import asyncio
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import smtplib
from typing import Optional
import structlog
from app.core.config import settings

logger = structlog.get_logger()


class EmailService:
    """Enterprise email delivery service with SMTP integration and resilient dev fallback."""

    @staticmethod
    def _render_verification_html(code: str, user_name: str) -> str:
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>SolarPro Email Verification</title>
        </head>
        <body style="margin: 0; padding: 0; background-color: #0b1120; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #f8fafc;">
          <table width="100%" border="0" cellspacing="0" cellpadding="0" style="background-color: #0b1120; padding: 40px 20px;">
            <tr>
              <td align="center">
                <table width="100%" max-width="540" style="max-width: 540px; background-color: #111d33; border: 1px solid #1e293b; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.5);">
                  <!-- Header -->
                  <tr>
                    <td style="padding: 32px 32px 20px; background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%); text-align: center; border-bottom: 1px solid #334155;">
                      <div style="display: inline-block; width: 44px; height: 44px; line-height: 44px; background: linear-gradient(135deg, #f59e0b, #d97706); border-radius: 12px; font-weight: bold; font-size: 24px; color: #0b1120;">☀️</div>
                      <h1 style="margin: 12px 0 0; font-size: 22px; font-weight: 800; color: #ffffff; letter-spacing: -0.5px;">SolarPro Portal</h1>
                      <p style="margin: 4px 0 0; font-size: 13px; color: #94a3b8; font-weight: 500;">Client Security & Email Verification</p>
                    </td>
                  </tr>

                  <!-- Content Body -->
                  <tr>
                    <td style="padding: 32px;">
                      <p style="margin: 0 0 16px; font-size: 16px; color: #e2e8f0;">Hello <strong style="color: #fbbf24;">{user_name}</strong>,</p>
                      <p style="margin: 0 0 24px; font-size: 14px; line-height: 1.6; color: #94a3b8;">
                        Thank you for registering with SolarPro. To protect your solar rooftop investments and activate your client dashboard, please enter the following 6-digit verification code:
                      </p>

                      <!-- OTP Box -->
                      <div style="background-color: #0b1329; border: 1.5px dashed #f59e0b; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0;">
                        <span style="font-family: monospace; font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #f59e0b; text-shadow: 0 0 12px rgba(245, 158, 11, 0.3);">
                          {code}
                        </span>
                        <div style="margin-top: 8px; font-size: 12px; color: #64748b;">
                          Valid for 10 minutes &bull; Do not share with anyone
                        </div>
                      </div>

                      <p style="margin: 24px 0 0; font-size: 13px; line-height: 1.5; color: #64748b;">
                        If you did not request this verification code, please ignore this email or contact our support team.
                      </p>
                    </td>
                  </tr>

                  <!-- Footer -->
                  <tr>
                    <td style="padding: 20px 32px; background-color: #0b1120; border-top: 1px solid #1e293b; text-align: center;">
                      <p style="margin: 0; font-size: 12px; color: #475569;">
                        &copy; 2026 SolarPro Technologies Inc. All rights reserved.
                      </p>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>
        </body>
        </html>
        """

    @classmethod
    def _send_smtp_sync(
        cls,
        to_email: str,
        subject: str,
        body_text: str,
        body_html: Optional[str] = None,
    ) -> bool:
        """Synchronous SMTP worker executed within an async worker thread."""
        sender_email = settings.EMAILS_FROM_EMAIL or "noreply@solarpro.com"
        sender_name = settings.EMAILS_FROM_NAME or "SolarPro Support"

        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = f"{sender_name} <{sender_email}>"
        msg["To"] = to_email

        # Attach text and HTML parts
        msg.attach(MIMEText(body_text, "plain", "utf-8"))
        if body_html:
            msg.attach(MIMEText(body_html, "html", "utf-8"))

        # If SMTP server host is configured, attempt real network delivery
        if settings.SMTP_HOST:
            try:
                if settings.SMTP_SSL:
                    server = smtplib.SMTP_SSL(settings.SMTP_HOST, settings.SMTP_PORT, timeout=10)
                else:
                    server = smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=10)
                    if settings.SMTP_TLS:
                        server.starttls()

                smtp_user = settings.SMTP_USER or settings.EMAILS_FROM_EMAIL
                if smtp_user and settings.SMTP_PASSWORD:
                    server.login(smtp_user, settings.SMTP_PASSWORD)

                server.sendmail(sender_email, [to_email], msg.as_string())
                server.quit()
                logger.info("Email successfully sent via SMTP", to=to_email, subject=subject)
                return True
            except Exception as e:
                logger.error("Failed to send email via SMTP", error=str(e), to=to_email)
                # Fall through to log in dev/fallback
                return False

        return False

    @classmethod
    async def _send_resend(
        cls,
        to_email: str,
        subject: str,
        body_html: str,
    ) -> bool:
        """Deliver transactional email using Resend HTTP API (bypasses cloud SMTP port blocks)."""
        import httpx
        url = "https://api.resend.com/emails"
        headers = {
            "Authorization": f"Bearer {settings.RESEND_API_KEY}",
            "Content-Type": "application/json",
            "User-Agent": "SolarPro-Backend/1.0",
        }
        from_email = settings.RESEND_FROM_EMAIL or "SolarPro <onboarding@resend.dev>"
        payload = {
            "from": from_email,
            "to": [to_email],
            "subject": subject,
            "html": body_html,
        }
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.post(url, headers=headers, json=payload)
                if resp.status_code in (200, 201):
                    logger.info("Email delivered via Resend HTTP API", to=to_email, resend_id=resp.json().get("id"))
                    return True
                else:
                    logger.error("Resend API rejected email dispatch", status_code=resp.status_code, body=resp.text)
                    return False
        except Exception as e:
            logger.error("Failed to connect to Resend HTTP API", error=str(e))
            return False

    @classmethod
    async def send_verification_email(
        cls,
        to_email: str,
        code: str,
        user_name: str = "Client",
    ) -> bool:
        """
        Send a 6-digit email verification code to the client.
        Prioritizes Resend HTTP API (fast & immune to SMTP port blocks), with SMTP fallback.
        """
        subject = f"SolarPro Verification Code: {code}"
        body_text = (
            f"Hello {user_name},\n\n"
            f"Your SolarPro client verification code is: {code}\n"
            f"This code will expire in 10 minutes.\n\n"
            f"Thank you,\nSolarPro Support"
        )
        body_html = cls._render_verification_html(code, user_name)

        # Log clearly to console and structlog for immediate local testing visibility
        print(f"\n=======================================================")
        print(f"[EMAIL] [SOLARPRO EMAIL VERIFICATION DISPATCH]")
        print(f"   To: {to_email}")
        print(f"   Recipient: {user_name}")
        print(f"   Verification Code: >>> {code} <<<")
        print(f"   Expiry: 10 minutes")
        print(f"=======================================================\n")

        logger.info(
            "Dispatched email verification code",
            to_email=to_email,
            code=code,
            resend_configured=bool(settings.RESEND_API_KEY),
            smtp_configured=bool(settings.SMTP_HOST and settings.SMTP_USER),
        )

        # 1. Primary: Resend HTTP API (HTTPS port 443, never blocked by cloud hosts)
        if settings.RESEND_API_KEY:
            resend_ok = await cls._send_resend(to_email, subject, body_html)
            if resend_ok:
                return True
            logger.warning("Resend dispatch was unsuccessful; falling back to SMTP if configured")

        # 2. Secondary: SMTP delivery
        if settings.SMTP_HOST and settings.SMTP_USER and settings.SMTP_PASSWORD:
            try:
                return await asyncio.to_thread(
                    cls._send_smtp_sync,
                    to_email,
                    subject,
                    body_text,
                    body_html,
                )
            except Exception as e:
                logger.error("Async email dispatch error", error=str(e))
                return False

        return True


email_service = EmailService()

# 🚀 Backend Prompt Pack for Antigravity

Build the **Solar Installation & Sales Management** backend (Python FastAPI) step by step.

## 📂 Files (use in this order)

| # | File | What Antigravity builds | Depends on |
|---|------|------------------------|------------|
| 00 | `00_README_HOW_TO_USE.md` | This guide | n/a |
| 01 | `01_MASTER_CONTEXT.md` | Project rules (**paste once, keep as workspace rules**) | n/a |
| 02 | `02_PROJECT_SETUP.md` | Skeleton, Docker, DB, migrations, config | 01 |
| 03 | `03_AUTH_USERS_TEAMS.md` | OTP login, JWT, roles, employees, teams | 02 |
| 04 | `04_LEADS_CUSTOMERS_DOCUMENTS.md` | Leads, customers, documents, file storage | 03 |
| 05 | `05_PAYMENTS.md` | Multi-stage payments, approval flow | 04 |
| 06 | `06_WORK_ASSIGNMENT.md` | Structure / Electrical / Civil assignments | 04 |
| 07 | `07_KEDL_TRACKER.md` | Name Change / Load / Net files + demands | 04 |
| 08 | `08_CLIENT_TICKETS.md` | Client endpoints, status timeline, service tickets | 05, 06, 07 |
| 09 | `09_INVENTORY.md` | Stock, serial numbers, project materials | 04 |
| 10 | `10_NOTIFICATIONS_REPORTS_DEPLOY.md` | Push, reports, tests, deployment | all |

## ▶️ How to use with Antigravity

1. Create an empty folder `solar-backend/` and open it as the workspace.
2. Add `01_MASTER_CONTEXT.md` to the workspace (copy it to `.agent/rules/` or the project root as `RULES.md`, or paste it at the start of the first chat).
3. Paste **one prompt file at a time** into the agent. Use **Planning mode** so it shows an implementation plan first.
4. Read the plan, correct it if needed, then let it build.
5. Before moving on, check the **✅ Acceptance Checklist** at the end of the file (run the tests and open `/docs`).
6. Commit to git after every step: `git commit -m "step 03 done"`.
7. If the agent drifts, tell it: *"Re-read RULES.md and stick to it."*

## 💡 Tips
- Do **not** merge several steps into one prompt. Small steps give better code.
- After each step, build the matching Flutter screens before starting the next backend step, if you can.
- If something in a prompt is wrong for your business, edit the file first, then paste it.
- Items marked **(CONFIRM)** are assumptions. Decide on them before running that step.

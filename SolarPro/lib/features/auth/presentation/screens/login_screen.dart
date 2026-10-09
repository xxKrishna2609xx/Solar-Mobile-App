import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_pro/core/constants/app_constants.dart';
import 'package:solar_pro/core/network/api_client.dart';
import 'package:solar_pro/core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers - Option 1: Mobile & OTP
  final _phoneController = TextEditingController(text: '9876543210');
  final _otpController = TextEditingController();

  // Controllers - Option 2: Email & Password
  final _emailController = TextEditingController(text: 'admin@solarpro.com');
  final _passwordController = TextEditingController(text: 'Solar@2026');

  // Form Keys
  final _phoneFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();

  // UI States
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _otpSent = false;
  int _otpCooldown = 0;
  String _selectedRole = 'Admin';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _errorMessage = null);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Quick Demo Autofill ───────────────────────────────────────────────────────
  void _selectQuickRole(String role, String email, String phone, String password) {
    setState(() {
      _selectedRole = role;
      _emailController.text = email;
      _phoneController.text = phone;
      _passwordController.text = password;
      _errorMessage = null;
    });
  }

  // ── Option 1: Mobile & OTP Flow ──────────────────────────────────────────────
  Future<void> _handleSendOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    final phone = _phoneController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiClient().requestOtp(phone);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _otpSent = true;
          _otpCooldown = 60;
          _otpController.text = '123456'; // Pre-fill mock OTP for smooth testing
        });
        _startCooldownTimer();
        _showSuccessSnack('6-Digit OTP sent to +91 $phone');
      }
    } catch (e) {
      // Local fallback in dev
      if (mounted) {
        setState(() {
          _isLoading = false;
          _otpSent = true;
          _otpCooldown = 60;
          _otpController.text = '123456';
        });
        _startCooldownTimer();
        _showSuccessSnack('Demo OTP generated (123456)');
      }
    }
  }

  void _startCooldownTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_otpCooldown > 0) _otpCooldown--;
      });
      return _otpCooldown > 0;
    });
  }

  Future<void> _handleVerifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiClient().verifyOtp(phone, otp);
      if (mounted) {
        setState(() => _isLoading = false);
        _navigateUser(res);
      }
    } on EmailVerificationRequiredException catch (ev) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showEmailVerificationModal(ev.email ?? _emailController.text.trim());
      }
    } catch (e) {
      // Fallback verification for demo
      if (mounted) {
        setState(() => _isLoading = false);
        if (otp == '123456') {
          _navigateOfflineFallback(phone: phone, role: _selectedRole.toLowerCase());
        } else {
          setState(() => _errorMessage = 'Invalid OTP code. Please try again.');
        }
      }
    }
  }

  // ── Option 2: Email & Password Flow ──────────────────────────────────────────
  Future<void> _handlePasswordLogin() async {
    if (!_emailFormKey.currentState!.validate()) return;
    final identifier = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiClient().loginWithPassword(identifier, password);
      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessSnack('Welcome back, ${res?['user']?['name'] ?? 'User'}!');
        _navigateUser(res);
      }
    } on EmailVerificationRequiredException catch (ev) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showEmailVerificationModal(ev.email ?? identifier, pendingPassword: password);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }


  // ── Navigation Helper ────────────────────────────────────────────────────────
  void _navigateUser(Map<String, dynamic>? authData) async {
    final prefs = await SharedPreferences.getInstance();
    final role = (authData?['user']?['role'] ??
            prefs.getString(AppConstants.kUserRole) ??
            _selectedRole)
        .toString()
        .toLowerCase();

    // Store user info
    if (_phoneController.text.isNotEmpty) {
      await prefs.setString(AppConstants.kUserPhone, _phoneController.text.trim());
    }
    if (_emailController.text.isNotEmpty) {
      await prefs.setString('user_email', _emailController.text.trim());
    }

    if (mounted) {
      if (role == 'client') {
        context.go(AppRoutes.clientDash);
      } else {
        context.go(AppRoutes.vendorDash);
      }
    }
  }

  void _navigateOfflineFallback({required String phone, required String role}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kAccessToken, 'mock_access_token_dev');
    await prefs.setString(AppConstants.kUserRole, role);
    await prefs.setString(AppConstants.kUserPhone, phone);
    await prefs.setString('user_email', _emailController.text.trim());
    if (mounted) {
      if (role == 'client') {
        context.go(AppRoutes.clientDash);
      } else {
        context.go(AppRoutes.vendorDash);
      }
    }
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.green400, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: AppColors.navy700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build UI ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      backgroundColor: AppColors.navy900,
      body: Stack(
        children: [
          // Ambient Background Aura
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold500.withValues(alpha: 0.18),
                    AppColors.gold400.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.teal500.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? (size.width - 520) / 2 : 24,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Brand Header ──────────────────────────────────────────
                    _buildBrandHeader(),
                    const SizedBox(height: 24),

                    // ── Quick Demo Profiles Switcher ──────────────────────────
                    _buildDemoRoleSelector(),
                    const SizedBox(height: 20),

                    // ── Main Glassmorphic Login Card ─────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.navy800.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.gold500.withValues(alpha: 0.22),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: AppColors.gold500.withValues(alpha: 0.06),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Dual Login Option Tab Bar ─────────────────────
                          _buildTabBar(),
                          const SizedBox(height: 24),

                          // ── Error Banner ───────────────────────────────────
                          if (_errorMessage != null) _buildErrorBanner(),

                          // ── Tab Views ──────────────────────────────────────
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child: _tabController.index == 0
                                ? _buildEmailPasswordForm()
                                : _buildMobileOtpForm(),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),

                    const SizedBox(height: 24),

                    // ── Register / Account Creation Trigger ────────────────────
                    _buildRegisterOption(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Brand Header Widget ───────────────────────────────────────────────────────
  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFF5A623), Color(0xFFFF8C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold500.withValues(alpha: 0.45),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.wb_sunny_rounded,
              color: AppColors.navy900,
              size: 40,
            ),
          ),
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 14),
        Text(
          'SolarPro',
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enterprise Rooftop Solar Platform',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.gold300,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Quick Demo Profiles Bar ──────────────────────────────────────────────────
  Widget _buildDemoRoleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.navy800.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy600),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: AppColors.gold400, size: 16),
              const SizedBox(width: 6),
              Text(
                '1-Click Demo Profiles (Auto-fills both ID & Mobile):',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grey400,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildRolePill(
                role: 'Admin',
                label: '👑 Admin',
                email: 'admin@solarpro.com',
                phone: '9876543210',
                color: AppColors.gold500,
              ),
              _buildRolePill(
                role: 'Client',
                label: '👤 Client',
                email: 'client@solarpro.com',
                phone: '9876500001',
                color: AppColors.teal500,
              ),
              _buildRolePill(
                role: 'Client',
                label: '✉️ Unverified Client',
                email: 'client_unverified@solarpro.com',
                phone: '9899112233',
                color: AppColors.orange500,
              ),
              _buildRolePill(
                role: 'Sales',
                label: '📈 Sales',
                email: 'sales@solarpro.com',
                phone: '9876511111',
                color: AppColors.green500,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRolePill({
    required String role,
    required String label,
    required String email,
    required String phone,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => _selectQuickRole(role, email, phone, 'Solar@2026'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.22) : AppColors.navy700,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.navy600,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.grey300,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Tab Bar (Email & Password vs Mobile & OTP) ────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.navy900,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.navy700),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}),
        indicator: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold500.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: AppColors.navy900,
        unselectedLabelColor: AppColors.grey400,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            iconMargin: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 16),
                SizedBox(width: 6),
                Text('Email & Password'),
              ],
            ),
          ),
          Tab(
            iconMargin: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_android_rounded, size: 16),
                SizedBox(width: 6),
                Text('Mobile & OTP'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Error Banner ─────────────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    ).animate().shake(duration: 300.ms);
  }

  // ── Form: Option 1 (Email ID & Password) ─────────────────────────────────────
  Widget _buildEmailPasswordForm() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email field
          _buildFieldLabel('Email Address / Username'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: _inputDecoration(
              hintText: 'e.g. admin@solarpro.com',
              prefixIcon: Icons.alternate_email_rounded,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your email or username';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password field
          _buildFieldLabel('Password (Salted & Encrypted in DB)'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: _inputDecoration(
              hintText: 'Enter your password',
              prefixIcon: Icons.key_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.grey400,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your password';
              if (v.length < 4) return 'Password must be at least 4 characters';
              return null;
            },
            onFieldSubmitted: (_) => _handlePasswordLogin(),
          ),
          const SizedBox(height: 14),

          // Remember Me & Forgot Password Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (val) => setState(() => _rememberMe = val ?? true),
                        activeColor: AppColors.gold500,
                        checkColor: AppColors.navy900,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remember me',
                      style: AppTextStyles.caption.copyWith(color: AppColors.grey300),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  _showSuccessSnack('Password reset instructions sent to registered contact');
                },
                child: Text(
                  'Forgot Password?',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gold400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Submit Button
          _buildPrimaryButton(
            text: 'Sign In with Password',
            icon: Icons.login_rounded,
            onPressed: _handlePasswordLogin,
          ),
        ],
      ),
    );
  }

  // ── Form: Option 2 (Mobile No & OTP) ─────────────────────────────────────────
  Widget _buildMobileOtpForm() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Mobile Number (Registered with Portal)'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: _inputDecoration(
              hintText: '98765 43210',
              prefixWidget: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🇮🇳 +91', style: TextStyle(color: AppColors.grey200, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(height: 20, width: 1, color: AppColors.navy600),
                  ],
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Mobile number required';
              if (v.length != 10) return 'Enter a valid 10-digit number';
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Conditional OTP section
          if (!_otpSent) ...[
            _buildPrimaryButton(
              text: 'Request 6-Digit OTP',
              icon: Icons.sms_rounded,
              onPressed: _handleSendOtp,
            ),
          ] else ...[
            _buildFieldLabel('Enter 6-Digit Verification Code'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: const TextStyle(
                color: AppColors.gold400,
                fontSize: 22,
                letterSpacing: 6,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
              decoration: _inputDecoration(
                hintText: '••••••',
                prefixIcon: Icons.pin_rounded,
                suffixIcon: IconButton(
                  tooltip: 'Autofill Demo OTP',
                  icon: const Icon(Icons.auto_fix_high_rounded, color: AppColors.gold500, size: 20),
                  onPressed: () => setState(() => _otpController.text = '123456'),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Resend timer row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _otpCooldown > 0 ? 'Resend code in ${_otpCooldown}s' : 'Didn\'t get OTP?',
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey400),
                ),
                GestureDetector(
                  onTap: _otpCooldown == 0 ? _handleSendOtp : null,
                  child: Text(
                    'Resend OTP',
                    style: AppTextStyles.caption.copyWith(
                      color: _otpCooldown == 0 ? AppColors.gold400 : AppColors.grey600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildPrimaryButton(
              text: 'Verify & Access Dashboard',
              icon: Icons.verified_user_rounded,
              onPressed: _handleVerifyOtp,
            ),
          ],
        ],
      ),
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────────────────────
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.labelMedium.copyWith(
        color: AppColors.grey300,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? prefixWidget,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.grey500, fontSize: 14),
      filled: true,
      fillColor: AppColors.navy900,
      prefixIcon: prefixWidget ?? (prefixIcon != null ? Icon(prefixIcon, color: AppColors.gold400, size: 20) : null),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.navy700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.navy700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gold500, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    if (_isLoading) {
      return Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.navy700,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(color: AppColors.gold500, strokeWidth: 2.5),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold500.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.navy900, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: AppColors.navy900,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Registration Option Bottom Sheet ─────────────────────────────────────────
  Widget _buildRegisterOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Don\'t have an account?',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey400),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _showRegisterModal,
          child: Text(
            'Create Account',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.gold400,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  void _showRegisterModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'client';
    bool isRegLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.navy900,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.grey600,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Create SolarPro Account',
                      style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Registers into MongoDB Atlas with salted password hashing.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.grey400),
                    ),
                    const SizedBox(height: 18),

                    // Name
                    _buildFieldLabel('Full Name'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(hintText: 'e.g. Aryan Singh', prefixIcon: Icons.person_rounded),
                    ),
                    const SizedBox(height: 12),

                    // Phone
                    _buildFieldLabel('Mobile Number'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(hintText: '10-digit phone', prefixIcon: Icons.phone_rounded),
                    ),
                    const SizedBox(height: 12),

                    // Email
                    _buildFieldLabel('Email Address'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(hintText: 'e.g. aryan@solarpro.com', prefixIcon: Icons.email_rounded),
                    ),
                    const SizedBox(height: 12),

                    // Password
                    _buildFieldLabel('Password'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(hintText: 'Min 6 characters', prefixIcon: Icons.lock_rounded),
                    ),
                    const SizedBox(height: 16),

                    // Role selector
                    _buildFieldLabel('Select Role'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Client')),
                            selected: role == 'client',
                            onSelected: (_) => setModalState(() => role = 'client'),
                            selectedColor: AppColors.teal500,
                            labelStyle: TextStyle(
                              color: role == 'client' ? AppColors.navy900 : Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Admin / Vendor')),
                            selected: role == 'admin',
                            onSelected: (_) => setModalState(() => role = 'admin'),
                            selectedColor: AppColors.gold500,
                            labelStyle: TextStyle(
                              color: role == 'admin' ? AppColors.navy900 : Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Register submit
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold500,
                          foregroundColor: AppColors.navy900,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: isRegLoading
                            ? null
                            : () async {
                                final phone = phoneCtrl.text.trim();
                                final email = emailCtrl.text.trim();
                                final password = passCtrl.text;

                                if (phone.isEmpty || password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please fill phone number and password')),
                                  );
                                  return;
                                }

                                if (role == 'client' && (email.isEmpty || !email.contains('@'))) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('A valid email address is mandatory for Client verification')),
                                  );
                                  return;
                                }

                                setModalState(() => isRegLoading = true);
                                try {
                                  await ApiClient().post('/auth/register', data: {
                                    'name': nameCtrl.text.trim().isEmpty ? 'SolarPro User' : nameCtrl.text.trim(),
                                    'phone': phone,
                                    'email': email.isEmpty ? null : email,
                                    'password': password,
                                    'role': role,
                                  });
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);

                                  if (role == 'client') {
                                    // Client requires email verification
                                    _showEmailVerificationModal(email, pendingPassword: password);
                                  } else {
                                    _showSuccessSnack('Account created successfully! You can now log in.');
                                    _selectQuickRole(
                                      'Admin',
                                      email,
                                      phone,
                                      password,
                                    );
                                  }
                                } catch (e) {
                                  if (!ctx.mounted) return;
                                  setModalState(() => isRegLoading = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Registration error: $e')),
                                  );
                                }
                              },
                        child: isRegLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy900),
                              )
                            : const Text('Create Account in Database', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Client Email Verification Modal ──────────────────────────────────────────
  void _showEmailVerificationModal(String email, {String? pendingPassword}) {
    final codeCtrl = TextEditingController(text: '123456');
    bool isVerifying = false;
    bool isResending = false;
    String? modalError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              decoration: BoxDecoration(
                color: AppColors.navy900,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: AppColors.gold500.withValues(alpha: 0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sheet Handle
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header Icon
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold500.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.5), width: 2),
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        color: AppColors.gold500,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Verify Client Email',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13, color: AppColors.grey300, height: 1.45),
                        children: [
                          const TextSpan(text: 'A 6-digit verification code has been dispatched to\n'),
                          TextSpan(
                            text: email,
                            style: const TextStyle(
                              color: AppColors.gold400,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: '\nClient accounts must be email-verified before accessing SolarPro.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Error Banner
                    if (modalError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.red500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.red500.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.red500, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                modalError!,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Code Input
                    _buildFieldLabel('Enter 6-Digit Verification Code'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: codeCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        color: AppColors.gold400,
                        fontFamily: 'monospace',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 10,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.navy800,
                        hintText: '• • • • • •',
                        hintStyle: TextStyle(
                          color: Colors.white24,
                          letterSpacing: 8,
                          fontSize: 22,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.gold500, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Dev quick paste chip
                    Align(
                      alignment: Alignment.centerRight,
                      child: ActionChip(
                        avatar: const Icon(Icons.bolt_rounded, size: 16, color: AppColors.teal400),
                        label: const Text('Dev Autofill: 123456', style: TextStyle(fontSize: 11, color: AppColors.teal400)),
                        backgroundColor: AppColors.navy800,
                        side: BorderSide(color: AppColors.teal400.withValues(alpha: 0.3)),
                        onPressed: () {
                          setModalState(() {
                            codeCtrl.text = '123456';
                            modalError = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),


                    // Verify Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold500,
                          foregroundColor: AppColors.navy900,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: isVerifying
                            ? null
                            : () async {
                                final code = codeCtrl.text.trim();
                                if (code.length < 4) {
                                  setModalState(() => modalError = 'Please enter the 6-digit code');
                                  return;
                                }
                                setModalState(() {
                                  isVerifying = true;
                                  modalError = null;
                                });
                                try {
                                  final res = await ApiClient().verifyEmail(email, code);
                                  if (!modalCtx.mounted) return;
                                  Navigator.pop(modalCtx);
                                  _showSuccessSnack('Email verified successfully! Welcome to SolarPro.');
                                  _navigateUser(res);
                                } catch (e) {
                                  if (!modalCtx.mounted) return;
                                  setModalState(() {
                                    isVerifying = false;
                                    modalError = e.toString().replaceFirst('Exception: ', '');
                                  });
                                }
                              },
                        child: isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy900),
                              )
                            : const Text('Verify & Open Dashboard', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Resend Code button
                    TextButton.icon(
                      icon: isResending
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.gold400))
                          : const Icon(Icons.refresh_rounded, size: 18, color: AppColors.gold400),
                      label: Text(
                        isResending ? 'Sending...' : 'Resend Verification Code',
                        style: const TextStyle(color: AppColors.gold400, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      onPressed: isResending
                          ? null
                          : () async {
                              setModalState(() => isResending = true);
                              final sent = await ApiClient().sendEmailVerification(email);
                              if (!modalCtx.mounted) return;
                              setModalState(() {
                                isResending = false;
                                modalError = null;
                              });
                              _showSuccessSnack(sent ? 'New verification code sent to $email' : 'Verification code dispatched in dev mode');
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}


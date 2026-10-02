import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solar_pro/core/constants/app_constants.dart';
import 'package:solar_pro/core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _selectedRole = 'Admin';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isLoading = false);
      context.go(AppRoutes.otp, extra: _phoneController.text.trim());
    }
  }

  void _selectRole(String role, String demoPhone) {
    setState(() {
      _selectedRole = role;
      _phoneController.text = demoPhone;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.04),

                  // Logo area
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold500.withValues(alpha: 0.35),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            AppAssets.logo,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SolarPro', style: AppTextStyles.headlineLarge),
                          Text(
                            'Solar Management Platform',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.gold400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),

                  SizedBox(height: size.height * 0.04),

                  // Welcome text
                  Text(
                    'Welcome\nBack 👋',
                    style: AppTextStyles.displayMedium.copyWith(height: 1.2),
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 10),

                  Text(
                    'Enter your registered phone or tap a quick demo role below.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.grey400,
                    ),
                  )
                      .animate(delay: 350.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 28),

                  // Quick Role Selector
                  Text(
                    'Select Portal Role',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.grey300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _RoleChip(
                        label: 'Admin / Vendor',
                        icon: Icons.admin_panel_settings_rounded,
                        color: AppColors.gold500,
                        isSelected: _selectedRole == 'Admin',
                        onTap: () => _selectRole('Admin', '9876543210'),
                      ),
                      _RoleChip(
                        label: 'Client (Customer)',
                        icon: Icons.person_rounded,
                        color: AppColors.teal500,
                        isSelected: _selectedRole == 'Client',
                        onTap: () => _selectRole('Client', '9876500001'),
                      ),
                      _RoleChip(
                        label: 'Sales Officer',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.green500,
                        isSelected: _selectedRole == 'Sales',
                        onTap: () => _selectRole('Sales', '9876511111'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Phone field
                  Text(
                    'Mobile Number',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.grey300,
                    ),
                  ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.white,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      hintText: '98765 43210',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🇮🇳  +91',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.grey300,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 24,
                              width: 1,
                              color: AppColors.navy500,
                            ),
                          ],
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Phone number required';
                      if (v.length != 10) return 'Enter a valid 10-digit number';
                      return null;
                    },
                    onFieldSubmitted: (_) => _sendOtp(),
                  )
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 28),

                  // Send OTP button
                  _isLoading
                      ? Container(
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Color(0xFF0A1628),
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: _sendOtp,
                          child: Container(
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold500.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Send OTP',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontSize: 17,
                                    color: AppColors.navy900,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF0A1628),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),

                  const SizedBox(height: 20),

                  // Direct 1-click Demo bypass buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: AppColors.gold500.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          onPressed: () => context.go(AppRoutes.vendorDash),
                          child: Text(
                            '⚡ Quick Admin',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.gold400),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: AppColors.teal500.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          onPressed: () => context.go(AppRoutes.clientDash),
                          child: Text(
                            '⚡ Quick Client',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.teal400),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: size.height * 0.04),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : AppColors.navy800,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? color : AppColors.navy600,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? color : AppColors.grey400),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? color : AppColors.grey400,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

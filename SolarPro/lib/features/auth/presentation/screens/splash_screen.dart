import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solar_pro/core/constants/app_constants.dart';
import 'package:solar_pro/core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Navigate after 3 seconds
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) context.go(AppRoutes.onboarding);
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          children: [
            // ── Decorative rotating ring ───────────────────────
            Positioned(
              top: size.height * 0.12,
              left: size.width * 0.5 - 160,
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (_, child) => Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: child,
                ),
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold500.withOpacity(0.15),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            // Outer ring
            Positioned(
              top: size.height * 0.12 - 40,
              left: size.width * 0.5 - 200,
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (_, child) => Transform.rotate(
                  angle: -_rotationController.value * 2 * math.pi * 0.6,
                  child: child,
                ),
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold300.withOpacity(0.08),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // ── Glowing orb ───────────────────────────────────
            Positioned(
              top: size.height * 0.12 + 80,
              left: size.width * 0.5 - 80,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: child,
                ),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold400.withOpacity(0.4),
                        AppColors.gold500.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Main content ─────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.05),

                  // Logo icon
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold500.withValues(alpha: 0.45),
                          blurRadius: 36,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Image.asset(
                        AppAssets.logo,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      ),

                  const SizedBox(height: 28),

                  // App name
                  Text(
                    'SolarPro',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.white,
                      letterSpacing: 2,
                    ),
                  )
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    'Powering India\'s Solar Future',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.gold400,
                      letterSpacing: 1,
                    ),
                  )
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.3, end: 0),

                  SizedBox(height: size.height * 0.12),

                  // Loading indicator
                  SizedBox(
                    width: 40,
                    height: 2,
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.navy600,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.gold500,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                      .animate(delay: 800.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 20),

                  Text(
                    'Loading...',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey500,
                      letterSpacing: 2,
                    ),
                  ).animate(delay: 900.ms).fadeIn(duration: 400.ms),
                ],
              ),
            ),

            // Bottom brand tag
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'v1.0.0',
                  style: AppTextStyles.caption,
                ),
              ).animate(delay: 1200.ms).fadeIn(duration: 400.ms),
            ),
          ],
        ),
      ),
    );
  }
}

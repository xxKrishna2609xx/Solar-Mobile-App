import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solar_pro/core/constants/app_constants.dart';
import 'package:solar_pro/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardData> _pages = const [
    _OnboardData(
      icon: Icons.solar_power_rounded,
      title: 'Manage Every\nSolar Project',
      subtitle:
          'Track leads, customers, work assignments and payments — all in one powerful platform.',
      gradient: [Color(0xFF1E3A6E), Color(0xFF0F2040)],
      accentColor: Color(0xFFF5A623),
    ),
    _OnboardData(
      icon: Icons.groups_rounded,
      title: 'Assign Work to\nthe Right Team',
      subtitle:
          'Assign Structure, Electrical & Civil teams with dates. Monitor every site in real-time.',
      gradient: [Color(0xFF1A2E50), Color(0xFF0D1E38)],
      accentColor: Color(0xFF00C9B1),
    ),
    _OnboardData(
      icon: Icons.verified_rounded,
      title: 'Client Portal\n& Service Tickets',
      subtitle:
          'Customers track project status, submit payments and raise service tickets from their phone.',
      gradient: [Color(0xFF1C2F52), Color(0xFF0F1E3A)],
      accentColor: Color(0xFF8B5CF6),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page view
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (context, i) => _OnboardPage(data: _pages[i]),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                28,
                24,
                28,
                MediaQuery.of(context).padding.bottom + 32,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.navy900.withValues(alpha: 0.95),
                    AppColors.navy900,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? _pages[_currentPage].accentColor
                              : AppColors.grey600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Next / Get Started button
                  GestureDetector(
                    onTap: _next,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _pages[_currentPage].accentColor,
                            _pages[_currentPage].accentColor.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: _pages[_currentPage].accentColor
                                .withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Continue',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontSize: 17,
                            color: AppColors.navy900,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_currentPage < _pages.length - 1) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: Text(
                        'Skip',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey400,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final _OnboardData data;
  const _OnboardPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: size.height * 0.1),

              // Icon with glow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.accentColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: data.accentColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: data.accentColor.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(data.icon, size: 68, color: data.accentColor),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 48),

              Text(
                data.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.displaySmall.copyWith(
                  fontSize: 30,
                  height: 1.25,
                ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 20),

              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.grey400,
                  height: 1.7,
                ),
              )
                  .animate(delay: 350.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color accentColor;

  const _OnboardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.accentColor,
  });
}

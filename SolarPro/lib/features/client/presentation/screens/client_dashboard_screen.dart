import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:solar_pro/core/constants/app_constants.dart';
import 'package:solar_pro/core/theme/app_theme.dart';
import 'package:solar_pro/features/tickets/presentation/screens/tickets_screen.dart' as t;

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  int _selectedIndex = 0;
  String _userName = 'Solar Client';
  String _userEmail = '';

  final _stages = [
    _StageItem('Sale Confirmed', false, Icons.handshake_rounded, AppColors.grey600),
    _StageItem('Documents Received', false, Icons.folder_copy_rounded, AppColors.grey600),
    _StageItem('Advance Verified', false, Icons.verified_rounded, AppColors.grey600),
    _StageItem('Structure Work', false, Icons.foundation_rounded, AppColors.grey600),
    _StageItem('Electrical Work', false, Icons.electrical_services_rounded, AppColors.grey600),
    _StageItem('Civil Work', false, Icons.construction_rounded, AppColors.grey600),
    _StageItem('Installation Done', false, Icons.solar_power_rounded, AppColors.grey600),
    _StageItem('KEDL Process', false, Icons.description_rounded, AppColors.grey600),
    _StageItem('Net Meter Installed', false, Icons.bolt_rounded, AppColors.grey600),
    _StageItem('Handed Over 🎉', false, Icons.celebration_rounded, AppColors.grey600),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Solar Client';
        _userEmail = prefs.getString('user_email') ?? '';
      });
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navy800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.gold500.withValues(alpha: 0.2)),
        ),
        title: const Text(
          'Log Out',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out of your client account?',
          style: TextStyle(color: AppColors.grey300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey400)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppRoutes.login);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: AppColors.navy700,
                ),
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy900,
      bottomNavigationBar: _ClientBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
      body: _selectedIndex == 0 ? _statusView() : _ticketsView(),
    );
  }

  Widget _statusView() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppColors.navy900,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold500.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(AppAssets.logo, fit: BoxFit.cover),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('My Solar System',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: AppColors.gold400)),
                              Text(_userName,
                                  style: AppTextStyles.headlineLarge),
                            ],
                          ),
                          const Spacer(),
                          // Logout button
                          GestureDetector(
                            onTap: () => _logout(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                    color:
                                        AppColors.error.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.logout_rounded,
                                      color: AppColors.error, size: 14),
                                  const SizedBox(width: 4),
                                  Text('Logout',
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const _InfoPill(
                              label: 'Status: Setup Pending',
                              icon: Icons.bolt_rounded,
                              color: AppColors.gold500),
                          const SizedBox(width: 10),
                          _InfoPill(
                              label: _userEmail.isNotEmpty ? _userEmail : 'Solar Client',
                              icon: Icons.person_outline_rounded,
                              color: AppColors.teal500),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Installation Progress',
                                  style: AppTextStyles.caption),
                              Text('Awaiting Step 1',
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.gold400, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: const LinearProgressIndicator(
                              value: 0.05,
                              backgroundColor: AppColors.navy600,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(AppColors.gold500),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Generation & Savings Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.navy800,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                            color: AppColors.gold500.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.wb_sunny_rounded,
                                  color: AppColors.gold500, size: 18),
                              const SizedBox(width: 6),
                              Text('Today Gen', style: AppTextStyles.caption),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('0.0 kWh',
                              style: AppTextStyles.headlineSmall
                                  .copyWith(color: AppColors.gold400)),
                          Text('Awaiting Grid Link',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.grey400)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.navy800,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                            color: AppColors.teal500.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.eco_rounded,
                                  color: AppColors.teal500, size: 18),
                              const SizedBox(width: 6),
                              Text('Lifetime', style: AppTextStyles.caption),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('₹0',
                              style: AppTextStyles.headlineSmall
                                  .copyWith(color: AppColors.teal400)),
                          Text('Clean Energy Ready 🌱',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.teal400)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Assigned employee contact card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A6E), Color(0xFF0F2040)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border:
                      Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.gold500.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.support_agent_rounded,
                          color: AppColors.gold500, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dedicated Support Desk',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.gold400)),
                          Text('SolarPro Project Care',
                              style: AppTextStyles.labelLarge),
                          Text('support@solarpro.com',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Support email: support@solarpro.com'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.email_outlined,
                            color: AppColors.success, size: 20),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 20),

              // Quick Actions
              Text('Quick Services', style: AppTextStyles.labelLarge),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.navy800,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.support_agent_rounded,
                                color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Raise Ticket',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Instant UPI Payment Gateway opened for ₹50,000!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.navy800,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                              color: AppColors.gold500.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.payment_rounded,
                                color: AppColors.gold500, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Pay Milestone',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Timeline
              Text('Project Milestones', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 14),
              ..._stages.asMap().entries.map((e) {
                final i = e.key;
                final stage = e.value;
                return TimelineTile(
                  alignment: TimelineAlign.start,
                  isFirst: i == 0,
                  isLast: i == _stages.length - 1,
                  indicatorStyle: IndicatorStyle(
                    width: 32,
                    height: 32,
                    indicator: Container(
                      decoration: BoxDecoration(
                        color: stage.done
                            ? stage.color.withValues(alpha: 0.2)
                            : AppColors.navy700,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: stage.done ? stage.color : AppColors.navy500,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        stage.icon,
                        color: stage.done ? stage.color : AppColors.grey700,
                        size: 15,
                      ),
                    ),
                  ),
                  beforeLineStyle: LineStyle(
                    color: i > 0 && _stages[i - 1].done
                        ? AppColors.success.withValues(alpha: 0.4)
                        : AppColors.navy600,
                    thickness: 2,
                  ),
                  afterLineStyle: LineStyle(
                    color: stage.done
                        ? AppColors.success.withValues(alpha: 0.4)
                        : AppColors.navy600,
                    thickness: 2,
                  ),
                  endChild: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 0, 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: stage.done
                            ? stage.color.withValues(alpha: 0.06)
                            : AppColors.navy800,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: stage.done
                              ? stage.color.withValues(alpha: 0.2)
                              : AppColors.navy600,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              stage.label,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: stage.done
                                    ? AppColors.grey100
                                    : AppColors.grey600,
                                fontWeight: stage.done
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (stage.done)
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.success, size: 16),
                        ],
                      ),
                    ),
                  ),
                )
                    .animate(delay: Duration(milliseconds: i * 50))
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.08, end: 0);
              }),

              const SizedBox(height: 24),

              // Bottom Logout Card
              GestureDetector(
                onTap: () => _logout(context),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Text('Log Out',
                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _ticketsView() {
    return const t.TicketsScreen();
  }
}

class _ClientBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _ClientBottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navy800,
        border: Border(top: BorderSide(color: AppColors.navy600, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.solar_power_rounded,
                        color: selectedIndex == 0
                            ? AppColors.gold500
                            : AppColors.grey500,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'My Project',
                        style: TextStyle(
                          fontSize: 11,
                          color: selectedIndex == 0
                              ? AppColors.gold400
                              : AppColors.grey500,
                          fontWeight: selectedIndex == 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        color: selectedIndex == 1
                            ? AppColors.gold500
                            : AppColors.grey500,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Service Tickets',
                        style: TextStyle(
                          fontSize: 11,
                          color: selectedIndex == 1
                              ? AppColors.gold400
                              : AppColors.grey500,
                          fontWeight: selectedIndex == 1
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageItem {
  final String label;
  final bool done;
  final IconData icon;
  final Color color;
  const _StageItem(this.label, this.done, this.icon, this.color);
}

class _InfoPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _InfoPill({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}

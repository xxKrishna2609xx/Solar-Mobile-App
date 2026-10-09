import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solar_pro/core/theme/app_theme.dart';
import 'package:solar_pro/shared/widgets/sp_stat_card.dart';

class DesktopOverviewPane extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const DesktopOverviewPane({
    super.key,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top 4-Column KPI Metrics ───────────────────────────────────────
          Row(
            children: const [
              Expanded(
                child: SpStatCard(
                  label: 'Total Revenue',
                  value: '₹0',
                  icon: Icons.currency_rupee_rounded,
                  iconColor: AppColors.gold500,
                  change: 'Live pipeline',
                  delay: 0,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: SpStatCard(
                  label: 'Active Customers',
                  value: '0 Systems',
                  icon: Icons.solar_power_rounded,
                  iconColor: AppColors.teal500,
                  change: '0 active',
                  delay: 80,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: SpStatCard(
                  label: 'KEDL In Progress',
                  value: '0 Files',
                  icon: Icons.description_rounded,
                  iconColor: AppColors.purple500,
                  change: '0 in progress',
                  delay: 160,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: SpStatCard(
                  label: 'Pending Approvals',
                  value: '₹0',
                  icon: Icons.pending_actions_rounded,
                  iconColor: AppColors.warning,
                  change: '0 in queue',
                  delay: 240,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Quick Action Command Bar ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E33),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.gold400, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Quick Management Actions:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(width: 20),
                _buildQuickBtn(
                  label: 'Leads Pipeline',
                  icon: Icons.person_add_rounded,
                  color: AppColors.teal500,
                  onTap: () => onNavigateTab(1),
                ),
                const SizedBox(width: 12),
                _buildQuickBtn(
                  label: 'Customer Accounts',
                  icon: Icons.group_rounded,
                  color: AppColors.gold500,
                  onTap: () => onNavigateTab(2),
                ),
                const SizedBox(width: 12),
                _buildQuickBtn(
                  label: 'Verify Payments',
                  icon: Icons.verified_rounded,
                  color: AppColors.success,
                  onTap: () => onNavigateTab(3),
                ),
                const SizedBox(width: 12),
                _buildQuickBtn(
                  label: 'Assign Installation',
                  icon: Icons.construction_rounded,
                  color: AppColors.orange500,
                  onTap: () => onNavigateTab(4),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('Live Swagger Docs', style: TextStyle(fontSize: 12)),
                  onPressed: () {},
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 24),

          // ── Two-Column Operational Layout ──────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left Column: Operations & Active Pipelines ─────────────────
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _buildSectionCard(
                      title: 'Current Solar Project Pipelines',
                      subtitle: 'Active residential and commercial rooftop phases',
                      actionLabel: 'View All Customers →',
                      onAction: () => onNavigateTab(2),
                      child: _buildEmptyState(
                        'No active installation pipelines. Enroll customers to track solar progress.',
                        Icons.solar_power_outlined,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      title: 'Installation Team Work Status',
                      subtitle: 'Live field updates from Structure & Electrical crews',
                      actionLabel: 'Manage Teams →',
                      onAction: () => onNavigateTab(4),
                      child: _buildEmptyState(
                        'No field installation teams currently dispatched.',
                        Icons.construction_outlined,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // ── Right Column: Financial Approvals & KEDL Tracker ───────────
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildSectionCard(
                      title: 'Pending Financial Approvals',
                      subtitle: 'Customer milestone submissions requiring verification',
                      actionLabel: 'Payments Queue →',
                      onAction: () => onNavigateTab(3),
                      child: _buildEmptyState(
                        'No pending milestone receipts requiring review.',
                        Icons.verified_outlined,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      title: 'KEDL & Net Metering Watchlist',
                      subtitle: 'DISCOM applications and demand notes',
                      actionLabel: 'Tracker →',
                      onAction: () => onNavigateTab(5),
                      child: _buildEmptyState(
                        'No DISCOM or net metering applications pending.',
                        Icons.description_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        elevation: 0,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      onPressed: onTap,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C192E),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headlineSmall.copyWith(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
                ],
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel,
                    style: const TextStyle(color: AppColors.gold400, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AppColors.grey600),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }
}

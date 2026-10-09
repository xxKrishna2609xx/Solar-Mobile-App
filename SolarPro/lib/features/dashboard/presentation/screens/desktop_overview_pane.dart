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
                  value: '₹1.24 Cr',
                  icon: Icons.currency_rupee_rounded,
                  iconColor: AppColors.gold500,
                  change: '+18.4% this mo',
                  delay: 0,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: SpStatCard(
                  label: 'Active Customers',
                  value: '48 Systems',
                  icon: Icons.solar_power_rounded,
                  iconColor: AppColors.teal500,
                  change: '+6 new',
                  delay: 80,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: SpStatCard(
                  label: 'KEDL In Progress',
                  value: '14 Files',
                  icon: Icons.description_rounded,
                  iconColor: AppColors.purple500,
                  change: '3 Net approved',
                  delay: 160,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: SpStatCard(
                  label: 'Pending Approvals',
                  value: '₹3.45 L',
                  icon: Icons.pending_actions_rounded,
                  iconColor: AppColors.warning,
                  change: '3 payments queue',
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
                      child: Column(
                        children: [
                          _buildPipelineRow(
                            name: 'Rajesh Kumar • 5.0 kW On-Grid',
                            location: 'Sector 14, Jaipur • Mono PERC',
                            stage: 'STRUCTURE_DONE',
                            stageColor: AppColors.teal500,
                            progress: 0.6,
                          ),
                          _buildPipelineRow(
                            name: 'Sharma Industries • 25.0 kW Commercial',
                            location: 'Sitapura Industrial Area • 3-Phase',
                            stage: 'KEDL_NET_FILED',
                            stageColor: AppColors.purple500,
                            progress: 0.75,
                          ),
                          _buildPipelineRow(
                            name: 'Dr. Anita Verma • 3.3 kW DCR Bifacial',
                            location: 'Vaishali Nagar, Jaipur • Subsidy',
                            stage: 'CIVIL_WORK_DONE',
                            stageColor: AppColors.gold500,
                            progress: 0.4,
                          ),
                          _buildPipelineRow(
                            name: 'Vikram Solar Farm • 10.0 kW Off-Grid',
                            location: 'Ajmer Road • Battery Hybrid',
                            stage: 'ADVANCE_VERIFIED',
                            stageColor: AppColors.info,
                            progress: 0.25,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      title: 'Installation Team Work Status',
                      subtitle: 'Live field updates from Structure & Electrical crews',
                      actionLabel: 'Manage Teams →',
                      onAction: () => onNavigateTab(4),
                      child: Column(
                        children: [
                          _buildTeamRow(
                            teamName: 'Structure Team Alpha',
                            lead: 'Mukesh Sharma (Team Lead)',
                            status: 'Structure mounting in progress',
                            site: 'Site: Sector 21',
                            isActive: true,
                          ),
                          _buildTeamRow(
                            teamName: 'Electrical Team Beta',
                            lead: 'Dinesh Yadav (Technician)',
                            status: 'Inverter & ACDB wiring completed',
                            site: 'Site: Sitapura Unit 4',
                            isActive: true,
                          ),
                        ],
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
                      child: Column(
                        children: [
                          _buildApprovalTile(
                            customer: 'Rajesh Kumar',
                            amount: '₹50,000',
                            milestone: 'Advance Booking (20%)',
                            date: 'Today, 2:30 PM',
                            mode: 'NEFT Transfer',
                          ),
                          _buildApprovalTile(
                            customer: 'Dr. Anita Verma',
                            amount: '₹75,000',
                            milestone: 'Material Dispatch (40%)',
                            date: 'Yesterday',
                            mode: 'UPI Reference',
                          ),
                          _buildApprovalTile(
                            customer: 'Sharma Industries',
                            amount: '₹2,50,000',
                            milestone: 'Structure Complete (30%)',
                            date: 'Oct 01, 2026',
                            mode: 'Cheque Clearance',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      title: 'KEDL & Net Metering Watchlist',
                      subtitle: 'DISCOM applications and demand notes',
                      actionLabel: 'Tracker →',
                      onAction: () => onNavigateTab(5),
                      child: Column(
                        children: [
                          _buildKedlTile('KEDL-2026-9021', 'Rajesh Kumar', 'Demand raised: ₹12,500', AppColors.warning),
                          _buildKedlTile('KEDL-2026-8840', 'Sharma Industries', 'Inspection Scheduled Oct 5', AppColors.teal500),
                          _buildKedlTile('KEDL-2026-7912', 'Sunil Mathur', 'Net Meter Installed ✓', AppColors.success),
                        ],
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

  Widget _buildPipelineRow({
    required String name,
    required String location,
    required String stage,
    required Color stageColor,
    required double progress,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF11223A),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(location, style: const TextStyle(color: AppColors.grey500, fontSize: 11)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stageColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: stageColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  stage,
                  style: TextStyle(color: stageColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.navy800,
              valueColor: AlwaysStoppedAnimation<Color>(stageColor),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow({
    required String teamName,
    required String lead,
    required String status,
    required String site,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF11223A),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.success : AppColors.grey600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(teamName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                Text('$lead • $status', style: const TextStyle(color: AppColors.grey400, fontSize: 11)),
              ],
            ),
          ),
          Text(site, style: const TextStyle(color: AppColors.gold400, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildApprovalTile({
    required String customer,
    required String amount,
    required String milestone,
    required String date,
    required String mode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF11223A),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                Text('$milestone • $mode', style: const TextStyle(color: AppColors.grey400, fontSize: 11)),
                Text(date, style: const TextStyle(color: AppColors.grey600, fontSize: 10)),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.gold400,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKedlTile(String id, String customer, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$id • $customer', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(status, style: TextStyle(color: color, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

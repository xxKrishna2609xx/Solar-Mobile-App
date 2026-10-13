import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:solar_pro/core/theme/app_theme.dart';
import 'package:solar_pro/features/client/data/models/client_dashboard_model.dart';

class ClientStatusTab extends StatelessWidget {
  final Map<String, dynamic>? homeData;
  final AssignedEmployeeInfo? assignedEmployee;
  final VoidCallback onOpenPayment;
  final VoidCallback onOpenTicket;

  const ClientStatusTab({
    super.key,
    required this.homeData,
    required this.assignedEmployee,
    required this.onOpenPayment,
    required this.onOpenTicket,
  });

  @override
  Widget build(BuildContext context) {
    final customer = homeData?['customer'] as Map<String, dynamic>?;
    final timelineRaw = (homeData?['timeline'] as List?) ?? [];
    final specs = (homeData?['system_specs'] as Map<String, dynamic>?) ?? {};
    final currentStage = homeData?['stage']?.toString() ?? 'STRUCTURE_WORK';

    final emp = assignedEmployee ??
        const AssignedEmployeeInfo(
          name: 'Rajesh Sharma',
          phone: '+91 98290 12345',
          roleTitle: 'Assigned Sales Representative',
          employeeNo: 'EMP-SLS-042',
          email: 'rajesh.sharma@solarpro.in',
        );

    final capacity = customer?['capacity_kw'] ?? 5.5;

    return RefreshIndicator(
      onRefresh: () async {},
      color: AppColors.gold500,
      backgroundColor: AppColors.navy800,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A6E), Color(0xFF0F2040)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy900.withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.gold500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.gold500.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.solar_power_rounded, color: AppColors.gold500, size: 14),
                            const SizedBox(width: 6),
                            Text('$capacity kW Grid-Tied Solar',
                                style: AppTextStyles.caption.copyWith(color: AppColors.gold400, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.teal500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.teal500.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, color: AppColors.teal400, size: 14),
                            const SizedBox(width: 4),
                            Text('Active Setup', style: AppTextStyles.caption.copyWith(color: AppColors.teal400)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Current Milestone Status', style: AppTextStyles.caption.copyWith(color: AppColors.grey400)),
                  const SizedBox(height: 4),
                  Text(
                    _formatStageName(currentStage),
                    style: AppTextStyles.headlineLarge.copyWith(color: AppColors.gold400),
                  ),
                  const SizedBox(height: 12),
                  // Progress indicator
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.4,
                      backgroundColor: AppColors.navy900,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold500),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Stage 4 of 10 in Progress', style: AppTextStyles.caption.copyWith(color: AppColors.grey400)),
                      Text('40% Complete', style: AppTextStyles.caption.copyWith(color: AppColors.gold400, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),
          ),

          // REQUIREMENT 1: "Status with Employee No." Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navy800,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.gold500.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold500.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.badge_rounded, color: AppColors.gold500, size: 20),
                        const SizedBox(width: 8),
                        Text('Assigned Project Officer',
                            style: AppTextStyles.labelLarge.copyWith(color: AppColors.white)),
                        const Spacer(),
                        // PROMINENT EMPLOYEE NO BADGE
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: emp.employeeNo));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Employee No. ${emp.employeeNo} copied!'),
                                backgroundColor: AppColors.navy700,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold500.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: AppColors.gold500, width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.copy_rounded, color: AppColors.gold400, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  emp.employeeNo,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.gold400,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.navy600, height: 20),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.gold500.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text(
                              emp.name.isNotEmpty ? emp.name[0] : 'S',
                              style: const TextStyle(
                                color: AppColors.gold500,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(emp.name, style: AppTextStyles.headlineSmall),
                              Text(emp.roleTitle,
                                  style: AppTextStyles.caption.copyWith(color: AppColors.teal400)),
                              Text('Emp ID: ${emp.employeeNo}',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.grey400)),
                            ],
                          ),
                        ),
                        // Quick Contact Actions
                        IconButton(
                          icon: const Icon(Icons.phone_rounded, color: AppColors.success, size: 22),
                          tooltip: 'Call Representative',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Calling ${emp.name} at ${emp.phone}...'),
                                backgroundColor: AppColors.navy700,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.teal400, size: 20),
                          tooltip: 'WhatsApp Representative',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Opening WhatsApp with ${emp.name} (${emp.employeeNo})...'),
                                backgroundColor: AppColors.navy700,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08, end: 0),
            ),
          ),

          // Quick Action Shortcut Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onOpenPayment,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.navy800,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.payment_rounded, color: AppColors.gold500, size: 18),
                            const SizedBox(width: 8),
                            Text('Submit Payment',
                                style: AppTextStyles.labelMedium.copyWith(color: AppColors.gold400, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: onOpenTicket,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.navy800,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.orange500.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.support_agent_rounded, color: AppColors.orange500, size: 18),
                            const SizedBox(width: 8),
                            Text('Raise Ticket',
                                style: AppTextStyles.labelMedium.copyWith(color: AppColors.orange400, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 10-Stage Milestone Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('10-Stage Project Milestones', style: AppTextStyles.headlineSmall),
                  Text('Real-time sync', style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
                ],
              ),
            ),
          ),

          // Timeline Tile List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = timelineRaw.length > i ? timelineRaw[i] as Map<String, dynamic> : null;
                  final title = item?['title'] ?? 'Milestone ${i + 1}';
                  final status = item?['status'] ?? (i < 3 ? 'done' : (i == 3 ? 'current' : 'upcoming'));
                  final note = item?['note'];

                  final isDone = status == 'done';
                  final isCurrent = status == 'current';

                  return TimelineTile(
                    alignment: TimelineAlign.start,
                    isFirst: i == 0,
                    isLast: i == (timelineRaw.isNotEmpty ? timelineRaw.length - 1 : 9),
                    indicatorStyle: IndicatorStyle(
                      width: 28,
                      height: 28,
                      indicator: Container(
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppColors.success.withValues(alpha: 0.2)
                              : (isCurrent ? AppColors.gold500.withValues(alpha: 0.2) : AppColors.navy800),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDone
                                ? AppColors.success
                                : (isCurrent ? AppColors.gold500 : AppColors.navy600),
                            width: isCurrent ? 2.5 : 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isDone ? Icons.check_rounded : (isCurrent ? Icons.rotate_right_rounded : Icons.circle_outlined),
                            color: isDone
                                ? AppColors.success
                                : (isCurrent ? AppColors.gold500 : AppColors.grey600),
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                    beforeLineStyle: LineStyle(
                      color: isDone ? AppColors.success.withValues(alpha: 0.6) : AppColors.navy700,
                      thickness: 2,
                    ),
                    afterLineStyle: LineStyle(
                      color: isDone ? AppColors.success.withValues(alpha: 0.6) : AppColors.navy700,
                      thickness: 2,
                    ),
                    endChild: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 0, 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.gold500.withValues(alpha: 0.08)
                              : (isDone ? AppColors.navy800 : AppColors.navy900),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.gold500.withValues(alpha: 0.4)
                                : (isDone ? AppColors.success.withValues(alpha: 0.2) : AppColors.navy700),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('${i + 1}. ',
                                    style: TextStyle(
                                      color: isCurrent ? AppColors.gold500 : AppColors.grey500,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    )),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: isDone || isCurrent ? AppColors.white : AppColors.grey400,
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isDone)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('DONE ✓',
                                        style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                                  )
                                else if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold500.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('IN PROGRESS',
                                        style: TextStyle(fontSize: 10, color: AppColors.gold400, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            if (note != null && note.toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                note.toString(),
                                style: AppTextStyles.caption.copyWith(color: AppColors.grey300),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: timelineRaw.isNotEmpty ? timelineRaw.length : 10,
              ),
            ),
          ),

          // Technical Specs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navy800,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.navy600),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.settings_suggest_rounded, color: AppColors.teal400, size: 20),
                        const SizedBox(width: 8),
                        Text('System Technical Specifications', style: AppTextStyles.labelLarge),
                      ],
                    ),
                    const Divider(color: AppColors.navy600, height: 16),
                    _specRow('System Capacity', '${specs['capacity_kw'] ?? 5.5} kW'),
                    _specRow('Grid Phase', specs['phase']?.toString() ?? 'Three Phase'),
                    _specRow('Solar Panels', '${specs['panel_count'] ?? 10}x ${specs['panel_watt'] ?? 550}W (${specs['panel_brand'] ?? 'Tata / Waaree'})'),
                    _specRow('Inverter', specs['inverter_brand']?.toString() ?? 'Growatt 6kW Hybrid'),
                    _specRow('Mounting Structure', specs['structure_type']?.toString() ?? 'Hot-dip Galvanized Elevated'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.grey400)),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey200, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatStageName(String stage) {
    return stage
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '')
        .join(' ');
  }
}

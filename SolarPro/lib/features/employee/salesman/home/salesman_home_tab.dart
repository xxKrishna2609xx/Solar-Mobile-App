import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_pro/core/constants/app_constants.dart';
import 'package:solar_pro/core/theme/app_theme.dart';
import 'package:solar_pro/features/employee/salesman/leads/add_lead_bottom_sheet.dart';
import 'package:solar_pro/features/employee/salesman/leads/salesman_lead_detail_screen.dart';
import 'package:solar_pro/features/leads/data/lead_repository.dart';
import 'package:solar_pro/features/leads/data/models/lead_model.dart';
import 'package:solar_pro/shared/widgets/sp_stat_card.dart';

class SalesmanHomeTab extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const SalesmanHomeTab({super.key, this.onNavigateTab});

  @override
  State<SalesmanHomeTab> createState() => _SalesmanHomeTabState();
}

class _SalesmanHomeTabState extends State<SalesmanHomeTab> {
  final LeadRepository _repository = LeadRepository();
  List<LeadModel> _leads = [];
  bool _isLoading = true;
  String _userName = 'Sales Executive';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchDashboardData();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString(AppConstants.kUserName) ?? 'Sales Executive';
        _currentUserId = prefs.getString(AppConstants.kUserId);
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final leads = await _repository.getLeads();
      if (mounted) {
        setState(() {
          _leads = leads;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _callNumber(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Phone +91 $phone copied to dialer'),
        backgroundColor: AppColors.teal500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayFollowUps = _leads.where((l) => l.isFollowUpToday || l.isFollowUpOverdue).toList();
    final closedCount = _leads.where((l) => l.status == 'converted').length;
    final totalLeads = _leads.length;

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      color: AppColors.gold500,
      backgroundColor: AppColors.navy800,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navy800, Color(0xFF162544)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.navy600),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.gold500.withValues(alpha: 0.2),
                    child: const Icon(Icons.solar_power_rounded, color: AppColors.gold500, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: AppTextStyles.caption.copyWith(color: AppColors.grey400, fontSize: 12),
                        ),
                        Text(
                          _userName,
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.gold500),
                    onPressed: _fetchDashboardData,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // KPI Grid
            Row(
              children: [
                Expanded(
                  child: SpStatCard(
                    label: 'Total Pipeline',
                    value: totalLeads.toString(),
                    change: 'Assigned',
                    icon: Icons.groups_rounded,
                    iconColor: AppColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SpStatCard(
                    label: 'Due Follow-ups',
                    value: todayFollowUps.length.toString(),
                    change: todayFollowUps.any((l) => l.isFollowUpOverdue) ? 'Overdue' : 'Today',
                    icon: Icons.alarm_rounded,
                    iconColor: todayFollowUps.isNotEmpty ? AppColors.gold500 : AppColors.teal500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SpStatCard(
                    label: 'Converted Sales',
                    value: closedCount.toString(),
                    change: 'Closed',
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.teal500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final newLead = await AddLeadBottomSheet.show(context);
                      if (newLead != null) {
                        _fetchDashboardData();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.gold500.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.4)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.person_add_alt_1_rounded, color: AppColors.gold500, size: 24),
                          SizedBox(height: 8),
                          Text(
                            '+ Add Lead',
                            style: TextStyle(color: AppColors.gold500, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Quick prospect capture',
                            style: TextStyle(color: AppColors.grey400, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Today's Follow-ups Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.alarm_on_rounded, color: AppColors.gold500, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Today's Follow-ups",
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                if (todayFollowUps.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gold500,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${todayFollowUps.length} DUE',
                      style: const TextStyle(color: AppColors.navy900, fontWeight: FontWeight.w800, fontSize: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.gold500),
                ),
              )
            else if (todayFollowUps.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.navy800,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.navy600),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.celebration_rounded, color: AppColors.teal500, size: 36),
                    SizedBox(height: 10),
                    Text(
                      'All caught up for today!',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'No prospect calls or visits are pending right now.',
                      style: TextStyle(color: AppColors.grey500, fontSize: 12),
                    ),
                  ],
                ),
              )

            else
              Column(
                children: todayFollowUps.map((lead) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.navy800,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: lead.isFollowUpOverdue ? AppColors.error : AppColors.gold500.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.gold500.withValues(alpha: 0.15),
                          child: Text(
                            lead.name.isNotEmpty ? lead.name[0].toUpperCase() : 'L',
                            style: const TextStyle(color: AppColors.gold500, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lead.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lead.followUpDate != null
                                    ? DateFormat('hh:mm a').format(lead.followUpDate!)
                                    : 'Today',
                                style: TextStyle(
                                  color: lead.isFollowUpOverdue ? AppColors.error : AppColors.gold400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (lead.notes != null && lead.notes!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  lead.notes!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.grey400, fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone_rounded, color: AppColors.teal500),
                          onPressed: () => _callNumber(lead.phone),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => SalesmanLeadDetailScreen(
                                  lead: lead,
                                  currentUserId: _currentUserId,
                                  onLeadUpdated: _fetchDashboardData,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),
            // Bottom Action to View Pipeline
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => widget.onNavigateTab?.call(1),
                icon: const Icon(Icons.view_list_rounded, size: 18),
                label: const Text('View Full Leads Pipeline'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.navy600),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

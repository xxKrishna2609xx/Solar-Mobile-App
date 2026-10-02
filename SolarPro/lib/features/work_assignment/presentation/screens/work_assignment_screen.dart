import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solar_pro/core/theme/app_theme.dart';

class WorkAssignmentScreen extends StatefulWidget {
  const WorkAssignmentScreen({super.key});

  @override
  State<WorkAssignmentScreen> createState() => _WorkAssignmentScreenState();
}

class _WorkAssignmentScreenState extends State<WorkAssignmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_WorkJob> _structureJobs = [
    _WorkJob('1', 'Rajesh Kumar', 'Team A (Sunil)', 'in_progress', '23 Sep', '25 Sep', 'Sector 21'),
    _WorkJob('2', 'Sunita Devi', 'Team B (Mukesh)', 'pending', '26 Sep', '28 Sep', 'Janakpuri'),
    _WorkJob('3', 'Anil Mehta', 'Team A (Sunil)', 'completed', '10 Sep', '12 Sep', 'Pitampura'),
  ];

  final List<_WorkJob> _electricalJobs = [
    _WorkJob('4', 'Vikram Joshi', 'Team B (Mukesh)', 'completed', '15 Sep', '16 Sep', 'Rohini'),
    _WorkJob('5', 'Priya Sharma', 'Team A (Sunil)', 'in_progress', '24 Sep', '25 Sep', 'Dwarka'),
  ];

  final List<_WorkJob> _civilJobs = [
    _WorkJob('6', 'Kavita Singh', 'Team C (Harish)', 'pending', '27 Sep', '29 Sep', 'Shalimar Bagh'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onJobStatusChange(_WorkJob job, String type, String newStatus) {
    setState(() {
      final list = switch (type) {
        'Structure' => _structureJobs,
        'Electrical' => _electricalJobs,
        _ => _civilJobs,
      };
      final idx = list.indexWhere((it) => it.id == job.id);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(status: newStatus);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Job for ${job.customer} updated to ${newStatus.replaceAll('_', ' ').toUpperCase()}'),
        backgroundColor: newStatus == 'completed' ? AppColors.success : AppColors.warning,
      ),
    );
  }

  void _showJobDetailSheet(BuildContext context, _WorkJob job, String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navy800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.grey600,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.customer, style: AppTextStyles.headlineSmall),
                      Text('$type Work • ${job.location}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.gold400)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (job.status == 'completed'
                            ? AppColors.success
                            : AppColors.warning)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    job.status.replaceAll('_', ' ').toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                        color: job.status == 'completed'
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.navy700,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.groups_rounded,
                          size: 16, color: AppColors.gold500),
                      const SizedBox(width: 8),
                      Text('Assigned: ', style: AppTextStyles.caption),
                      Text(job.team, style: AppTextStyles.labelMedium),
                    ],
                  ),
                  const Divider(height: 16, color: AppColors.navy600),
                  Row(
                    children: [
                      const Icon(Icons.date_range_rounded,
                          size: 16, color: AppColors.teal500),
                      const SizedBox(width: 8),
                      Text('Schedule: ', style: AppTextStyles.caption),
                      Text('${job.start} to ${job.end}',
                          style: AppTextStyles.labelMedium),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling Team Lead for ${job.team}...'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.call_rounded,
                              color: AppColors.success, size: 18),
                          const SizedBox(width: 6),
                          Text('Call Team Lead',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: AppColors.success)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _onJobStatusChange(job, type, 'completed');
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Center(
                        child: Text('Mark Done ✓',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.navy900)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignSheet(BuildContext context) {
    String selectedType = 'Structure';
    final nameCtrl = TextEditingController();
    final teamCtrl = TextEditingController(text: 'Team A (Sunil)');
    final startCtrl = TextEditingController(text: 'Today');
    final endCtrl = TextEditingController(text: 'In 3 Days');
    final locCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navy800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.grey600,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Assign Work', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 16),
                Text('Work Type',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.grey400)),
                const SizedBox(height: 8),
                Row(
                  children: ['Structure', 'Electrical', 'Civil'].map((t) {
                    final colors = {
                      'Structure': AppColors.orange500,
                      'Electrical': AppColors.purple500,
                      'Civil': AppColors.teal500
                    };
                    final isSel = selectedType == t;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedType = t),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSel
                                ? colors[t]!.withValues(alpha: 0.25)
                                : AppColors.navy700,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                                color: isSel ? colors[t]! : AppColors.navy600,
                                width: isSel ? 1.5 : 1),
                          ),
                          child: Center(
                            child: Text(t,
                                style: AppTextStyles.caption.copyWith(
                                    color: isSel
                                        ? colors[t]
                                        : AppColors.grey400,
                                    fontWeight: isSel
                                        ? FontWeight.w600
                                        : FontWeight.normal)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Customer Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Site Location / Area',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: teamCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Team / Technician Name',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Start Date',
                          prefixIcon: Icon(Icons.event_rounded),
                        ),
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endCtrl,
                        decoration: const InputDecoration(
                          hintText: 'End Date',
                          prefixIcon: Icon(Icons.event_available_rounded),
                        ),
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    final cust = nameCtrl.text.trim();
                    final loc = locCtrl.text.trim();
                    if (cust.isEmpty) return;

                    final newJob = _WorkJob(
                      DateTime.now().millisecondsSinceEpoch.toString(),
                      cust,
                      teamCtrl.text.trim().isEmpty
                          ? 'Team A'
                          : teamCtrl.text.trim(),
                      'pending',
                      startCtrl.text.trim(),
                      endCtrl.text.trim(),
                      loc.isEmpty ? 'Site' : loc,
                    );

                    setState(() {
                      if (selectedType == 'Structure') {
                        _structureJobs.insert(0, newJob);
                        _tabController.index = 0;
                      } else if (selectedType == 'Electrical') {
                        _electricalJobs.insert(0, newJob);
                        _tabController.index = 1;
                      } else {
                        _civilJobs.insert(0, newJob);
                        _tabController.index = 2;
                      }
                    });

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '$selectedType work assigned to ${newJob.team} for $cust!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Center(
                      child: Text('Confirm Assignment',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.navy900)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy900,
      appBar: AppBar(
        title: const Text('Work Assignment'),
        actions: [
          IconButton(
            tooltip: 'Assign Work',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.add_rounded,
                  color: Color(0xFF0A1628), size: 18),
            ),
            onPressed: () => _showAssignSheet(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold500,
          labelColor: AppColors.gold500,
          unselectedLabelColor: AppColors.grey500,
          tabs: [
            Tab(text: 'Structure (${_structureJobs.length})'),
            Tab(text: 'Electrical (${_electricalJobs.length})'),
            Tab(text: 'Civil (${_civilJobs.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WorkList(
            type: 'Structure',
            color: AppColors.orange500,
            jobs: _structureJobs,
            onJobTap: (j) => _showJobDetailSheet(context, j, 'Structure'),
          ),
          _WorkList(
            type: 'Electrical',
            color: AppColors.purple500,
            jobs: _electricalJobs,
            onJobTap: (j) => _showJobDetailSheet(context, j, 'Electrical'),
          ),
          _WorkList(
            type: 'Civil',
            color: AppColors.teal500,
            jobs: _civilJobs,
            onJobTap: (j) => _showJobDetailSheet(context, j, 'Civil'),
          ),
        ],
      ),
    );
  }
}

class _WorkList extends StatelessWidget {
  final String type;
  final Color color;
  final List<_WorkJob> jobs;
  final ValueChanged<_WorkJob> onJobTap;

  const _WorkList({
    required this.type,
    required this.color,
    required this.jobs,
    required this.onJobTap,
  });

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(
        child: Text('No $type assignments',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final job = jobs[i];
        final statusColor = switch (job.status) {
          'completed' => AppColors.success,
          'in_progress' => AppColors.warning,
          'pending' => AppColors.grey500,
          _ => AppColors.grey500,
        };
        return GestureDetector(
          onTap: () => onJobTap(job),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.navy800,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(job.customer, style: AppTextStyles.labelLarge),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        job.status.replaceAll('_', ' '),
                        style:
                            AppTextStyles.caption.copyWith(color: statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.groups_rounded, size: 14, color: color),
                    const SizedBox(width: 5),
                    Text(job.team,
                        style: AppTextStyles.bodySmall.copyWith(color: color)),
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.grey500),
                    const SizedBox(width: 5),
                    Text(job.location, style: AppTextStyles.bodySmall),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded,
                        size: 14, color: AppColors.grey500),
                    const SizedBox(width: 5),
                    Text('${job.start} – ${job.end}',
                        style: AppTextStyles.bodySmall),
                    const Spacer(),
                    Text('Tap to manage →',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.gold400, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: i * 80))
            .fadeIn(duration: 380.ms)
            .slideX(begin: 0.05, end: 0);
      },
    );
  }
}

class _WorkJob {
  final String id, customer, team, status, start, end, location;
  const _WorkJob(this.id, this.customer, this.team, this.status, this.start, this.end, this.location);

  _WorkJob copyWith({String? status}) {
    return _WorkJob(
      id,
      customer,
      team,
      status ?? this.status,
      start,
      end,
      location,
    );
  }
}

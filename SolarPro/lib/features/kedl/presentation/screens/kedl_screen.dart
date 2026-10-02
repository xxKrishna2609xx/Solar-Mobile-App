import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solar_pro/core/theme/app_theme.dart';

class KedlScreen extends StatefulWidget {
  const KedlScreen({super.key});

  @override
  State<KedlScreen> createState() => _KedlScreenState();
}

class _KedlScreenState extends State<KedlScreen> {
  String _filterType = 'All';
  final _types = ['All', 'Name Change', 'Load File', 'Net File'];

  final List<_KedlFile> _files = [
    _KedlFile('1', 'Rajesh Kumar', 'name_change', 'demand_paid', 8500, 'Sector 21', 'Rohan Verma'),
    _KedlFile('2', 'Sunita Devi', 'load', 'submitted', 0, 'Janakpuri', 'Rohan Verma'),
    _KedlFile('3', 'Vikram Joshi', 'net', 'approved', 12000, 'Rohini', 'Priti Jain'),
    _KedlFile('4', 'Priya Sharma', 'name_change', 'demand_raised', 7500, 'Dwarka', 'Rohan Verma'),
    _KedlFile('5', 'Anil Mehta', 'load', 'not_started', 0, 'Pitampura', 'Priti Jain'),
    _KedlFile('6', 'Kavita Singh', 'net', 'submitted', 0, 'Shalimar Bagh', 'Rohan Verma'),
  ];

  Color _statusColor(String s) => switch (s) {
        'approved' => AppColors.success,
        'demand_paid' => AppColors.gold500,
        'demand_raised' => AppColors.warning,
        'submitted' => AppColors.teal500,
        _ => AppColors.grey500,
      };

  String _statusLabel(String s) => switch (s) {
        'approved' => 'Approved ✓',
        'demand_paid' => 'Demand Paid',
        'demand_raised' => 'Demand Raised',
        'submitted' => 'Submitted',
        'not_started' => 'Not Started',
        _ => s,
      };

  String _typeLabel(String t) => switch (t) {
        'name_change' => 'Name Change',
        'load' => 'Load File',
        'net' => 'Net File',
        _ => t,
      };

  Color _typeColor(String t) => switch (t) {
        'name_change' => AppColors.gold500,
        'load' => AppColors.teal500,
        'net' => AppColors.purple500,
        _ => AppColors.grey500,
      };

  List<_KedlFile> get _filteredFiles {
    if (_filterType == 'All') return _files;
    final map = {
      'Name Change': 'name_change',
      'Load File': 'load',
      'Net File': 'net',
    };
    final key = map[_filterType];
    return _files.where((f) => f.type == key).toList();
  }

  void _showAddFileSheet(BuildContext context) {
    final custCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final demandCtrl = TextEditingController();
    String type = 'net';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navy800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                Text('New KEDL / Discom File',
                    style: AppTextStyles.headlineMedium),
                const SizedBox(height: 16),
                TextField(
                  controller: custCtrl,
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
                    hintText: 'Area / Substation Division',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: demandCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Demand Amount (₹) - Optional',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                  ),
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 14),
                Text('Application File Type', style: AppTextStyles.caption),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    ('net', 'Net Metering File'),
                    ('load', 'Load Enhancement'),
                    ('name_change', 'Name Change File'),
                  ].map((t) {
                    final isSel = type == t.$1;
                    return GestureDetector(
                      onTap: () => setSheetState(() => type = t.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.gold500.withValues(alpha: 0.2)
                              : AppColors.navy700,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                              color: isSel
                                  ? AppColors.gold500
                                  : AppColors.navy600),
                        ),
                        child: Text(t.$2,
                            style: AppTextStyles.caption.copyWith(
                                color: isSel
                                    ? AppColors.gold400
                                    : AppColors.grey400)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    final cust = custCtrl.text.trim();
                    final loc = locCtrl.text.trim();
                    final dem = int.tryParse(demandCtrl.text.trim()) ?? 0;
                    if (cust.isEmpty) return;

                    final newF = _KedlFile(
                      DateTime.now().millisecondsSinceEpoch.toString(),
                      cust,
                      type,
                      'submitted',
                      dem,
                      loc.isEmpty ? 'Delhi Division' : loc,
                      'Rohan Verma',
                    );

                    setState(() {
                      _files.insert(0, newF);
                    });

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'KEDL ${_typeLabel(type)} created for $cust!'),
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
                      child: Text('Submit File Application',
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

  void _showKedlDetail(BuildContext context, _KedlFile f) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navy800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
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
            Text('${f.customer} — ${_typeLabel(f.type)}',
                style: AppTextStyles.headlineMedium),
            const SizedBox(height: 4),
            Text('Discom Officer: ${f.assignedTo} • ${f.location}',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 20),

            // Status flow
            ...['not_started', 'submitted', 'demand_raised', 'demand_paid', 'approved']
                .map((s) {
              final stages = [
                'not_started',
                'submitted',
                'demand_raised',
                'demand_paid',
                'approved'
              ];
              final active = stages.indexOf(f.status) >= stages.indexOf(s);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? AppColors.success.withValues(alpha: 0.2)
                            : AppColors.navy700,
                        border: Border.all(
                          color: active ? AppColors.success : AppColors.navy500,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        active ? Icons.check_rounded : Icons.circle_outlined,
                        size: 12,
                        color: active ? AppColors.success : AppColors.grey600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _statusLabel(s),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: active ? AppColors.grey200 : AppColors.grey600,
                        fontWeight:
                            s == f.status ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }),

            if (f.demand > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 10),
                    Text('Discom Demand Amount: ₹${f.demand}',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.warning)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling Discom Officer ${f.assignedTo}...'),
                          backgroundColor: AppColors.teal500,
                        ),
                      );
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.teal500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                            color: AppColors.teal500.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.call_rounded,
                              color: AppColors.teal500, size: 18),
                          const SizedBox(width: 6),
                          Text('Call Officer',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: AppColors.teal500)),
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
                      setState(() {
                        final idx = _files.indexWhere((it) => it.id == f.id);
                        if (idx != -1) {
                          final next = switch (f.status) {
                            'not_started' => 'submitted',
                            'submitted' => 'demand_raised',
                            'demand_raised' => 'demand_paid',
                            'demand_paid' => 'approved',
                            _ => 'approved',
                          };
                          _files[idx] = _files[idx].copyWith(status: next);
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('KEDL status advanced to next stage!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Center(
                        child: Text('Advance Stage →',
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

  @override
  Widget build(BuildContext context) {
    final list = _filteredFiles;

    return Scaffold(
      backgroundColor: AppColors.navy900,
      appBar: AppBar(
        title: const Text('KEDL Tracker'),
        actions: [
          IconButton(
            tooltip: 'Add File',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.add_rounded,
                  color: Color(0xFF0A1628), size: 18),
            ),
            onPressed: () => _showAddFileSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Summary cards
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              physics: const BouncingScrollPhysics(),
              children: [
                _KedlSummaryCard(
                  label: 'Name Change',
                  done: _files.where((f) => f.type == 'name_change' && (f.status == 'approved' || f.status == 'demand_paid')).length,
                  total: _files.where((f) => f.type == 'name_change').length,
                  color: AppColors.gold500,
                ),
                const SizedBox(width: 10),
                _KedlSummaryCard(
                  label: 'Load Files',
                  done: _files.where((f) => f.type == 'load' && (f.status == 'approved' || f.status == 'demand_paid')).length,
                  total: _files.where((f) => f.type == 'load').length,
                  color: AppColors.teal500,
                ),
                const SizedBox(width: 10),
                _KedlSummaryCard(
                  label: 'Net Files',
                  done: _files.where((f) => f.type == 'net' && (f.status == 'approved' || f.status == 'demand_paid')).length,
                  total: _files.where((f) => f.type == 'net').length,
                  color: AppColors.purple500,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

          // Filter
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              physics: const BouncingScrollPhysics(),
              itemCount: _types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = _filterType == _types[i];
                return GestureDetector(
                  onTap: () => setState(() => _filterType = _types[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.gold500.withValues(alpha: 0.15)
                          : AppColors.navy800,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: selected ? AppColors.gold500 : AppColors.navy600,
                      ),
                    ),
                    child: Text(
                      _types[i],
                      style: AppTextStyles.labelMedium.copyWith(
                        color:
                            selected ? AppColors.gold400 : AppColors.grey400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 4),

          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text('No files in this category',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.grey500)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    physics: const BouncingScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final f = list[i];
                      final statusColor = _statusColor(f.status);
                      final typeColor = _typeColor(f.type);
                      return GestureDetector(
                        onTap: () => _showKedlDetail(context, f),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.navy800,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(
                                color: typeColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                                child: Icon(Icons.description_rounded,
                                    color: typeColor, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(f.customer,
                                            style: AppTextStyles.labelLarge),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: statusColor
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.pill),
                                          ),
                                          child: Text(
                                            _statusLabel(f.status),
                                            style: AppTextStyles.caption
                                                .copyWith(color: statusColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(_typeLabel(f.type),
                                            style: AppTextStyles.bodySmall
                                                .copyWith(color: typeColor)),
                                        const SizedBox(width: 8),
                                        if (f.demand > 0)
                                          Text(
                                            'Demand: ₹${f.demand ~/ 1000}K',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                    color: AppColors.warning),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.person_outline_rounded,
                                            size: 12,
                                            color: AppColors.grey500),
                                        const SizedBox(width: 4),
                                        Text(
                                            '${f.assignedTo} • ${f.location}',
                                            style: AppTextStyles.caption),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.grey600),
                            ],
                          ),
                        ),
                      )
                          .animate(delay: Duration(milliseconds: i * 70))
                          .fadeIn(duration: 350.ms)
                          .slideX(begin: 0.05, end: 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _KedlSummaryCard extends StatelessWidget {
  final String label;
  final int done, total;
  final Color color;
  const _KedlSummaryCard(
      {required this.label,
      required this.done,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: color)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$done',
                  style: AppTextStyles.headlineLarge
                      .copyWith(color: color, fontSize: 28)),
              Text('/$total',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: color.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
    );
  }
}

class _KedlFile {
  final String id, customer, type, status, location, assignedTo;
  final int demand;
  const _KedlFile(this.id, this.customer, this.type, this.status, this.demand,
      this.location, this.assignedTo);

  _KedlFile copyWith({String? status}) {
    return _KedlFile(
      id,
      customer,
      type,
      status ?? this.status,
      demand,
      location,
      assignedTo,
    );
  }
}

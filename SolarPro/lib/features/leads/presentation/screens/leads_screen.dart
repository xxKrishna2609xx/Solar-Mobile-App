import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_pro/core/theme/app_theme.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_Lead> _openLeads = [
    _Lead(
        id: '1',
        name: 'Sunita Devi',
        phone: '9876543210',
        area: 'Sector 12',
        kw: 3,
        status: 'follow_up',
        source: 'Reference',
        referrerName: 'Amit Verma'),
    _Lead(
        id: '2',
        name: 'Manoj Patel',
        phone: '9123456789',
        area: 'Rajouri Garden',
        kw: 5,
        status: 'new',
        source: 'WhatsApp'),
    _Lead(
        id: '3',
        name: 'Ramesh Gupta',
        phone: '9988776655',
        area: 'Dwarka Sec 7',
        kw: 8,
        status: 'contacted',
        source: 'Instagram'),
    _Lead(
        id: '4',
        name: 'Kavita Singh',
        phone: '9911223344',
        area: 'Janakpuri',
        kw: 4,
        status: 'follow_up',
        source: 'Call'),
    _Lead(
        id: '5',
        name: 'Anil Kumar',
        phone: '9870001111',
        area: 'Pitampura',
        kw: 10,
        status: 'new',
        source: 'Website'),
  ];

  final List<_Lead> _closedLeads = [
    _Lead(
        id: '6',
        name: 'Priya Sharma',
        phone: '9765432100',
        area: 'Rohini',
        kw: 5,
        status: 'converted',
        source: 'Reference',
        referrerName: 'Dr. S. K. Gupta'),
    _Lead(
        id: '7',
        name: 'Vikram Joshi',
        phone: '9654321000',
        area: 'Shalimar Bagh',
        kw: 7,
        status: 'converted',
        source: 'Facebook'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    return switch (status) {
      'new' => AppColors.teal500,
      'contacted' => AppColors.info,
      'follow_up' => AppColors.warning,
      'converted' => AppColors.success,
      'lost' => AppColors.error,
      _ => AppColors.grey500,
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'new' => 'New',
      'contacted' => 'Contacted',
      'follow_up' => 'Follow Up',
      'converted' => 'Converted',
      'lost' => 'Lost',
      _ => status,
    };
  }

  List<_Lead> _filtered(List<_Lead> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((l) {
      return l.name.toLowerCase().contains(_searchQuery) ||
          l.phone.contains(_searchQuery) ||
          l.area.toLowerCase().contains(_searchQuery) ||
          (l.referrerName?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  void _onStatusChanged(_Lead lead, String newStatus) {
    setState(() {
      _openLeads.removeWhere((l) => l.id == lead.id);
      _closedLeads.removeWhere((l) => l.id == lead.id);
      final updated = lead.copyWith(status: newStatus);
      if (newStatus == 'converted' || newStatus == 'lost') {
        _closedLeads.insert(0, updated);
      } else {
        _openLeads.insert(0, updated);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lead status updated to ${_statusLabel(newStatus)}'),
        backgroundColor: _statusColor(newStatus),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredOpen = _filtered(_openLeads);
    final filteredClosed = _filtered(_closedLeads);

    return Scaffold(
      backgroundColor: AppColors.navy900,
      appBar: AppBar(
        title: const Text('Lead Management'),
        actions: [
          IconButton(
            tooltip: 'Add Lead',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.add_rounded, color: Color(0xFF0A1628), size: 18),
            ),
            onPressed: () => _showAddLeadSheet(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold500,
          indicatorWeight: 2,
          labelStyle: AppTextStyles.labelLarge,
          unselectedLabelStyle: AppTextStyles.bodyMedium,
          labelColor: AppColors.gold500,
          unselectedLabelColor: AppColors.grey500,
          tabs: [
            Tab(text: 'Open (${_openLeads.length})'),
            Tab(text: 'Closed (${_closedLeads.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Search leads by name, phone, area...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _LeadList(
                  leads: filteredOpen,
                  statusColor: _statusColor,
                  statusLabel: _statusLabel,
                  onLeadTap: (l) => _showLeadDetailSheet(context, l),
                ),
                _LeadList(
                  leads: filteredClosed,
                  statusColor: _statusColor,
                  statusLabel: _statusLabel,
                  onLeadTap: (l) => _showLeadDetailSheet(context, l),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddLeadSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final kwCtrl = TextEditingController();
    final referrerCtrl = TextEditingController();
    String source = 'Reference';

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
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Add New Lead', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Customer Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Mobile Number (10 digits)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: areaCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Area / Location',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: kwCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Expected kW',
                          prefixIcon: Icon(Icons.bolt_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Lead Source',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.grey400)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Reference', 'WhatsApp', 'Instagram', 'Call', 'Website']
                      .map((s) {
                    final isSel = source == s;
                    return GestureDetector(
                      onTap: () => setSheetState(() => source = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.gold500.withValues(alpha: 0.15)
                              : AppColors.navy700,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: isSel ? AppColors.gold500 : AppColors.navy600,
                          ),
                        ),
                        child: Text(
                          s,
                          style: AppTextStyles.caption.copyWith(
                            color: isSel ? AppColors.gold400 : AppColors.grey400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (source == 'Reference') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: referrerCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Referred By (Name of Person)',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                  ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0),
                ],
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    final name = nameCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    final area = areaCtrl.text.trim();
                    final kw = int.tryParse(kwCtrl.text.trim()) ?? 3;
                    final referrer = source == 'Reference'
                        ? referrerCtrl.text.trim()
                        : null;

                    if (name.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter name and phone number'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    final newLead = _Lead(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      phone: phone,
                      area: area.isEmpty ? 'Delhi NCR' : area,
                      kw: kw,
                      status: 'new',
                      source: source,
                      referrerName: referrer?.isNotEmpty == true ? referrer : null,
                    );

                    setState(() {
                      _openLeads.insert(0, newLead);
                    });

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lead "${newLead.name}" added successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold500.withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Save Lead',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.navy900),
                      ),
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

  void _showLeadDetailSheet(BuildContext context, _Lead lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _statusColor(lead.status).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      lead.name[0],
                      style: AppTextStyles.headlineMedium
                          .copyWith(color: _statusColor(lead.status)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lead.name, style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 2),
                      Text('+91 ${lead.phone}', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(lead.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    _statusLabel(lead.status),
                    style: AppTextStyles.caption
                        .copyWith(color: _statusColor(lead.status)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Info rows
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navy700,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.navy600),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.grey400),
                      const SizedBox(width: 8),
                      Text('Area: ', style: AppTextStyles.caption),
                      Text(lead.area, style: AppTextStyles.labelMedium),
                      const Spacer(),
                      const Icon(Icons.bolt_rounded, size: 16, color: AppColors.gold500),
                      const SizedBox(width: 4),
                      Text('${lead.kw} kW Expected',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.gold400)),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.navy600),
                  Row(
                    children: [
                      const Icon(Icons.source_rounded,
                          size: 16, color: AppColors.teal500),
                      const SizedBox(width: 8),
                      Text('Source: ', style: AppTextStyles.caption),
                      Text(
                        lead.source == 'Reference' &&
                                (lead.referrerName?.isNotEmpty ?? false)
                            ? 'Reference (by ${lead.referrerName})'
                            : lead.source,
                        style: AppTextStyles.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons: Call & WhatsApp
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.phone_in_talk_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text('Calling +91 ${lead.phone}...'),
                            ],
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.call_rounded,
                              color: AppColors.success, size: 18),
                          const SizedBox(width: 8),
                          Text('Call Lead',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: AppColors.success)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.chat_bubble_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text('Opening WhatsApp chat with ${lead.name}...'),
                            ],
                          ),
                          backgroundColor: AppColors.teal500,
                        ),
                      );
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.teal500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                            color: AppColors.teal500.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_rounded,
                              color: AppColors.teal500, size: 18),
                          const SizedBox(width: 8),
                          Text('WhatsApp',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: AppColors.teal500)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text('Update Status',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.grey400)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['new', 'contacted', 'follow_up', 'converted', 'lost'].map((st) {
                final isCurrent = lead.status == st;
                final col = _statusColor(st);
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _onStatusChanged(lead, st);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrent ? col.withValues(alpha: 0.2) : AppColors.navy700,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: isCurrent ? col : AppColors.navy600,
                        width: isCurrent ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      _statusLabel(st),
                      style: AppTextStyles.caption.copyWith(
                        color: isCurrent ? col : AppColors.grey400,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Convert to customer button
            if (lead.status != 'converted')
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _onStatusChanged(lead, 'converted');
                  context.push(
                      '/vendor/customers/${lead.name.replaceAll(' ', '-').toLowerCase()}');
                },
                child: Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Center(
                    child: Text(
                      'Convert to Customer & Open Profile →',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.navy900),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LeadList extends StatelessWidget {
  final List<_Lead> leads;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;
  final ValueChanged<_Lead> onLeadTap;

  const _LeadList({
    required this.leads,
    required this.statusColor,
    required this.statusLabel,
    required this.onLeadTap,
  });

  @override
  Widget build(BuildContext context) {
    if (leads.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline_rounded,
                color: AppColors.grey600, size: 48),
            const SizedBox(height: 12),
            Text('No leads found',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: leads.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final lead = leads[i];
        final color = statusColor(lead.status);
        return GestureDetector(
          onTap: () => onLeadTap(lead),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.navy800,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.navy600),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      lead.name[0],
                      style: AppTextStyles.headlineSmall.copyWith(color: color),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(lead.name, style: AppTextStyles.labelLarge),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              statusLabel(lead.status),
                              style: AppTextStyles.caption.copyWith(color: color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.grey500),
                          const SizedBox(width: 4),
                          Text(lead.area, style: AppTextStyles.bodySmall),
                          const SizedBox(width: 12),
                          const Icon(Icons.bolt_rounded,
                              size: 12, color: AppColors.gold500),
                          const SizedBox(width: 4),
                          Text('${lead.kw} kW',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.gold400)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lead.source == 'Reference' &&
                                      (lead.referrerName?.isNotEmpty ?? false)
                                  ? 'Source: Reference (${lead.referrerName})'
                                  : 'Source: ${lead.source}',
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tap for details →',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.gold400, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: i * 60))
            .fadeIn(duration: 350.ms)
            .slideX(begin: 0.05, end: 0);
      },
    );
  }
}

class _Lead {
  final String id, name, phone, area, status, source;
  final String? referrerName;
  final int kw;
  const _Lead({
    required this.id,
    required this.name,
    required this.phone,
    required this.area,
    required this.kw,
    required this.status,
    required this.source,
    this.referrerName,
  });

  _Lead copyWith({
    String? id,
    String? name,
    String? phone,
    String? area,
    String? status,
    String? source,
    String? referrerName,
    int? kw,
  }) {
    return _Lead(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      area: area ?? this.area,
      status: status ?? this.status,
      source: source ?? this.source,
      referrerName: referrerName ?? this.referrerName,
      kw: kw ?? this.kw,
    );
  }
}

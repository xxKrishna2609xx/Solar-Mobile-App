import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:solar_pro/core/theme/app_theme.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late _CustomerInfo _customer;

  final List<_StageInfo> _stages = [
    _StageInfo('Sale Confirmed', true, AppColors.success, Icons.handshake_rounded),
    _StageInfo('Docs Received', true, AppColors.success, Icons.folder_rounded),
    _StageInfo('Advance Verified', true, AppColors.success, Icons.verified_rounded),
    _StageInfo('Structure Work', true, AppColors.success, Icons.foundation_rounded),
    _StageInfo('Electrical Work', true, AppColors.success, Icons.electrical_services_rounded),
    _StageInfo('Civil Work', false, AppColors.warning, Icons.construction_rounded),
    _StageInfo('Installation Done', false, AppColors.grey600, Icons.solar_power_rounded),
    _StageInfo('KEDL Process', false, AppColors.grey600, Icons.description_rounded),
    _StageInfo('Net Meter Installed', false, AppColors.grey600, Icons.bolt_rounded),
    _StageInfo('Handed Over', false, AppColors.grey600, Icons.celebration_rounded),
  ];

  late List<_DocItem> _documents;
  late List<_PaymentRecord> _payments;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initCustomerData();
  }

  void _initCustomerData() {
    final id = widget.customerId.toLowerCase();
    if (id.contains('sunita')) {
      _customer = const _CustomerInfo(
        name: 'Sunita Devi',
        phone: '9876500002',
        address: 'Janakpuri, Delhi',
        kw: 3,
        phase: 'Single Phase',
        amount: 150000,
        paid: 75000,
      );
    } else if (id.contains('vikram')) {
      _customer = const _CustomerInfo(
        name: 'Vikram Joshi',
        phone: '9876500003',
        address: 'Rohini Sec 14',
        kw: 7,
        phase: 'Three Phase',
        amount: 350000,
        paid: 350000,
      );
    } else if (id.contains('priya')) {
      _customer = const _CustomerInfo(
        name: 'Priya Sharma',
        phone: '9876500004',
        address: 'Pitampura, Delhi',
        kw: 4,
        phase: 'Single Phase',
        amount: 200000,
        paid: 60000,
      );
    } else if (id.contains('anil')) {
      _customer = const _CustomerInfo(
        name: 'Anil Mehta',
        phone: '9876500005',
        address: 'Shalimar Bagh',
        kw: 10,
        phase: 'Three Phase',
        amount: 500000,
        paid: 350000,
      );
    } else if (id.contains('kavita')) {
      _customer = const _CustomerInfo(
        name: 'Kavita Singh',
        phone: '9876500006',
        address: 'Rajouri Garden',
        kw: 8,
        phase: 'Three Phase',
        amount: 400000,
        paid: 200000,
      );
    } else {
      _customer = const _CustomerInfo(
        name: 'Rajesh Kumar',
        phone: '9876500001',
        address: 'Sector 21, Dwarka',
        kw: 5,
        phase: 'Single Phase',
        amount: 250000,
        paid: 200000,
      );
    }

    _documents = [
      _DocItem('E-Bill', Icons.receipt_long_rounded, AppColors.teal500, true),
      _DocItem('Aadhaar Card', Icons.badge_rounded, AppColors.gold500, true),
      _DocItem('PAN Card', Icons.credit_card_rounded, AppColors.info, true),
      _DocItem('Cancelled Cheque', Icons.account_balance_rounded, AppColors.orange500, false),
      _DocItem('Registry (Property Paper)', Icons.home_work_rounded, AppColors.purple500, false),
    ];

    _payments = [
      _PaymentRecord(1, (_customer.amount * 0.25).round(), 'Advance (25%)', 'verified', '12 Sep 2026', 'UPI'),
      _PaymentRecord(2, (_customer.amount * 0.35).round(), '2nd Instalment', 'verified', '25 Sep 2026', 'NEFT'),
      _PaymentRecord(3, (_customer.amount * 0.20).round(), '3rd Instalment', 'sales_approved', '01 Oct 2026', 'Cheque'),
      _PaymentRecord(4, (_customer.amount * 0.20).round(), 'Final Balance', 'pending', 'Due on completion', 'Pending'),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _uploadDocument(int index) {
    setState(() {
      _documents[index] = _documents[index].copyWith(uploaded: true);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document "${_documents[index].name}" uploaded and verified!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _addPaymentRecord(int amount, String mode, String label) {
    setState(() {
      _payments.insert(
        0,
        _PaymentRecord(
          _payments.length + 1,
          amount,
          label,
          'verified',
          'Today',
          mode,
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment of ₹$amount recorded successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy900,
      appBar: AppBar(
        title: Text(_customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Project proposal & summary shared via WhatsApp/Email!'),
                  backgroundColor: AppColors.teal500,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.cardGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Avatar
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              gradient: AppColors.goldGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _customer.name[0],
                                style: const TextStyle(
                                  color: Color(0xFF0A1628),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_customer.name, style: AppTextStyles.headlineLarge),
                                const SizedBox(height: 2),
                                Text('+91 ${_customer.phone}', style: AppTextStyles.bodySmall),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 13, color: AppColors.grey500),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _customer.address,
                                        style: AppTextStyles.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Call button
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Calling ${_customer.name} (+91 ${_customer.phone})...'),
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
                                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(Icons.call_rounded, color: AppColors.success, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // WhatsApp button
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Opening WhatsApp with ${_customer.name}...'),
                                  backgroundColor: AppColors.teal500,
                                ),
                              );
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.teal500.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.teal500.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(Icons.chat_bubble_outline_rounded,
                                  color: AppColors.teal500, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _InfoChip(label: '${_customer.kw} kW', icon: Icons.bolt_rounded, color: AppColors.gold500),
                          const SizedBox(width: 10),
                          _InfoChip(label: _customer.phase, icon: Icons.electrical_services_rounded, color: AppColors.teal500),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.gold500.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '₹${(_customer.amount / 100000).toStringAsFixed(1)}L Project',
                              style: AppTextStyles.caption.copyWith(color: AppColors.gold400),
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
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.gold500,
                labelColor: AppColors.gold500,
                unselectedLabelColor: AppColors.grey500,
                tabs: const [
                  Tab(text: 'Timeline'),
                  Tab(text: 'Documents'),
                  Tab(text: 'Payments'),
                  Tab(text: 'Work'),
                  Tab(text: 'KEDL'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _TimelineTab(stages: _stages),
            _DocumentsTab(
              docs: _documents,
              onUpload: _uploadDocument,
            ),
            _PaymentsTab(
              payments: _payments,
              totalAmount: _customer.amount,
              paidAmount: _customer.paid,
              onAddPayment: _addPaymentRecord,
            ),
            _WorkTab(customerName: _customer.name),
            _KedlTab(customerName: _customer.name),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.navy800,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// ── Timeline Tab ──────────────────────────────────────────────────────────────

class _TimelineTab extends StatelessWidget {
  final List<_StageInfo> stages;
  const _TimelineTab({required this.stages});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      physics: const BouncingScrollPhysics(),
      itemCount: stages.length,
      itemBuilder: (context, i) {
        final stage = stages[i];
        final isFirst = i == 0;
        final isLast = i == stages.length - 1;
        return TimelineTile(
          alignment: TimelineAlign.start,
          isFirst: isFirst,
          isLast: isLast,
          indicatorStyle: IndicatorStyle(
            width: 36,
            height: 36,
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
                stage.done ? stage.icon : Icons.radio_button_unchecked_rounded,
                color: stage.done ? stage.color : AppColors.grey600,
                size: 18,
              ),
            ),
          ),
          beforeLineStyle: LineStyle(
            color: stages[i > 0 ? i - 1 : 0].done
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
            padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: stage.done
                    ? stage.color.withValues(alpha: 0.06)
                    : AppColors.navy800,
                borderRadius: BorderRadius.circular(AppRadius.lg),
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
                        color: stage.done ? AppColors.white : AppColors.grey500,
                        fontWeight: stage.done ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (stage.done)
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 18),
                ],
              ),
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: i * 60))
            .fadeIn(duration: 350.ms)
            .slideX(begin: 0.1, end: 0);
      },
    );
  }
}

// ── Documents Tab ─────────────────────────────────────────────────────────────

class _DocumentsTab extends StatelessWidget {
  final List<_DocItem> docs;
  final ValueChanged<int> onUpload;

  const _DocumentsTab({required this.docs, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = docs[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.navy800,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.navy600),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.name,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey200),
                ),
              ),
              item.uploaded
                  ? GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Previewing verified ${item.name}...'),
                            backgroundColor: AppColors.teal500,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Uploaded',
                                style: AppTextStyles.caption.copyWith(color: AppColors.success)),
                            const SizedBox(width: 4),
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.success, size: 16),
                          ],
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () => onUpload(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.gold500.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.gold500.withValues(alpha: 0.6)),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.file_upload_outlined,
                                size: 14, color: AppColors.gold400),
                            const SizedBox(width: 4),
                            Text('Upload',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.gold400, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: i * 70))
            .fadeIn(duration: 350.ms);
      },
    );
  }
}

// ── Payments Tab ──────────────────────────────────────────────────────────────

class _PaymentsTab extends StatelessWidget {
  final List<_PaymentRecord> payments;
  final int totalAmount;
  final int paidAmount;
  final Function(int, String, String) onAddPayment;

  const _PaymentsTab({
    required this.payments,
    required this.totalAmount,
    required this.paidAmount,
    required this.onAddPayment,
  });

  void _showRecordPaymentSheet(BuildContext context) {
    final amtCtrl = TextEditingController();
    String mode = 'UPI';
    final noteCtrl = TextEditingController(text: 'Instalment Payment');

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
              Text('Record Payment', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 16),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  hintText: 'Description / Milestone',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 14),
              Text('Payment Mode', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['UPI', 'NEFT/RTGS', 'Cheque', 'Cash'].map((m) {
                  final isSel = mode == m;
                  return GestureDetector(
                    onTap: () => setSheetState(() => mode = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.gold500.withValues(alpha: 0.2)
                            : AppColors.navy700,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                            color: isSel ? AppColors.gold500 : AppColors.navy600),
                      ),
                      child: Text(m,
                          style: AppTextStyles.caption.copyWith(
                              color: isSel ? AppColors.gold400 : AppColors.grey400)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  final amt = int.tryParse(amtCtrl.text.trim()) ?? 0;
                  if (amt <= 0) return;
                  Navigator.pop(ctx);
                  onAddPayment(amt, mode, noteCtrl.text.trim());
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Center(
                    child: Text('Confirm & Save Receipt',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.navy900)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        // Summary & Add Button
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A3A6E), Color(0xFF0F2040)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('₹${(paidAmount / 1000).toStringAsFixed(0)}K Paid',
                            style: AppTextStyles.displaySmall
                                .copyWith(color: AppColors.gold400)),
                        Text('Total ₹${(totalAmount / 1000).toStringAsFixed(0)}K Project',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.navy600,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(AppColors.gold500),
                          strokeWidth: 5,
                        ),
                        Center(
                          child: Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.gold400,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => _showRecordPaymentSheet(context),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.gold500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.gold500.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_card_rounded,
                          size: 16, color: AppColors.gold400),
                      const SizedBox(width: 8),
                      Text('+ Record New Payment',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.gold400)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            physics: const BouncingScrollPhysics(),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final p = payments[i];
              final statusColor = switch (p.status) {
                'verified' => AppColors.success,
                'sales_approved' => AppColors.warning,
                'pending' => AppColors.grey500,
                _ => AppColors.grey500,
              };
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.navy800,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.navy600),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${p.no}',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: statusColor, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.label,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.grey200)),
                          Text('${p.date} • ${p.mode}', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${(p.amount / 1000).toStringAsFixed(0)}K',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: AppColors.white)),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            p.status.replaceAll('_', ' '),
                            style: AppTextStyles.caption
                                .copyWith(color: statusColor, fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: Duration(milliseconds: i * 60)).fadeIn(duration: 350.ms);
            },
          ),
        ),
      ],
    );
  }
}

// ── Work Tab ──────────────────────────────────────────────────────────────────

class _WorkTab extends StatelessWidget {
  final String customerName;
  const _WorkTab({required this.customerName});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: const [
        _WorkCard(
          type: 'Structure Work',
          team: 'Team A (Lead: Sunil)',
          status: 'completed',
          start: '18 Sep',
          end: '20 Sep',
          color: AppColors.orange500,
        ),
        SizedBox(height: 10),
        _WorkCard(
          type: 'Electrical Work',
          team: 'Team B (Lead: Mukesh)',
          status: 'completed',
          start: '21 Sep',
          end: '22 Sep',
          color: AppColors.purple500,
        ),
        SizedBox(height: 10),
        _WorkCard(
          type: 'Civil Work',
          team: 'Team A (Lead: Sunil)',
          status: 'in_progress',
          start: '23 Sep',
          end: '25 Sep',
          color: AppColors.teal500,
        ),
        SizedBox(height: 10),
        _WorkCard(
          type: 'Net Meter Testing',
          team: 'Discom Liaison Officer',
          status: 'pending',
          start: '28 Sep',
          end: '02 Oct',
          color: AppColors.gold500,
        ),
      ],
    );
  }
}

class _WorkCard extends StatelessWidget {
  final String type, team, status, start, end;
  final Color color;
  const _WorkCard({
    required this.type,
    required this.team,
    required this.status,
    required this.start,
    required this.end,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (status) {
      'completed' => AppColors.success,
      'in_progress' => AppColors.warning,
      'pending' => AppColors.grey500,
      _ => AppColors.grey500,
    };
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$type assignment for $team is currently ${status.replaceAll('_', ' ')}.'),
            backgroundColor: color,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.navy800,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.groups_rounded, size: 13, color: color),
                      const SizedBox(width: 5),
                      Text(team, style: AppTextStyles.bodySmall.copyWith(color: color)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.date_range_rounded,
                          size: 13, color: AppColors.grey500),
                      const SizedBox(width: 5),
                      Text('$start – $end', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                status.replaceAll('_', ' '),
                style: AppTextStyles.caption.copyWith(color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── KEDL Tab ──────────────────────────────────────────────────────────────────

class _KedlTab extends StatelessWidget {
  final String customerName;
  const _KedlTab({required this.customerName});

  @override
  Widget build(BuildContext context) {
    final files = [
      ('Name Change File', 'demand_paid', '₹8,500', AppColors.gold500),
      ('Load Enhancement File', 'submitted', '—', AppColors.teal500),
      ('Net Metering File', 'not_started', '—', AppColors.purple500),
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final (name, status, demand, color) = files[i];
        final statusColor = switch (status) {
          'approved' => AppColors.success,
          'demand_paid' => AppColors.gold500,
          'submitted' => AppColors.teal500,
          'demand_raised' => AppColors.warning,
          _ => AppColors.grey500,
        };
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$name status: ${status.replaceAll('_', ' ')}'),
                backgroundColor: color,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.navy800,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.description_rounded, color: color, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.labelLarge),
                      const SizedBox(height: 4),
                      Text('Demand: $demand', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    status.replaceAll('_', ' '),
                    style: AppTextStyles.caption.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: i * 80)).fadeIn(duration: 350.ms);
      },
    );
  }
}

class _CustomerInfo {
  final String name, phone, address, phase;
  final int kw, amount, paid;
  const _CustomerInfo({
    required this.name,
    required this.phone,
    required this.address,
    required this.kw,
    required this.phase,
    required this.amount,
    required this.paid,
  });
}

class _StageInfo {
  final String label;
  final bool done;
  final Color color;
  final IconData icon;
  const _StageInfo(this.label, this.done, this.color, this.icon);
}

class _DocItem {
  final String name;
  final IconData icon;
  final Color color;
  final bool uploaded;
  const _DocItem(this.name, this.icon, this.color, this.uploaded);

  _DocItem copyWith({bool? uploaded}) =>
      _DocItem(name, icon, color, uploaded ?? this.uploaded);
}

class _PaymentRecord {
  final int no, amount;
  final String label, status, date, mode;
  const _PaymentRecord(this.no, this.amount, this.label, this.status, this.date, this.mode);
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _InfoChip({required this.label, required this.icon, required this.color});

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

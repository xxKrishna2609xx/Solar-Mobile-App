import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solar_pro/core/network/api_client.dart';
import 'package:solar_pro/core/theme/app_theme.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  String _filterStage = 'All';
  String _searchQuery = '';

  final _stages = ['All', 'Sale Confirmed', 'Work In Progress', 'KEDL Process', 'Live'];

  List<_Customer> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    try {
      final raw = await ApiClient().getCustomers();
      final List<_Customer> parsed = [];
      for (final item in raw) {
        parsed.add(_Customer(
          id: item['id']?.toString() ?? item['_id']?.toString() ?? '',
          name: item['name']?.toString() ?? 'Unnamed Customer',
          address: item['address']?.toString() ?? 'Delhi NCR',
          kw: (item['kw'] is num) ? (item['kw'] as num).toInt() : 5,
          stage: item['stage']?.toString() ?? 'SALE_CONFIRMED',
          amount: (item['total_amount'] is num) ? (item['total_amount'] as num).toInt() : 200000,
          paid: (item['paid_amount'] is num) ? (item['paid_amount'] as num).toInt() : 50000,
          phone: item['phone']?.toString() ?? '',
        ));
      }
      if (mounted) {
        setState(() {
          _customers = parsed;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _stageColor(String stage) {
    return switch (stage) {
      'SALE_CONFIRMED' => AppColors.info,
      'DOCUMENTS_RECEIVED' => AppColors.teal500,
      'ADVANCE_VERIFIED' => AppColors.warning,
      'STRUCTURE_WORK' => AppColors.orange500,
      'ELECTRICAL_WORK' => AppColors.purple500,
      'CIVIL_WORK' => AppColors.grey400,
      'INSTALLATION_COMPLETE' => AppColors.success,
      'KEDL_PROCESS' => AppColors.gold500,
      'SYSTEM_LIVE' => AppColors.green400,
      'HANDED_OVER' => AppColors.teal500,
      _ => AppColors.grey500,
    };
  }

  String _stageLabel(String stage) {
    return switch (stage) {
      'SALE_CONFIRMED' => 'Sale Confirmed',
      'DOCUMENTS_RECEIVED' => 'Docs Received',
      'ADVANCE_VERIFIED' => 'Advance Verified',
      'STRUCTURE_WORK' => 'Structure Work',
      'ELECTRICAL_WORK' => 'Electrical Work',
      'CIVIL_WORK' => 'Civil Work',
      'INSTALLATION_COMPLETE' => 'Installed',
      'KEDL_PROCESS' => 'KEDL Process',
      'SYSTEM_LIVE' => 'System Live',
      'HANDED_OVER' => 'Handed Over ✓',
      _ => stage,
    };
  }

  List<_Customer> get _filteredCustomers {
    return _customers.where((c) {
      final matchesSearch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery) ||
          c.address.toLowerCase().contains(_searchQuery) ||
          c.phone.contains(_searchQuery);

      if (!matchesSearch) return false;

      if (_filterStage == 'All') return true;
      if (_filterStage == 'Sale Confirmed') {
        return c.stage == 'SALE_CONFIRMED' ||
            c.stage == 'DOCUMENTS_RECEIVED' ||
            c.stage == 'ADVANCE_VERIFIED';
      }
      if (_filterStage == 'Work In Progress') {
        return c.stage == 'STRUCTURE_WORK' ||
            c.stage == 'ELECTRICAL_WORK' ||
            c.stage == 'CIVIL_WORK' ||
            c.stage == 'INSTALLATION_COMPLETE';
      }
      if (_filterStage == 'KEDL Process') {
        return c.stage == 'KEDL_PROCESS';
      }
      if (_filterStage == 'Live') {
        return c.stage == 'SYSTEM_LIVE' || c.stage == 'HANDED_OVER';
      }
      return true;
    }).toList();
  }

  void _showAddCustomerSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final kwCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navy800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
              Text('Add New Customer', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Customer Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  hintText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  hintText: 'Site Address / City',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: kwCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Solar kW',
                        prefixIcon: Icon(Icons.bolt_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Project ₹',
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  final name = nameCtrl.text.trim();
                  final phone = phoneCtrl.text.trim();
                  final address = addressCtrl.text.trim();
                  final kw = int.tryParse(kwCtrl.text.trim()) ?? 5;
                  final amount = int.tryParse(amountCtrl.text.trim()) ?? 250000;

                  if (name.isEmpty || phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter name and phone number'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  final newCustomer = _Customer(
                    id: name.replaceAll(' ', '-').toLowerCase(),
                    name: name,
                    address: address.isEmpty ? 'Delhi NCR' : address,
                    kw: kw,
                    stage: 'SALE_CONFIRMED',
                    amount: amount,
                    paid: (amount * 0.2).round(),
                    phone: phone,
                  );

                  setState(() {
                    _customers.insert(0, newCustomer);
                  });

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Customer "$name" added successfully!'),
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
                      'Create Customer Profile',
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.navy900),
                    ),
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
    final list = _filteredCustomers;

    return Scaffold(
      backgroundColor: AppColors.navy900,
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            tooltip: 'Add Customer',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.person_add_rounded,
                  color: Color(0xFF0A1628), size: 18),
            ),
            onPressed: () => _showAddCustomerSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Search by name, address, phone...',
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

          // Stage filter chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: _stages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final isSelected = _filterStage == _stages[i];
                return GestureDetector(
                  onTap: () => setState(() => _filterStage = _stages[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gold500.withValues(alpha: 0.15)
                          : AppColors.navy800,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: isSelected ? AppColors.gold500 : AppColors.navy600,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      _stages[i],
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected ? AppColors.gold400 : AppColors.grey400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 8),

          // Customer list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.gold500),
                  )
                : list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded,
                                size: 48, color: AppColors.grey600),
                            const SizedBox(height: 12),
                            Text('No customers found',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.grey500)),
                          ],
                        ),
                      )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = list[i];
                      final color = _stageColor(c.stage);
                      final progress = c.amount > 0 ? (c.paid / c.amount).clamp(0.0, 1.0) : 0.0;
                      return _CustomerCard(
                        customer: c,
                        stageColor: color,
                        stageLabel: _stageLabel(c.stage),
                        progress: progress,
                        delay: i * 70,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final _Customer customer;
  final Color stageColor;
  final String stageLabel;
  final double progress;
  final int delay;

  const _CustomerCard({
    required this.customer,
    required this.stageColor,
    required this.stageLabel,
    required this.progress,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/vendor/customers/${customer.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.navy800,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.navy600),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      customer.name[0],
                      style: AppTextStyles.headlineSmall.copyWith(color: stageColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name, style: AppTextStyles.labelLarge),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.grey500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer.address,
                              style: AppTextStyles.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: stageColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        stageLabel,
                        style: AppTextStyles.caption.copyWith(color: stageColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, size: 12, color: AppColors.gold500),
                        Text(
                          ' ${customer.kw} kW',
                          style: AppTextStyles.caption.copyWith(color: AppColors.gold400),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Payment progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${_formatAmount(customer.paid)} / ₹${_formatAmount(customer.amount)}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey300),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% paid',
                  style: AppTextStyles.caption.copyWith(
                    color: progress >= 1 ? AppColors.success : AppColors.gold400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.navy600,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1 ? AppColors.success : AppColors.gold500,
                ),
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 12),
            // Quick Call & WhatsApp bar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling ${customer.name} (+91 ${customer.phone})...'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.call_rounded, size: 13, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text('Call',
                            style: AppTextStyles.caption.copyWith(color: AppColors.success)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening WhatsApp chat with ${customer.name}...'),
                        backgroundColor: AppColors.teal500,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.teal500.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 13, color: AppColors.teal500),
                        const SizedBox(width: 4),
                        Text('Chat',
                            style: AppTextStyles.caption.copyWith(color: AppColors.teal500)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'View Details →',
                  style: AppTextStyles.caption.copyWith(color: AppColors.gold400),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 380.ms)
        .slideY(begin: 0.08, end: 0);
  }

  String _formatAmount(int amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return '$amount';
  }
}

class _Customer {
  final String id, name, address, stage, phone;
  final int kw, amount, paid;

  const _Customer({
    required this.id,
    required this.name,
    required this.address,
    required this.kw,
    required this.stage,
    required this.amount,
    required this.paid,
    required this.phone,
  });
}

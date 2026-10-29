import 'package:flutter/material.dart';
import 'package:solar_pro/core/network/api_client.dart';
import 'package:solar_pro/core/theme/app_theme.dart';
import 'package:solar_pro/features/admin/employees/models/admin_employee_model.dart';
import 'package:solar_pro/features/admin/employees/widgets/employee_task_sheet.dart';

class AdminEmployeesScreen extends StatefulWidget {
  final ApiClient? apiClient;
  final List<AdminEmployee>? initialEmployees;

  const AdminEmployeesScreen({
    super.key,
    this.apiClient,
    this.initialEmployees,
  });

  @override
  State<AdminEmployeesScreen> createState() => _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends State<AdminEmployeesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<AdminEmployee> _employees = [];
  String _selectedTrade = 'all';
  late ApiClient _client;

  final List<(String, String)> _tradeFilters = [
    ('all', 'All Staff'),
    ('sales', 'Sales'),
    ('service', 'Service & Maintenance'),
    ('structure', 'Structure'),
    ('electrical', 'Electrical'),
    ('civil', 'Civil'),
    ('kedl', 'KEDL Liaison'),
  ];

  @override
  void initState() {
    super.initState();
    _client = widget.apiClient ?? ApiClient();
    if (widget.initialEmployees != null) {
      _employees = List.from(widget.initialEmployees!);
      _isLoading = false;
    } else {
      _loadEmployees();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final rawList = await _client.getEmployees(
        trade: _selectedTrade == 'all' ? null : _selectedTrade,
      );
      if (mounted) {
        setState(() {
          _employees = rawList.map((e) => AdminEmployee.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AdminEmployee> get _filteredEmployees {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _employees;
    return _employees.where((e) {
      return e.name.toLowerCase().contains(query) ||
          e.employeeNo.toLowerCase().contains(query) ||
          e.phone.contains(query) ||
          e.role.toLowerCase().contains(query) ||
          e.team.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalStaff = _employees.length;
    final totalTasks = _employees.fold(0, (acc, e) => acc + e.taskCount);
    final displayedList = _filteredEmployees;

    return Scaffold(
      backgroundColor: AppColors.navy900,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Staff & Employees Directory',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              '$totalStaff employee${totalStaff == 1 ? '' : 's'} registered in database',
              style: const TextStyle(fontSize: 11, color: AppColors.gold400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh staff list',
            onPressed: _loadEmployees,
          ),
        ],
      ),
      body: Column(
        children: [
          // Top KPI Summary Cards Row
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: AppColors.navy800,
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Total Staff',
                    value: '$totalStaff',
                    icon: Icons.groups_rounded,
                    color: AppColors.gold500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Active On Duty',
                    value: '${_employees.where((e) => e.isActive).length}',
                    icon: Icons.verified_user_rounded,
                    color: AppColors.teal500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Allocated Tasks',
                    value: '$totalTasks',
                    icon: Icons.assignment_turned_in_rounded,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ),

          // Search and Filters Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.navy800,
              border: Border(bottom: BorderSide(color: AppColors.navy700)),
            ),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by employee name, ID, phone, role...',
                    hintStyle: const TextStyle(color: AppColors.grey500, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.grey400, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.grey400, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.navy900,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.navy600),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.navy600),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.gold500),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Horizontal Discipline Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _tradeFilters.map((tf) {
                      final isSel = _selectedTrade == tf.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            tf.$2,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? Colors.black : AppColors.grey400,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.gold500,
                          backgroundColor: AppColors.navy900,
                          side: BorderSide(
                            color: isSel ? AppColors.gold500 : AppColors.navy700,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedTrade = tf.$1);
                            _loadEmployees();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Main Employees Column / List View
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.gold500),
                  )
                : displayedList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.navy800,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.navy700),
                                ),
                                child: const Icon(
                                  Icons.people_outline_rounded,
                                  size: 44,
                                  color: AppColors.grey500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Employees Found',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchController.text.isNotEmpty
                                    ? 'No staff member matched "${_searchController.text}".'
                                    : 'No employees found under this trade filter.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.grey400,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEmployees,
                        color: AppColors.gold500,
                        backgroundColor: AppColors.navy800,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: displayedList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final emp = displayedList[index];
                            return _EmployeeListCard(
                              employee: emp,
                              onTap: () {
                                EmployeeTaskDetailSheet.show(
                                  context,
                                  employee: emp,
                                  onTasksChanged: _loadEmployees,
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.navy900,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.navy700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: color.withValues(alpha: 0.7), size: 16),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.grey400,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeListCard extends StatelessWidget {
  final AdminEmployee employee;
  final VoidCallback onTap;

  const _EmployeeListCard({
    required this.employee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.navy800,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.navy700),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: employee.roleColor.withValues(alpha: 0.15),
                child: Text(
                  employee.name.isNotEmpty
                      ? employee.name.substring(0, 1).toUpperCase()
                      : 'E',
                  style: TextStyle(
                    color: employee.roleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            employee.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.navy700,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            employee.employeeNo,
                            style: const TextStyle(
                              color: AppColors.gold400,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(employee.roleIcon, size: 12, color: employee.roleColor),
                        const SizedBox(width: 4),
                        Text(
                          employee.roleDisplayName,
                          style: TextStyle(
                            color: employee.roleColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '• ${employee.team}',
                            style: const TextStyle(
                              color: AppColors.grey400,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      employee.phone,
                      style: const TextStyle(color: AppColors.grey500, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Task Count Badge & Action Hint
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: employee.taskCount > 0
                          ? AppColors.gold500.withValues(alpha: 0.15)
                          : AppColors.navy700,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: employee.taskCount > 0
                            ? AppColors.gold500.withValues(alpha: 0.4)
                            : AppColors.navy600,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size: 11,
                          color: employee.taskCount > 0 ? AppColors.gold400 : AppColors.grey400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          employee.taskCount > 0 ? '${employee.taskCount} Tasks' : 'No tasks',
                          style: TextStyle(
                            color: employee.taskCount > 0 ? AppColors.gold400 : AppColors.grey400,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Tasks',
                        style: TextStyle(color: AppColors.grey400, fontSize: 10),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.grey400),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

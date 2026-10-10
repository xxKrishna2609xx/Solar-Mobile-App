import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_pro/core/constants/app_constants.dart';
import 'package:solar_pro/core/network/api_client.dart';
import 'package:solar_pro/core/theme/app_theme.dart';
import 'package:solar_pro/features/employee/common/employee_empty_placeholder.dart';
import 'package:solar_pro/features/employee/salesman/customers/salesman_customers_tab.dart';
import 'package:solar_pro/features/employee/salesman/home/salesman_home_tab.dart';
import 'package:solar_pro/features/employee/salesman/leads/salesman_leads_tab.dart';
import 'package:solar_pro/features/employee/salesman/payments/salesman_payments_tab.dart';
import 'package:solar_pro/features/employee/site_work/presentation/tabs/site_calendar_tab.dart';
import 'package:solar_pro/features/employee/site_work/presentation/tabs/site_home_tab.dart';
import 'package:solar_pro/features/employee/site_work/presentation/tabs/site_my_jobs_tab.dart';
import 'package:solar_pro/shared/widgets/sp_bottom_nav.dart';


enum EmployeePortalType {
  salesman,
  site,
  kedl,
  service,
}

class EmployeeShell extends StatefulWidget {
  final EmployeePortalType portalType;

  const EmployeeShell({
    super.key,
    required this.portalType,
  });

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  int _currentIndex = 0;
  String _userName = 'Employee';
  String _userPhone = '';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString(AppConstants.kUserName) ?? 'Employee';
        _userPhone = prefs.getString(AppConstants.kUserPhone) ?? '';
        _userRole = prefs.getString(AppConstants.kUserRole) ?? widget.portalType.name;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navy800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text(
          'Confirm Logout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to log out of your employee account?',
          style: TextStyle(color: AppColors.grey400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey400)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ApiClient().logout();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  List<SpNavItem> _buildNavItems() {
    switch (widget.portalType) {
      case EmployeePortalType.salesman:
        return const [
          SpNavItem(icon: Icons.dashboard_rounded, label: 'Home'),
          SpNavItem(icon: Icons.people_alt_rounded, label: 'Leads'),
          SpNavItem(icon: Icons.groups_rounded, label: 'Customers'),
          SpNavItem(icon: Icons.payments_rounded, label: 'Payments'),
          SpNavItem(icon: Icons.person_rounded, label: 'Profile'),
        ];
      case EmployeePortalType.site:
        return const [
          SpNavItem(icon: Icons.dashboard_rounded, label: 'Home'),
          SpNavItem(icon: Icons.assignment_rounded, label: 'My Jobs'),
          SpNavItem(icon: Icons.calendar_month_rounded, label: 'Calendar'),
          SpNavItem(icon: Icons.person_rounded, label: 'Profile'),
        ];
      case EmployeePortalType.kedl:
        return const [
          SpNavItem(icon: Icons.dashboard_rounded, label: 'Home'),
          SpNavItem(icon: Icons.folder_shared_rounded, label: 'Files'),
          SpNavItem(icon: Icons.receipt_long_rounded, label: 'Demands'),
          SpNavItem(icon: Icons.person_rounded, label: 'Profile'),
        ];
      case EmployeePortalType.service:
        return const [
          SpNavItem(icon: Icons.dashboard_rounded, label: 'Home'),
          SpNavItem(icon: Icons.confirmation_number_rounded, label: 'Tickets'),
          SpNavItem(icon: Icons.person_rounded, label: 'Profile'),
        ];
    }
  }

  String _getPortalTitle() {
    switch (widget.portalType) {
      case EmployeePortalType.salesman:
        return 'Sales Executive';
      case EmployeePortalType.site:
        return 'Site Operations';
      case EmployeePortalType.kedl:
        return 'KEDL Discom';
      case EmployeePortalType.service:
        return 'Service Desk';
    }
  }

  Widget _buildBody(int tabIndex) {
    // If last tab is profile
    final navItems = _buildNavItems();
    if (tabIndex == navItems.length - 1) {
      return _buildProfileTab();
    }

    switch (widget.portalType) {
      case EmployeePortalType.salesman:
        switch (tabIndex) {
          case 0:
            return SalesmanHomeTab(
              onNavigateTab: (index) => setState(() => _currentIndex = index),
            );
          case 1:
            return const SalesmanLeadsTab();

          case 2:
            return SalesmanCustomersTab(
              onNavigateTab: (index) => setState(() => _currentIndex = index),
            );
          case 3:
            return const SalesmanPaymentsTab();
        }
        break;

      case EmployeePortalType.site:
        switch (tabIndex) {
          case 0:
            return SiteHomeTab(
              onNavigateTab: (index) => setState(() => _currentIndex = index),
            );
          case 1:
            return const SiteMyJobsTab();
          case 2:
            return const SiteCalendarTab();
        }
        break;

      case EmployeePortalType.kedl:
        switch (tabIndex) {
          case 0:
            return const EmployeeEmptyPlaceholder(
              title: 'KEDL Overview',
              description: 'Discom file status counters and open demands.',
              icon: Icons.account_balance_rounded,
            );
          case 1:
            return const EmployeeEmptyPlaceholder(
              title: 'Discom Files',
              description: 'Name Change, Load Increase, and Net Metering paperwork.',
              icon: Icons.folder_shared_rounded,
            );
          case 2:
            return const EmployeeEmptyPlaceholder(
              title: 'Fee Demands',
              description: 'Track and resolve open Discom fee demands.',
              icon: Icons.receipt_long_rounded,
            );
        }
        break;

      case EmployeePortalType.service:
        switch (tabIndex) {
          case 0:
            return const EmployeeEmptyPlaceholder(
              title: 'Service Operations',
              description: 'Active ticket status overview and serial warranty lookup.',
              icon: Icons.support_agent_rounded,
            );
          case 1:
            return const EmployeeEmptyPlaceholder(
              title: 'Service Tickets',
              description: 'Manage Structure, Wiring, and Inverter issue tickets.',
              icon: Icons.confirmation_number_rounded,
            );
        }
        break;
    }

    return const EmployeeEmptyPlaceholder(
      title: 'Section Coming Soon',
      description: 'This feature will be enabled in the upcoming release.',
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.navy800,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.navy600),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.gold500.withValues(alpha: 0.2),
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'E',
                    style: const TextStyle(
                      color: AppColors.gold500,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userPhone.isNotEmpty ? _userPhone : 'Employee Profile',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.gold500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          _userRole.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.gold400,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: AppColors.navy800,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.navy600),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: AppColors.gold500),
                  title: const Text('Notifications', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.grey500),
                  onTap: () => context.push(AppRoutes.notifications),
                ),
                const Divider(height: 1, color: AppColors.navy600),
                ListTile(
                  leading: const Icon(Icons.security_rounded, color: AppColors.gold500),
                  title: const Text('Security & Session', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Tokens stored securely', style: TextStyle(color: AppColors.grey500, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.15),
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navItems = _buildNavItems();
    final safeIndex = _currentIndex.clamp(0, navItems.length - 1);

    return Scaffold(
      backgroundColor: AppColors.navy900,
      appBar: AppBar(
        backgroundColor: AppColors.navy800,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getPortalTitle(),
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),

            Text(
              'SolarPro Operations',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.grey500,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'Notifications',
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(safeIndex),
      bottomNavigationBar: SpBottomNav(
        selectedIndex: safeIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: navItems,
      ),
    );
  }
}

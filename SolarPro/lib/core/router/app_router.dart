import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_pro/core/constants/app_constants.dart';
import 'package:solar_pro/features/auth/presentation/screens/splash_screen.dart';
import 'package:solar_pro/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:solar_pro/features/auth/presentation/screens/login_screen.dart';
import 'package:solar_pro/features/auth/presentation/screens/otp_screen.dart';
import 'package:solar_pro/features/dashboard/presentation/screens/vendor_dashboard_screen.dart';
import 'package:solar_pro/features/leads/presentation/screens/leads_screen.dart';
import 'package:solar_pro/features/customers/presentation/screens/customers_screen.dart';
import 'package:solar_pro/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:solar_pro/features/payments/presentation/screens/payments_screen.dart';
import 'package:solar_pro/features/work_assignment/presentation/screens/work_assignment_screen.dart';
import 'package:solar_pro/features/kedl/presentation/screens/kedl_screen.dart';
import 'package:solar_pro/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:solar_pro/features/tickets/presentation/screens/tickets_screen.dart';
import 'package:solar_pro/features/client/presentation/screens/client_dashboard_screen.dart';
import 'package:solar_pro/features/notifications/presentation/screens/notifications_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      // ── Auth ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpScreen(phone: phone);
        },
      ),

      // ── Vendor / Admin Shell ───────────────────────────────────────────
      GoRoute(
        path: AppRoutes.vendorDash,
        builder: (context, state) => const VendorDashboardScreen(),
      ),

      // ── Dedicated Leads & Customers Screens ────────────────────────────
      GoRoute(
        path: AppRoutes.leads,
        builder: (context, state) => const LeadsScreen(),
      ),
      GoRoute(
        path: AppRoutes.customers,
        builder: (context, state) => const CustomersScreen(),
      ),

      // ── Customer detail ───────────────────────────────────────────────
      GoRoute(
        path: '/vendor/customers/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CustomerDetailScreen(customerId: id);
        },
      ),

      // ── Feature screens ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.payments,
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.workAssign,
        builder: (context, state) => const WorkAssignmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.kedl,
        builder: (context, state) => const KedlScreen(),
      ),
      GoRoute(
        path: AppRoutes.inventory,
        builder: (context, state) => const InventoryScreen(),
      ),

      // ── Client portal ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.clientDash,
        builder: (context, state) => const ClientDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.clientTickets,
        builder: (context, state) => const TicketsScreen(),
      ),

      // ── Shared ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFF5A623), size: 48),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.message ?? '',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.go(AppRoutes.vendorDash),
              child: const Text('Go to Dashboard',
                  style: TextStyle(color: Color(0xFFF5A623))),
            ),
          ],
        ),
      ),
    ),
  );
});

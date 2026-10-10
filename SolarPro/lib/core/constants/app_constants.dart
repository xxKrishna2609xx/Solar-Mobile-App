import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// App-wide constants

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'SolarPro';
  static const String appTagline = 'Powering India\'s Solar Future';
  static const String companyName = 'SolarPro Management';

  // Hosted Backend Toggle
  // Set to true to connect to the cloud backend (Render) - no local server needed!
  static const bool useHostedBackend = true;
  static const String remoteBaseUrl = 'https://solar-mobile-app.onrender.com/api/v1';
  static const String remoteLiveHost = 'https://solar-mobile-app.onrender.com';

  // API - Resolves cloud URL when useHostedBackend is true, otherwise localhost for local testing
  static String get baseUrl {
    if (useHostedBackend) return remoteBaseUrl;
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
    return 'http://localhost:8000/api/v1';
  }

  static String get liveHost {
    if (useHostedBackend) return remoteLiveHost;
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  static const int connectTimeout = 35000;
  static const int receiveTimeout = 35000;


  // Storage keys
  static const String kAccessToken   = 'access_token';
  static const String kRefreshToken  = 'refresh_token';
  static const String kUserRole      = 'user_role';
  static const String kUserId        = 'user_id';
  static const String kUserName      = 'user_name';
  static const String kUserPhone     = 'user_phone';

  // Pagination
  static const int pageSize = 20;

  // OTP
  static const int otpLength    = 6;
  static const int otpTimerSecs = 60;

  // Image constraints
  static const int maxTicketImages = 10;
  static const int minTicketImages = 2;
}

class AppRoutes {
  AppRoutes._();
  static const String splash      = '/';
  static const String onboarding  = '/onboarding';
  static const String login       = '/login';
  static const String otp         = '/otp';
  // Vendor
  static const String vendorDash  = '/vendor/dashboard';
  static const String leads       = '/vendor/leads';
  static const String leadDetail  = '/vendor/leads/:id';
  static const String customers   = '/vendor/customers';
  static const String customerDetail = '/vendor/customers/:id';
  static const String addCustomer = '/vendor/customers/add';
  static const String payments    = '/vendor/payments';
  static const String users       = '/vendor/users';
  static const String teams       = '/vendor/teams';
  static const String workAssign  = '/vendor/work-assignments';
  static const String kedl        = '/vendor/kedl';
  static const String inventory   = '/vendor/inventory';
  static const String reports     = '/vendor/reports';
  static const String adminApprovals = '/admin/approvals';
  static const String notifications = '/notifications';
  // Client
  static const String clientDash  = '/client/dashboard';
  static const String clientStatus = '/client/status';
  static const String clientPay   = '/client/payment';
  static const String clientTickets = '/client/tickets';
  static const String newTicket   = '/client/tickets/new';
  // Employee Portal
  static const String employeeSalesman = '/employee/salesman';
  static const String employeeSite     = '/employee/site';
  static const String employeeKedl     = '/employee/kedl';
  static const String employeeService  = '/employee/service';
  static const String unsupportedRole  = '/unsupported-role';
}

/// Resolves the home landing route for a given user role & optional team type
String resolveRoleHomeRoute(String? role, {String? teamType}) {
  final cleanRole = role?.trim().toLowerCase() ?? '';
  final cleanTeam = teamType?.trim().toLowerCase() ?? '';

  switch (cleanRole) {
    case 'admin':
    case 'manager':
    case 'vendor':
      return AppRoutes.vendorDash;
    case 'client':
      return AppRoutes.clientDash;
    case 'sales':
    case 'salesman':
      return AppRoutes.employeeSalesman;
    case 'kedl':
      return AppRoutes.employeeKedl;
    case 'service':
      return AppRoutes.employeeService;
    case 'electrician':
    case 'structure':
    case 'civil':
      return AppRoutes.employeeSite;
    case 'technician':
    case 'labour':
      if (cleanTeam == 'electrical' ||
          cleanTeam == 'structure' ||
          cleanTeam == 'civil') {
        return AppRoutes.employeeSite;
      }
      return AppRoutes.employeeService;
    default:
      return AppRoutes.unsupportedRole;
  }
}


class AppAssets {
  AppAssets._();
  // Images
  static const String logo         = 'assets/images/logo.png';
  static const String solarPanel   = 'assets/images/solar_panel.png';
  static const String onboard1     = 'assets/images/onboard_1.png';
  static const String onboard2     = 'assets/images/onboard_2.png';
  static const String onboard3     = 'assets/images/onboard_3.png';
  // Animations (Lottie)
  static const String loadingAnim  = 'assets/animations/loading.json';
  static const String successAnim  = 'assets/animations/success.json';
  static const String solarAnim    = 'assets/animations/solar.json';
  static const String emptyAnim    = 'assets/animations/empty.json';
}

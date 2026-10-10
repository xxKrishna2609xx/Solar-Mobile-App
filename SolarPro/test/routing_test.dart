import 'package:flutter_test/flutter_test.dart';
import 'package:solar_pro/core/constants/app_constants.dart';

void main() {
  group('Role to Home Route Resolution Matrix', () {
    test('Main Admin (admin) lands on Vendor Dashboard', () {
      expect(resolveRoleHomeRoute('admin'), AppRoutes.vendorDash);
    });

    test('Co-Admin (manager) lands on Vendor Dashboard', () {
      expect(resolveRoleHomeRoute('manager'), AppRoutes.vendorDash);
    });

    test('Salesman (sales / salesman) lands on Salesman Portal', () {
      expect(resolveRoleHomeRoute('sales'), AppRoutes.employeeSalesman);
      expect(resolveRoleHomeRoute('salesman'), AppRoutes.employeeSalesman);
    });

    test('KEDL Employee (kedl) lands on KEDL Portal', () {
      expect(resolveRoleHomeRoute('kedl'), AppRoutes.employeeKedl);
    });

    test('Electrician (electrician or labour/technician with electrical team) lands on Site Operations', () {
      expect(resolveRoleHomeRoute('electrician'), AppRoutes.employeeSite);
      expect(resolveRoleHomeRoute('technician', teamType: 'electrical'), AppRoutes.employeeSite);
      expect(resolveRoleHomeRoute('labour', teamType: 'electrical'), AppRoutes.employeeSite);
    });

    test('Structure Technician (structure or labour/technician with structure team) lands on Site Operations', () {
      expect(resolveRoleHomeRoute('structure'), AppRoutes.employeeSite);
      expect(resolveRoleHomeRoute('technician', teamType: 'structure'), AppRoutes.employeeSite);
      expect(resolveRoleHomeRoute('labour', teamType: 'structure'), AppRoutes.employeeSite);
    });

    test('Civil Technician (civil or labour/technician with civil team) lands on Site Operations', () {
      expect(resolveRoleHomeRoute('civil'), AppRoutes.employeeSite);
      expect(resolveRoleHomeRoute('technician', teamType: 'civil'), AppRoutes.employeeSite);
      expect(resolveRoleHomeRoute('labour', teamType: 'civil'), AppRoutes.employeeSite);
    });

    test('Service Technician (service or technician without site team) lands on Service Desk', () {
      expect(resolveRoleHomeRoute('service'), AppRoutes.employeeService);
      expect(resolveRoleHomeRoute('technician'), AppRoutes.employeeService);
    });

    test('Client (client) lands on Client Dashboard', () {
      expect(resolveRoleHomeRoute('client'), AppRoutes.clientDash);
    });

    test('Unknown or invalid role resolves to Unsupported Role Screen', () {
      expect(resolveRoleHomeRoute('unknown_guest'), AppRoutes.unsupportedRole);
      expect(resolveRoleHomeRoute(null), AppRoutes.unsupportedRole);
      expect(resolveRoleHomeRoute(''), AppRoutes.unsupportedRole);
    });
  });

  group('Route Isolation Invariants', () {
    test('Employee routes cannot match vendor or client roots', () {
      const employeeRoutes = [
        AppRoutes.employeeSalesman,
        AppRoutes.employeeSite,
        AppRoutes.employeeKedl,
        AppRoutes.employeeService,
      ];

      for (final route in employeeRoutes) {
        expect(route.startsWith('/vendor'), isFalse);
        expect(route.startsWith('/client'), isFalse);
        expect(route.startsWith('/employee'), isTrue);
      }
    });

    test('Vendor routes cannot match employee or client roots', () {
      const vendorRoutes = [
        AppRoutes.vendorDash,
        AppRoutes.leads,
        AppRoutes.customers,
        AppRoutes.payments,
        AppRoutes.inventory,
      ];

      for (final route in vendorRoutes) {
        expect(route.startsWith('/employee'), isFalse);
        expect(route.startsWith('/client'), isFalse);
      }
    });

    test('Client routes cannot match employee or vendor roots', () {
      const clientRoutes = [
        AppRoutes.clientDash,
        AppRoutes.clientStatus,
        AppRoutes.clientPay,
        AppRoutes.clientTickets,
      ];

      for (final route in clientRoutes) {
        expect(route.startsWith('/employee'), isFalse);
        expect(route.startsWith('/vendor'), isFalse);
      }
    });
  });
}

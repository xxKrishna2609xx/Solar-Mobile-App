import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_pro/features/employee/service/presentation/widgets/service_ticket_card.dart';
import 'package:solar_pro/features/tickets/data/models/ticket_model.dart';

void main() {
  testWidgets('Test rendering ServiceTicketCard with real backend JSON', (WidgetTester tester) async {
    final backendJson = {
      "_id": "tck_1001",
      "assigned_staff": "Vikram Singh",
      "assigned_staff_emp_no": "EMP-SRV-104",
      "assigned_to": "emp-srv-104",
      "comments": [
        {
          "id": "cmt_01",
          "author_name": "Sunil Verma",
          "author_role": "client",
          "message": "Please send a service technician urgently, solar export halted.",
          "created_at": "2026-10-14T14:41:49.902108+00:00"
        },
        {
          "id": "cmt_02",
          "author_name": "Vikram Singh",
          "author_role": "technician",
          "message": "Technician dispatched to inspect AC voltage tapping and grid tolerance.",
          "created_at": "2026-10-14T16:41:49.902108+00:00"
        }
      ],
      "created_at": "2026-10-14T13:41:49.902000",
      "customer_address": "Plot 42, Malviya Nagar, Jaipur, Rajasthan",
      "customer_id": "cust_101",
      "customer_name": "Sunil Verma",
      "customer_phone": "9829011223",
      "description": "Growatt inverter display shows blinking warning LED and stopped exporting power.",
      "error_code": "E-029: Grid Overvoltage",
      "id": "tck_1001",
      "images": [
        "inverter_error_display.jpg"
      ],
      "priority": "urgent",
      "status": "in_progress",
      "ticket_no": "TCK-2026-1001",
      "title": "Inverter blinking red with error code",
      "type": "inverter",
      "updated_at": "2026-10-14T16:41:49.902000"
    };

    final ticket = TicketModel.fromJson(backendJson);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ServiceTicketCard(
              ticket: ticket,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('TCK-2026-1001'), findsOneWidget);
    expect(find.text('Sunil Verma'), findsOneWidget);
    print('ServiceTicketCard rendered successfully!');
  });
}

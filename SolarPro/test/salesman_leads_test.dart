import 'package:flutter_test/flutter_test.dart';
import 'package:solar_pro/features/leads/data/models/lead_model.dart';

void main() {
  group('LeadModel Unit Tests', () {
    test('JSON serialization & deserialization', () {
      final now = DateTime.now();
      final json = {
        'id': 'lead-123',
        'name': 'Rajesh Sharma',
        'phone': '9876543210',
        'address': 'Sector 15, Jaipur',
        'expected_kw': 5.5,
        'source': 'Self: Personal Reference',
        'status': 'follow_up',
        'assigned_sales_id': 'sales-001',
        'follow_up_date': now.toIso8601String(),
        'notes': 'Call on Sunday afternoon',
        'lost_reason': null,
      };

      final lead = LeadModel.fromJson(json);

      expect(lead.id, 'lead-123');
      expect(lead.name, 'Rajesh Sharma');
      expect(lead.phone, '9876543210');
      expect(lead.address, 'Sector 15, Jaipur');
      expect(lead.expectedKw, 5.5);
      expect(lead.source, 'Self: Personal Reference');
      expect(lead.status, 'follow_up');
      expect(lead.assignedSalesId, 'sales-001');
      expect(lead.notes, 'Call on Sunday afternoon');
      expect(lead.lostReason, isNull);
    });

    test('UI Status Label Mapping (Owner specification: Follow-up, Closed, Returned)', () {
      final leadNew = LeadModel(id: '1', name: 'A', phone: '1', status: 'new');
      final leadContacted = LeadModel(id: '2', name: 'B', phone: '2', status: 'contacted');
      final leadFollowUp = LeadModel(id: '3', name: 'C', phone: '3', status: 'follow_up');
      final leadConverted = LeadModel(id: '4', name: 'D', phone: '4', status: 'converted');
      final leadLost = LeadModel(id: '5', name: 'E', phone: '5', status: 'lost');

      expect(leadNew.uiStatusLabel, 'New');
      expect(leadContacted.uiStatusLabel, 'Contacted');
      expect(leadFollowUp.uiStatusLabel, 'Follow-up');
      expect(leadConverted.uiStatusLabel, 'Closed'); // Prompt 3 requirement
      expect(leadLost.uiStatusLabel, 'Returned');   // Prompt 3 requirement
    });

    test('Follow-up Today and Overdue calculations', () {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day, 14, 30);
      final tomorrowDate = now.add(const Duration(days: 1));
      final yesterdayDate = now.subtract(const Duration(days: 1));

      final todayLead = LeadModel(
        id: '1',
        name: 'Today Lead',
        phone: '1',
        status: 'follow_up',
        followUpDate: todayDate,
      );

      final futureLead = LeadModel(
        id: '2',
        name: 'Future Lead',
        phone: '2',
        status: 'follow_up',
        followUpDate: tomorrowDate,
      );

      final overdueLead = LeadModel(
        id: '3',
        name: 'Overdue Lead',
        phone: '3',
        status: 'follow_up',
        followUpDate: yesterdayDate,
      );

      expect(todayLead.isFollowUpToday, isTrue);
      expect(todayLead.isFollowUpOverdue, isFalse);

      expect(futureLead.isFollowUpToday, isFalse);
      expect(futureLead.isFollowUpOverdue, isFalse);

      expect(overdueLead.isFollowUpToday, isFalse);
      expect(overdueLead.isFollowUpOverdue, isTrue);
    });

    test('Source Tagging: Added by me vs Assigned by Admin', () {
      const myUserId = 'user-sales-789';

      final selfAddedLead = LeadModel(
        id: '1',
        name: 'Self Prospect',
        phone: '1',
        status: 'new',
        source: 'Self: Newspaper Ad',
        assignedSalesId: myUserId,
      );

      final adminAssignedLead = LeadModel(
        id: '2',
        name: 'Campaign Prospect',
        phone: '2',
        status: 'new',
        source: 'Meta Ads Campaign',
        assignedSalesId: myUserId,
      );

      expect(selfAddedLead.sourceLabel(myUserId), 'Added by me');
      expect(adminAssignedLead.sourceLabel(myUserId), 'Assigned by Admin');
    });
  });
}

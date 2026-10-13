import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_pro/core/network/api_client.dart';
import 'package:solar_pro/features/client/data/models/client_dashboard_model.dart';

class ClientRepository {
  final ApiClient _apiClient;

  ClientRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // In-memory / cached fallback state for seamless offline & demo experience
  static final List<ClientPaymentRecord> _cachedPayments = [
    ClientPaymentRecord(
      id: 'pay-001',
      stageNo: 1,
      stageName: 'Token Advance (Booking Confirmed)',
      amount: 25000.0,
      mode: 'UPI',
      referenceNo: 'UPI/4891238910',
      paidOn: DateTime.now().subtract(const Duration(days: 12)),
      proofUrl: 'assets/images/receipt_sample.png',
      status: 'verified',
      salesApprovedBy: 'Rajesh Sharma',
      salesApproverEmpNo: 'EMP-SLS-042',
      verifiedBy: 'Accounts Admin',
      remarks: 'Booking token payment received and verified',
    ),
    ClientPaymentRecord(
      id: 'pay-002',
      stageNo: 2,
      stageName: 'Structure Work Advance (Milestone 2)',
      amount: 50000.0,
      mode: 'IMPS',
      referenceNo: 'IMPS/9812481023',
      paidOn: DateTime.now().subtract(const Duration(days: 4)),
      proofUrl: 'assets/images/receipt_sample.png',
      status: 'sales_approved',
      salesApprovedBy: 'Rajesh Sharma',
      salesApproverEmpNo: 'EMP-SLS-042',
      remarks: 'Payment proof verified by Salesman Rajesh Sharma. Pending Admin verification.',
    ),
  ];

  static final List<ClientTicketRecord> _cachedTickets = [
    ClientTicketRecord(
      id: 'tic-001',
      ticketNo: 'TIC-892104',
      type: ClientTicketType.structure,
      title: 'Mounting Bracket Vibration on West Roof Panel',
      description: 'The aluminum mounting bracket on the southwest frame makes a rattling noise during high winds. 3 photos attached showing foundation anchor and bracket.',
      status: 'in_progress',
      priority: 'high',
      images: ['photo1.jpg', 'photo2.jpg', 'photo3.jpg'],
      assignedStaff: 'Vikram Singh',
      assignedStaffEmpNo: 'EMP-SRV-104',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ClientTicketRecord(
      id: 'tic-002',
      ticketNo: 'TIC-842109',
      type: ClientTicketType.inverter,
      title: 'Inverter Error Code E04 Grid Voltage High',
      description: 'The inverter tripped at 1:30 PM displaying error code E04 (Grid Overvoltage). Solar generation halted.',
      errorCode: 'E04 - Grid Voltage High',
      status: 'open',
      priority: 'high',
      images: ['inverter_display.jpg'],
      assignedStaff: 'Rajesh Sharma',
      assignedStaffEmpNo: 'EMP-SLS-042',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  /// Fetch 10-stage milestones, assigned employee with Employee No, specs, and financials
  Future<Map<String, dynamic>> getClientHomeData() async {
    try {
      final res = await _apiClient.dio.get('/client/home');
      if (res.data != null && res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }
    } catch (_) {
      // Fallback to offline / demo data
    }

    final prefs = await SharedPreferences.getInstance();
    final clientName = prefs.getString('user_name') ?? 'Aryan Jadaun';
    final clientPhone = prefs.getString('user_phone') ?? '+91 98765 00001';

    return {
      'customer': {
        'name': clientName,
        'mobile': clientPhone,
        'address': 'Plot 42, Sunrise Enclave, Sector 14, Jaipur, Rajasthan',
        'capacity_kw': 5.5,
        'final_price': 25000000, // 2,50,000 in paise
        'stage': 'STRUCTURE_WORK',
      },
      'stage': 'STRUCTURE_WORK',
      'timeline': [
        {'stage': 'SALE_CONFIRMED', 'title': 'Sale Confirmed', 'status': 'done', 'date': DateTime.now().subtract(const Duration(days: 14)).toIso8601String(), 'note': 'Sales agreement signed and advance token verified.'},
        {'stage': 'DOCUMENTS_RECEIVED', 'title': 'Documents Received', 'status': 'done', 'date': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(), 'note': 'Aadhaar, Electricity Bill and rooftop pictures verified.'},
        {'stage': 'ADVANCE_VERIFIED', 'title': 'Advance Verified', 'status': 'done', 'date': DateTime.now().subtract(const Duration(days: 8)).toIso8601String(), 'note': 'Payment approved by salesman & verified by admin.'},
        {'stage': 'STRUCTURE_WORK', 'title': 'Structure Work', 'status': 'current', 'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(), 'note': 'Hot-dip galvanized mounting structure installation ongoing.'},
        {'stage': 'ELECTRICAL_WORK', 'title': 'Electrical Work', 'status': 'upcoming', 'note': 'DC cabling, conduits and earthing connection.'},
        {'stage': 'CIVIL_WORK', 'title': 'Civil Work', 'status': 'upcoming', 'note': 'Grouting and rooftop water-proofing inspection.'},
        {'stage': 'INSTALLATION_COMPLETE', 'title': 'Installation Done', 'status': 'upcoming', 'note': 'Solar panels and inverter physically mounted.'},
        {'stage': 'KEDL_PROCESS', 'title': 'KEDL Process', 'status': 'upcoming', 'note': 'Discom paperwork and inspection liaison.'},
        {'stage': 'NET_METER_INSTALLED', 'title': 'Net Meter Installed', 'status': 'upcoming', 'note': 'Bi-directional net meter sync with grid.'},
        {'stage': 'HANDED_OVER', 'title': 'Handed Over 🎉', 'status': 'upcoming', 'note': 'Project handed over with 25-year solar warranty kit.'},
      ],
      'responsible_contact': {
        'name': 'Rajesh Sharma',
        'phone': '+91 98290 12345',
        'role_title': 'Senior Sales Representative',
        'employee_no': 'EMP-SLS-042',
        'email': 'rajesh.sharma@solarpro.in',
      },
      'sales_contact': {
        'name': 'Rajesh Sharma',
        'phone': '+91 98290 12345',
        'role_title': 'Sales Executive',
        'employee_no': 'EMP-SLS-042',
        'email': 'rajesh.sharma@solarpro.in',
      },
      'payment_summary': {
        'total_amount': 250000.0,
        'total_paid': 75000.0,
        'remaining_balance': 175000.0,
        'next_milestone': 'Structure Work Completion (₹50,000)',
      },
      'system_specs': {
        'capacity_kw': 5.5,
        'phase': 'Three Phase',
        'panel_brand': 'Tata Power Solar / Waaree Bifacial',
        'panel_watt': 550,
        'panel_count': 10,
        'inverter_brand': 'Growatt 6kW Hybrid Inverter',
        'structure_type': 'High-Rise Heavy Duty Galvanized Structure',
      },
    };
  }

  /// Get list of submitted payments with their salesman approval & admin verification status
  Future<List<ClientPaymentRecord>> getPayments() async {
    try {
      final res = await _apiClient.dio.get('/client/payments');
      if (res.data is List) {
        final list = (res.data as List).map((e) => ClientPaymentRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return List.from(_cachedPayments);
  }

  /// Client submits a new payment record with photo receipt proof
  Future<ClientPaymentRecord> submitPayment({
    required double amountRupees,
    required String mode,
    String? referenceNo,
    String? remarks,
    String? proofFileName,
    String? photoBase64,
  }) async {
    final amountPaise = (amountRupees * 100).toInt();

    try {
      final formData = FormData.fromMap({
        'amount': amountPaise,
        'mode': mode.toLowerCase(),
        if (referenceNo != null) 'reference_no': referenceNo,
        if (remarks != null) 'remarks': remarks,
      });

      final res = await _apiClient.dio.post('/client/payments', data: formData);
      if (res.data is Map) {
        final newRecord = ClientPaymentRecord.fromJson(Map<String, dynamic>.from(res.data as Map));
        _cachedPayments.insert(0, newRecord);
        return newRecord;
      }
    } catch (_) {}

    // Offline / Demo submission fallback
    final newRecord = ClientPaymentRecord(
      id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
      stageNo: _cachedPayments.length + 1,
      stageName: 'Rooftop Solar Milestone Payment',
      amount: amountRupees,
      mode: mode.toUpperCase(),
      referenceNo: referenceNo ?? 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      paidOn: DateTime.now(),
      proofUrl: proofFileName ?? 'receipt_uploaded.png',
      status: 'pending', // Directly starts in Awaiting Salesman Approval
      salesApprovedBy: null,
      salesApproverEmpNo: null,
      remarks: remarks ?? 'Submitted by customer with photo receipt for salesman approval.',
    );

    _cachedPayments.insert(0, newRecord);
    return newRecord;
  }

  /// Get all service tickets
  Future<List<ClientTicketRecord>> getTickets() async {
    try {
      final res = await _apiClient.dio.get('/client/tickets');
      if (res.data is List) {
        final list = (res.data as List).map((e) => ClientTicketRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return List.from(_cachedTickets);
  }

  /// Raise a service ticket (enforcing Structure 2-10 photos, Wiring photos, Inverter Fault)
  Future<ClientTicketRecord> createTicket({
    required ClientTicketType type,
    required String title,
    required String description,
    String? errorCode,
    String priority = 'high',
    required List<String> images,
  }) async {
    // Validate image constraints according to user handwritten notes
    if (type == ClientTicketType.structure && (images.length < 2 || images.length > 10)) {
      throw Exception('Structure issue requires between 2 and 10 photos of the structure.');
    }
    if (type == ClientTicketType.wiring && (images.isEmpty || images.length > 10)) {
      throw Exception('Wiring issue requires at least 1 photo (up to 10 photos).');
    }

    try {
      final payload = {
        'type': type.name,
        'title': title.trim(),
        'description': description.trim(),
        if (errorCode != null && errorCode.isNotEmpty) 'error_code': errorCode.trim(),
        'priority': priority.toLowerCase(),
        'image_keys': images,
      };

      final res = await _apiClient.dio.post('/client/tickets', data: payload);
      if (res.data is Map) {
        final item = ClientTicketRecord.fromJson(Map<String, dynamic>.from(res.data as Map));
        _cachedTickets.insert(0, item);
        return item;
      }
    } catch (e) {
      if (e is! DioException) {
        // Validation exceptions should propagate
        rethrow;
      }
    }

    // Local / Offline addition
    final newTicket = ClientTicketRecord(
      id: 'tic-${DateTime.now().millisecondsSinceEpoch}',
      ticketNo: 'TIC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      type: type,
      title: title.trim(),
      description: description.trim(),
      errorCode: errorCode,
      status: 'open',
      priority: priority,
      images: images,
      assignedStaff: 'Rajesh Sharma',
      assignedStaffEmpNo: 'EMP-SLS-042',
      createdAt: DateTime.now(),
    );

    _cachedTickets.insert(0, newTicket);
    return newTicket;
  }
}

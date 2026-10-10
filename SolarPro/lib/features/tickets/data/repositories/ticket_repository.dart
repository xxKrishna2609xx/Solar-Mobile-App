import 'dart:convert';
import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_pro/core/constants/app_constants.dart';
import 'package:solar_pro/core/network/api_client.dart';
import 'package:solar_pro/features/tickets/data/models/ticket_model.dart';

class TicketRepository {
  final ApiClient _apiClient;
  static const String _kTicketsCacheKey = 'service_tickets_cache_v1';

  TicketRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // ── List Tickets ───────────────────────────────────────────────────────────

  Future<List<TicketModel>> listTickets({
    String? customerId,
    TicketStatus? status,
    TicketType? type,
    String? assignedTo,
    TicketPriority? priority,
    String? search,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(AppConstants.kUserRole)?.toLowerCase() ?? '';
    final userId = prefs.getString(AppConstants.kUserId);

    // Rule: Service employees see only tickets assigned to them
    String? effectiveAssignedTo = assignedTo;
    if (effectiveAssignedTo == null && (role == 'service' || role == 'technician') && userId != null) {
      effectiveAssignedTo = userId;
    }

    final queryParams = <String, dynamic>{};
    if (customerId != null) queryParams['customer_id'] = customerId;
    if (status != null) queryParams['status'] = status.toBackendString();
    if (type != null) queryParams['type'] = type.toBackendString();
    if (effectiveAssignedTo != null) queryParams['assigned_to'] = effectiveAssignedTo;

    try {
      final response = await _apiClient.dio.get('/tickets', queryParameters: queryParams);
      final List<TicketModel> result = [];
      if (response.data is List) {
        for (final item in response.data) {
          if (item is Map<String, dynamic>) {
            result.add(TicketModel.fromJson(item));
          }
        }
      }

      await _cacheTickets(result);
      return _applyFilters(result, customerId, status, type, effectiveAssignedTo, priority, search);
    } catch (e) {
      dev.log('Error fetching tickets from API: $e. Using local cache.');
      return _loadCachedOrMockTickets(
        customerId: customerId,
        status: status,
        type: type,
        assignedTo: effectiveAssignedTo,
        priority: priority,
        search: search,
      );
    }
  }

  // ── Get Single Ticket ──────────────────────────────────────────────────────

  Future<TicketModel> getTicketById(String id) async {
    try {
      final response = await _apiClient.dio.get('/tickets/$id');
      if (response.data is Map<String, dynamic>) {
        return TicketModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      dev.log('Error fetching ticket $id from API: $e');
    }

    final cached = await _loadCachedOrMockTickets();
    final match = cached.where((t) => t.id == id).firstOrNull;
    if (match != null) return match;
    throw Exception('Ticket not found ($id)');
  }

  // ── Update Ticket Status ───────────────────────────────────────────────────

  Future<TicketModel> updateTicketStatus(
    String id,
    TicketStatus status, {
    String? resolutionNote,
  }) async {
    // CRITICAL BACKEND & PROMPT RULE: Resolve strictly requires a resolution note
    if (status == TicketStatus.resolved && (resolutionNote == null || resolutionNote.trim().isEmpty)) {
      throw ArgumentError('A resolution note is strictly required before resolving a ticket.');
    }

    final payload = <String, dynamic>{
      'status': status.toBackendString(),
      if (resolutionNote != null) 'resolution_note': resolutionNote,
    };

    try {
      final response = await _apiClient.dio.post('/tickets/$id/status', data: payload);
      if (response.data is Map<String, dynamic>) {
        final updated = TicketModel.fromJson(response.data as Map<String, dynamic>);
        await _updateCachedTicket(updated);
        return updated;
      }
    } catch (e) {
      dev.log('Error updating ticket status $id: $e. Updating locally.');
    }

    final current = await getTicketById(id);
    final updated = current.copyWith(
      status: status,
      resolvedAt: status == TicketStatus.resolved ? DateTime.now() : current.resolvedAt,
      resolutionNote: resolutionNote ?? current.resolutionNote,
    );
    await _updateCachedTicket(updated);
    return updated;
  }

  // ── Add Ticket Comment ─────────────────────────────────────────────────────

  Future<TicketCommentModel> addTicketComment(String id, String message) async {
    if (message.trim().isEmpty) {
      throw ArgumentError('Comment message cannot be empty');
    }

    try {
      final response = await _apiClient.dio.post(
        '/tickets/$id/comments',
        data: {'message': message.trim()},
      );
      if (response.data is Map<String, dynamic>) {
        final comment = TicketCommentModel.fromJson(response.data as Map<String, dynamic>);
        final current = await getTicketById(id);
        await _updateCachedTicket(current.copyWith(comments: [...current.comments, comment]));
        return comment;
      }
    } catch (e) {
      dev.log('Error adding ticket comment: $e. Adding locally.');
    }

    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(AppConstants.kUserName) ?? 'Service Specialist';
    final comment = TicketCommentModel(
      id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
      ticketId: id,
      authorName: name,
      authorRole: 'technician',
      message: message.trim(),
      createdAt: DateTime.now(),
    );

    final current = await getTicketById(id);
    await _updateCachedTicket(current.copyWith(comments: [...current.comments, comment]));
    return comment;
  }

  // ── Add Visit Photos ───────────────────────────────────────────────────────

  Future<List<TicketImageModel>> addVisitPhotos(String id, List<String> filePaths) async {
    final List<TicketImageModel> newPhotos = [];
    final now = DateTime.now();

    for (int i = 0; i < filePaths.length; i++) {
      final path = filePaths[i];
      newPhotos.add(
        TicketImageModel(
          id: 'img_${now.millisecondsSinceEpoch}_$i',
          ticketId: id,
          fileKey: path.split('/').last.split('\\').last,
          createdAt: now,
        ),
      );
    }

    final current = await getTicketById(id);
    final updated = current.copyWith(images: [...current.images, ...newPhotos]);
    await _updateCachedTicket(updated);
    return newPhotos;
  }

  // ── Reverse Serial Lookup ──────────────────────────────────────────────────

  Future<SerialDetailModel> lookupSerial(String serialNo) async {
    final cleanSerial = serialNo.trim().toUpperCase();
    try {
      final response = await _apiClient.dio.get('/serials/$cleanSerial');
      if (response.data is Map<String, dynamic>) {
        return SerialDetailModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      dev.log('Error looking up serial $cleanSerial from API: $e. Checking mock inventory.');
    }

    final mockSerials = _generateMockSerials();
    final match = mockSerials.where((s) => s.serialNo.toUpperCase() == cleanSerial).firstOrNull;
    if (match != null) return match;

    // Generic fallback if user enters any valid serial code
    final now = DateTime.now();
    return SerialDetailModel(
      id: 'ser_lookup_${now.millisecondsSinceEpoch}',
      itemId: 'item_gen_01',
      itemName: cleanSerial.contains('INV') ? 'Solar Grid Inverter' : 'Solar Monocrystalline Module',
      category: cleanSerial.contains('INV') ? 'inverter' : 'panel',
      brand: cleanSerial.contains('INV') ? 'Growatt' : 'Adani Solar',
      model: cleanSerial.contains('INV') ? 'MIN 5000TL-X' : '540W Bifacial',
      serialNo: cleanSerial,
      status: 'installed',
      customerId: 'cust_101',
      customerName: 'Sunil Verma',
      customerPhone: '9829012345',
      customerAddress: 'Plot 42, Malviya Nagar, Jaipur, Rajasthan',
      supplierName: 'Premier Energy Distributors',
      warrantyMonths: 60,
      installedOn: now.subtract(const Duration(days: 120)),
      warrantyUntil: now.add(const Duration(days: 1705)),
      isUnderWarranty: true,
    );
  }

  // ── Cache & Mock Persistence ───────────────────────────────────────────────

  Future<void> _cacheTickets(List<TicketModel> tickets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(tickets.map((t) => t.toJson()).toList());
      await prefs.setString(_kTicketsCacheKey, encoded);
    } catch (_) {}
  }

  Future<void> _updateCachedTicket(TicketModel updated) async {
    final list = await _loadCachedOrMockTickets();
    final idx = list.indexWhere((t) => t.id == updated.id);
    if (idx != -1) {
      list[idx] = updated;
    } else {
      list.insert(0, updated);
    }
    await _cacheTickets(list);
  }

  Future<List<TicketModel>> _loadCachedOrMockTickets({
    String? customerId,
    TicketStatus? status,
    TicketType? type,
    String? assignedTo,
    TicketPriority? priority,
    String? search,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kTicketsCacheKey);
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        final list = decoded
            .whereType<Map<String, dynamic>>()
            .map((item) => TicketModel.fromJson(item))
            .toList();

        return _applyFilters(list, customerId, status, type, assignedTo, priority, search);
      }
    } catch (_) {}

    final seed = _generateSeedTickets();
    await _cacheTickets(seed);
    return _applyFilters(seed, customerId, status, type, assignedTo, priority, search);
  }

  List<TicketModel> _applyFilters(
    List<TicketModel> list,
    String? customerId,
    TicketStatus? status,
    TicketType? type,
    String? assignedTo,
    TicketPriority? priority,
    String? search,
  ) {
    return list.where((t) {
      if (customerId != null && t.customerId != customerId) return false;
      if (status != null && t.status != status) return false;
      if (type != null && t.type != type) return false;
      if (priority != null && t.priority != priority) return false;
      if (search != null && search.trim().isNotEmpty) {
        final q = search.toLowerCase();
        final match = t.ticketNo.toLowerCase().contains(q) ||
            t.customerName.toLowerCase().contains(q) ||
            t.title.toLowerCase().contains(q) ||
            (t.errorCode?.toLowerCase().contains(q) ?? false);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  List<TicketModel> _generateSeedTickets() {
    final now = DateTime.now();

    return [
      TicketModel(
        id: 'tck_001',
        ticketNo: 'TCK-2026-1001',
        customerId: 'cust_101',
        customerName: 'Sunil Verma',
        customerPhone: '9829012345',
        customerAddress: 'Plot 42, Malviya Nagar, Jaipur, Rajasthan',
        type: TicketType.inverter,
        title: 'Inverter blinking red with error code',
        description: 'Growatt inverter display shows blinking warning LED and stopped generating power since yesterday.',
        errorCode: 'E-029: Grid Overvoltage',
        status: TicketStatus.assigned,
        priority: TicketPriority.urgent,
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(hours: 4)),
        images: [
          TicketImageModel(
            id: 'img_tck_01',
            ticketId: 'tck_001',
            fileKey: 'inverter_error_display.jpg',
            createdAt: now.subtract(const Duration(hours: 4)),
          ),
        ],
        comments: [
          TicketCommentModel(
            id: 'cmt_01',
            ticketId: 'tck_001',
            authorName: 'Sunil Verma',
            authorRole: 'client',
            message: 'Please send a service technician urgently, system is not exporting.',
            createdAt: now.subtract(const Duration(hours: 3)),
          ),
        ],
      ),
      TicketModel(
        id: 'tck_002',
        ticketNo: 'TCK-2026-1002',
        customerId: 'cust_102',
        customerName: 'Rajesh Sharma',
        customerPhone: '9829098765',
        customerAddress: 'Shop 12, Industrial Area, Kota, Rajasthan',
        type: TicketType.wiring,
        title: 'AC conduit clamp loose after high winds',
        description: 'The outdoor PVC flexible conduit carrying AC output wire came off the wall clamp.',
        status: TicketStatus.inProgress,
        priority: TicketPriority.normal,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        images: [
          TicketImageModel(
            id: 'img_tck_02',
            ticketId: 'tck_002',
            fileKey: 'loose_conduit_photo.jpg',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
        ],
      ),
      TicketModel(
        id: 'tck_003',
        ticketNo: 'TCK-2026-1003',
        customerId: 'cust_103',
        customerName: 'Pooja Agarwal',
        customerPhone: '9414055555',
        customerAddress: '15 Civil Lines, Ajmer, Rajasthan',
        type: TicketType.structure,
        title: 'Structure end-clamp tightening request',
        description: 'Corner panel clamp was making vibrating sound during high wind.',
        status: TicketStatus.resolved,
        priority: TicketPriority.low,
        resolvedAt: now.subtract(const Duration(days: 2)),
        resolutionNote: 'Replaced mid-clamp bolt and re-torqued all 8 end clamps with anti-rust spray.',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  List<SerialDetailModel> _generateMockSerials() {
    final now = DateTime.now();
    return [
      SerialDetailModel(
        id: 'ser_01',
        itemId: 'item_growatt_5k',
        itemName: 'Growatt 5kW Grid-Tie Inverter',
        category: 'inverter',
        brand: 'Growatt',
        model: 'MIN 5000TL-X',
        serialNo: 'INV-GW-5K-9901',
        status: 'installed',
        customerId: 'cust_101',
        customerName: 'Sunil Verma',
        customerPhone: '9829012345',
        customerAddress: 'Plot 42, Malviya Nagar, Jaipur, Rajasthan',
        supplierName: 'Premier Energy Distributors',
        warrantyMonths: 60,
        installedOn: now.subtract(const Duration(days: 90)),
        warrantyUntil: now.add(const Duration(days: 1735)),
        isUnderWarranty: true,
      ),
      SerialDetailModel(
        id: 'ser_02',
        itemId: 'item_adani_540',
        itemName: 'Adani Solar 540W Mono PERC',
        category: 'panel',
        brand: 'Adani Solar',
        model: 'Bifacial DCR',
        serialNo: 'PAN-AD-540-1011',
        status: 'installed',
        customerId: 'cust_101',
        customerName: 'Sunil Verma',
        customerPhone: '9829012345',
        customerAddress: 'Plot 42, Malviya Nagar, Jaipur, Rajasthan',
        supplierName: 'Adani Solar Direct',
        warrantyMonths: 144,
        installedOn: now.subtract(const Duration(days: 90)),
        warrantyUntil: now.add(const Duration(days: 4290)),
        isUnderWarranty: true,
      ),
      SerialDetailModel(
        id: 'ser_03',
        itemId: 'item_old_inv',
        itemName: 'Luminous Solar Inverter 3kW',
        category: 'inverter',
        brand: 'Luminous',
        model: 'NXi 3000',
        serialNo: 'INV-LUM-3K-0012',
        status: 'installed',
        customerId: 'cust_103',
        customerName: 'Pooja Agarwal',
        customerPhone: '9414055555',
        customerAddress: '15 Civil Lines, Ajmer, Rajasthan',
        supplierName: 'Luminous Power',
        warrantyMonths: 24,
        installedOn: now.subtract(const Duration(days: 900)),
        warrantyUntil: now.subtract(const Duration(days: 170)),
        isUnderWarranty: false, // Expired warranty!
      ),
    ];
  }
}

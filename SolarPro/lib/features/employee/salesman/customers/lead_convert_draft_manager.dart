import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// State representation of a lead conversion draft stored locally.
class LeadConvertDraft {
  final String leadId;
  final int currentStep;

  // Step 1: Customer Info
  final String name;
  final String phone;
  final String address;
  final double? latitude;
  final double? longitude;
  final int finalPriceRupees;

  // Step 2: Subsidy & Panels
  final bool isSubsidy;
  final String panelBrand;
  final int panelWatt;
  final int panelCount;

  // Step 3: Inverter & Structure (with backend-gap fields)
  final String inverterBrand;
  final int inverterCount;
  final double inverterCapacity;
  final String phase; // "single" or "three"
  final String structureBrand;
  final int structureCount;
  final String structureHeight;

  // Step 4: Wiring & Protection (with backend-gap fields)
  final String acWireBrand;
  final String acWireSize;
  final String dcWireBrand;
  final String dcWireSize;
  final String earthingWireBrand;
  final String earthingWireSize;
  final String spdAcBrand;
  final String spdAcDetails;
  final String spdDcBrand;
  final String spdDcDetails;
  final String solarMeterBrand;
  final int solarMeterCount;

  // Step 5: Extra Work (with backend-gap fields)
  final String civilWork;
  final String earthingNotes;

  // Step 6: Document attachment metadata (docType -> fileName)
  final Map<String, String> attachedDocs;

  const LeadConvertDraft({
    required this.leadId,
    this.currentStep = 0,
    this.name = '',
    this.phone = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.finalPriceRupees = 0,
    this.isSubsidy = true,
    this.panelBrand = '',
    this.panelWatt = 540,
    this.panelCount = 6,
    this.inverterBrand = '',
    this.inverterCount = 1,
    this.inverterCapacity = 3.3,
    this.phase = 'single',
    this.structureBrand = '',
    this.structureCount = 1,
    this.structureHeight = 'High Rise (8-10 ft)',
    this.acWireBrand = 'Polycab',
    this.acWireSize = '4 sq mm',
    this.dcWireBrand = 'Siechem',
    this.dcWireSize = '4 sq mm',
    this.earthingWireBrand = 'Copper',
    this.earthingWireSize = '10 sq mm',
    this.spdAcBrand = 'Schneider Electric',
    this.spdAcDetails = 'Type 2 AC SPD 40kA',
    this.spdDcBrand = 'Havells',
    this.spdDcDetails = '1000V DC SPD 40kA',
    this.solarMeterBrand = 'Secure Meters',
    this.solarMeterCount = 1,
    this.civilWork = '',
    this.earthingNotes = '',
    this.attachedDocs = const {},
  });

  /// Price in paise (Rupees * 100)
  int get finalPricePaise => finalPriceRupees * 100;

  /// Total solar kW = watt * count / 1000
  double get totalCapacityKw => (panelWatt * panelCount) / 1000.0;

  /// Panel type label per prompt rule:
  /// "Switching Subsidy/Non-subsidy changes the panel type label (DCR/NDCR)."
  String get panelTypeLabel => isSubsidy ? 'DCR Panels' : 'NDCR Panels';

  Map<String, dynamic> toJson() {
    return {
      'leadId': leadId,
      'currentStep': currentStep,
      'name': name,
      'phone': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'finalPriceRupees': finalPriceRupees,
      'isSubsidy': isSubsidy,
      'panelBrand': panelBrand,
      'panelWatt': panelWatt,
      'panelCount': panelCount,
      'inverterBrand': inverterBrand,
      'inverterCount': inverterCount,
      'inverterCapacity': inverterCapacity,
      'phase': phase,
      'structureBrand': structureBrand,
      'structureCount': structureCount,
      'structureHeight': structureHeight,
      'acWireBrand': acWireBrand,
      'acWireSize': acWireSize,
      'dcWireBrand': dcWireBrand,
      'dcWireSize': dcWireSize,
      'earthingWireBrand': earthingWireBrand,
      'earthingWireSize': earthingWireSize,
      'spdAcBrand': spdAcBrand,
      'spdAcDetails': spdAcDetails,
      'spdDcBrand': spdDcBrand,
      'spdDcDetails': spdDcDetails,
      'solarMeterBrand': solarMeterBrand,
      'solarMeterCount': solarMeterCount,
      'civilWork': civilWork,
      'earthingNotes': earthingNotes,
      'attachedDocs': attachedDocs,
    };
  }

  factory LeadConvertDraft.fromJson(Map<String, dynamic> json) {
    return LeadConvertDraft(
      leadId: json['leadId']?.toString() ?? '',
      currentStep: (json['currentStep'] is int) ? json['currentStep'] as int : 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      finalPriceRupees: (json['finalPriceRupees'] is num) ? (json['finalPriceRupees'] as num).toInt() : 0,
      isSubsidy: json['isSubsidy'] is bool ? json['isSubsidy'] as bool : true,
      panelBrand: json['panelBrand']?.toString() ?? '',
      panelWatt: (json['panelWatt'] is num) ? (json['panelWatt'] as num).toInt() : 540,
      panelCount: (json['panelCount'] is num) ? (json['panelCount'] as num).toInt() : 6,
      inverterBrand: json['inverterBrand']?.toString() ?? '',
      inverterCount: (json['inverterCount'] is num) ? (json['inverterCount'] as num).toInt() : 1,
      inverterCapacity: (json['inverterCapacity'] is num) ? (json['inverterCapacity'] as num).toDouble() : 3.3,
      phase: json['phase']?.toString() ?? 'single',
      structureBrand: json['structureBrand']?.toString() ?? '',
      structureCount: (json['structureCount'] is num) ? (json['structureCount'] as num).toInt() : 1,
      structureHeight: json['structureHeight']?.toString() ?? 'High Rise (8-10 ft)',
      acWireBrand: json['acWireBrand']?.toString() ?? 'Polycab',
      acWireSize: json['acWireSize']?.toString() ?? '4 sq mm',
      dcWireBrand: json['dcWireBrand']?.toString() ?? 'Siechem',
      dcWireSize: json['dcWireSize']?.toString() ?? '4 sq mm',
      earthingWireBrand: json['earthingWireBrand']?.toString() ?? 'Copper',
      earthingWireSize: json['earthingWireSize']?.toString() ?? '10 sq mm',
      spdAcBrand: json['spdAcBrand']?.toString() ?? 'Schneider Electric',
      spdAcDetails: json['spdAcDetails']?.toString() ?? 'Type 2 AC SPD 40kA',
      spdDcBrand: json['spdDcBrand']?.toString() ?? 'Havells',
      spdDcDetails: json['spdDcDetails']?.toString() ?? '1000V DC SPD 40kA',
      solarMeterBrand: json['solarMeterBrand']?.toString() ?? 'Secure Meters',
      solarMeterCount: (json['solarMeterCount'] is num) ? (json['solarMeterCount'] as num).toInt() : 1,
      civilWork: json['civilWork']?.toString() ?? '',
      earthingNotes: json['earthingNotes']?.toString() ?? '',
      attachedDocs: json['attachedDocs'] is Map
          ? Map<String, String>.from(json['attachedDocs'] as Map)
          : const {},
    );
  }
}

/// Manages autosaving and loading conversion drafts per lead.
class LeadConvertDraftManager {
  static const String _keyPrefix = 'solar_lead_convert_draft_';

  static String _getKey(String leadId) => '$_keyPrefix$leadId';

  /// Save lead conversion draft to SharedPreferences
  static Future<void> saveDraft(LeadConvertDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(draft.toJson());
    await prefs.setString(_getKey(draft.leadId), jsonStr);
  }

  /// Retrieve lead conversion draft if it exists
  static Future<LeadConvertDraft?> loadDraft(String leadId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_getKey(leadId));
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return LeadConvertDraft.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Check if a draft exists for the given lead ID
  static Future<bool> hasDraft(String leadId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_getKey(leadId));
  }

  /// Delete draft once conversion succeeds
  static Future<void> clearDraft(String leadId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getKey(leadId));
  }
}

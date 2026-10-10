import 'package:solar_pro/features/work_assignment/data/models/work_assignment_model.dart';

/// Scope of work extracted strictly from equipment specifications.
/// IMPORTANT: Under no circumstances does this model contain financial,
/// pricing, payment, or document information.
class SiteCustomerScope {
  // Structure Scope
  final String structureBrand;
  final String panelBrand;
  final int panelCount;
  final int panelWatt;
  final String structureHeight;

  // Electrical Scope
  final String inverterBrand;
  final double inverterCapacityKw;
  final String phase;
  final String acWire;
  final String dcWire;
  final String earthingWire;
  final String acdbSpd;
  final String dcdbSpd;
  final String solarMeter;

  // Civil Scope
  final String civilWorkNotes;
  final String earthingNotes;

  const SiteCustomerScope({
    // Structure
    this.structureBrand = 'Galvanized Iron Heavy Structure',
    this.panelBrand = 'Solar High-Efficiency Monocrystalline',
    this.panelCount = 10,
    this.panelWatt = 540,
    this.structureHeight = '8 ft Elevated Structure',
    // Electrical
    this.inverterBrand = 'Grid-Tied Solar Inverter',
    this.inverterCapacityKw = 5.0,
    this.phase = 'Single Phase (230V)',
    this.acWire = 'Polycab 4 sq.mm 3-Core Cu Armoured',
    this.dcWire = 'Finolex 4 sq.mm UV Protected DC Solar Wire',
    this.earthingWire = 'Havells 6 sq.mm Bare Copper Conductor',
    this.acdbSpd = 'Schneider Electric ACDB with Class II SPD',
    this.dcdbSpd = 'L&T DCDB with 1000V DC Surge Protector',
    this.solarMeter = 'Bidirectional Net Meter (Qty: 1)',
    // Civil
    this.civilWorkNotes = 'Cast 8 RCC foundation pedestals (M20 grade) with waterproofing bitumen coat at anchor holes.',
    this.earthingNotes = 'Drill and install 2x 2-meter copper bonded earthing electrodes with chemical compound slurry.',
  });

  factory SiteCustomerScope.fromCustomerJson(Map<String, dynamic> json) {
    return SiteCustomerScope(
      structureBrand: json['structure_type']?.toString().isNotEmpty == true
          ? json['structure_type'].toString()
          : (json['structure_brand']?.toString() ?? 'Galvanized Iron Heavy Structure'),
      panelBrand: json['panel_brand']?.toString() ?? 'Solar Mono PERC',
      panelCount: json['panel_count'] as int? ?? 10,
      panelWatt: json['panel_watt'] as int? ?? 540,
      structureHeight: json['structure_height']?.toString() ?? '8 ft Elevated Structure',
      inverterBrand: json['inverter_brand']?.toString() ?? 'Grid-Tied Solar Inverter',
      inverterCapacityKw: (json['capacity_kw'] as num?)?.toDouble() ?? 5.0,
      phase: json['phase']?.toString().toLowerCase().contains('three') == true
          ? 'Three Phase (415V)'
          : 'Single Phase (230V)',
      acWire: json['ac_wire']?.toString() ?? 'Polycab 4 sq.mm Cu Armoured',
      dcWire: json['dc_wire']?.toString() ?? 'Finolex 4 sq.mm DC Solar Wire',
      earthingWire: json['earthing_wire']?.toString() ?? 'Havells 6 sq.mm Copper Conductor',
      acdbSpd: json['acdb_spd']?.toString() ?? 'Schneider Electric ACDB with SPD',
      dcdbSpd: json['dcdb_spd']?.toString() ?? 'L&T DCDB 1000V SPD',
      solarMeter: json['solar_meter']?.toString() ?? 'Bidirectional Net Meter (Qty: 1)',
      civilWorkNotes: json['civil_notes']?.toString() ??
          'Cast foundation pedestals (M20 grade) with chemical anchoring and bitumen waterproofing.',
      earthingNotes: json['earthing_notes']?.toString() ??
          'Install dual chemical earthing electrodes with earth pit chambers.',
    );
  }

  /// Get role-specific bullet points or key-value pairs
  List<MapEntry<String, String>> getEntriesForRole(WorkType workType) {
    switch (workType) {
      case WorkType.structure:
        return [
          MapEntry('Structure Brand / Type', structureBrand),
          MapEntry('Panel Specifications', '$panelCount x $panelBrand ($panelWatt W)'),
          MapEntry('Structure Elevation', structureHeight),
          const MapEntry('Mounting Checklist', 'Torque check on all clamps, rust-inhibitor spray on joints'),
        ];
      case WorkType.electrical:
        return [
          MapEntry('Inverter', '$inverterBrand ($inverterCapacityKw kW - $phase)'),
          MapEntry('AC Wiring', acWire),
          MapEntry('DC Solar Wiring', dcWire),
          MapEntry('Earthing Wire', earthingWire),
          MapEntry('ACDB Protection', acdbSpd),
          MapEntry('DCDB Protection', dcdbSpd),
          MapEntry('Solar Net Meter', solarMeter),
        ];
      case WorkType.civil:
        return [
          MapEntry('Civil Work Scope', civilWorkNotes),
          MapEntry('Earthing Setup', earthingNotes),
          const MapEntry('Quality Note', 'Ensure curing for 48 hours minimum before heavy structure loading'),
        ];
    }
  }
}

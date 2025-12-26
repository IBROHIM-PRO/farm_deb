class CottonBatch {
  final int? id;
  final int cottonTypeId;
  final double weightKg;
  final int units;
  final DateTime arrivalDate;
  final String source;
  final double pricePerKg;
  final double freightCost;
  final double totalCost;
  final double remainingWeightKg;
  final int remainingUnits;

  CottonBatch({
    this.id,
    required this.cottonTypeId,
    required this.weightKg,
    required this.units,
    required this.arrivalDate,
    required this.source,
    required this.pricePerKg,
    required this.freightCost,
    required this.totalCost,
    double? remainingWeightKg,
    int? remainingUnits,
  }) : remainingWeightKg = remainingWeightKg ?? weightKg,
       remainingUnits = remainingUnits ?? units;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cottonTypeId': cottonTypeId,
      'weightKg': weightKg,
      'units': units,
      'arrivalDate': arrivalDate.toIso8601String(),
      'source': source,
      'pricePerKg': pricePerKg,
      'freightCost': freightCost,
      'totalCost': totalCost,
      'remainingWeightKg': remainingWeightKg,
      'remainingUnits': remainingUnits,
    };
  }

  static CottonBatch fromMap(Map<String, dynamic> map) {
    return CottonBatch(
      id: (map['id'] as num?)?.toInt(),
      cottonTypeId: (map['cottonTypeId'] as num?)?.toInt() ?? 0,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
      units: (map['units'] as num?)?.toInt() ?? 0,
      arrivalDate: map['arrivalDate'] != null ? DateTime.parse(map['arrivalDate'] as String) : DateTime.now(),
      source: map['source'] as String? ?? '',
      pricePerKg: (map['pricePerKg'] as num?)?.toDouble() ?? 0.0,
      freightCost: (map['freightCost'] as num?)?.toDouble() ?? 0.0,
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0.0,
      remainingWeightKg: (map['remainingWeightKg'] as num?)?.toDouble(),
      remainingUnits: (map['remainingUnits'] as num?)?.toInt(),
    );
  }

  CottonBatch copyWith({
    int? id,
    int? cottonTypeId,
    double? weightKg,
    int? units,
    DateTime? arrivalDate,
    String? source,
    double? pricePerKg,
    double? freightCost,
    double? totalCost,
    double? remainingWeightKg,
    int? remainingUnits,
  }) {
    return CottonBatch(
      id: id ?? this.id,
      cottonTypeId: cottonTypeId ?? this.cottonTypeId,
      weightKg: weightKg ?? this.weightKg,
      units: units ?? this.units,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      source: source ?? this.source,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      freightCost: freightCost ?? this.freightCost,
      totalCost: totalCost ?? this.totalCost,
      remainingWeightKg: remainingWeightKg ?? this.remainingWeightKg,
      remainingUnits: remainingUnits ?? this.remainingUnits,
    );
  }

  bool get isFullyDispatched => remainingWeightKg <= 0 || remainingUnits <= 0;
}

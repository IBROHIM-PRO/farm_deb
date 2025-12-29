/// Cattle Weight Measurement - Periodic Re-Weighting
/// Tracks weight changes over time for growth monitoring
class CattleWeight {
  final int? id;
  final int cattleId;          // Link to CattleRegistry
  final DateTime measurementDate;
  final double weight;         // Weight in kg
  final String weightUnit;     // Usually kg
  final String? notes;         // Optional measurement notes

  CattleWeight({
    this.id,
    required this.cattleId,
    required this.measurementDate,
    required this.weight,
    this.weightUnit = 'kg',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cattleId': cattleId,
      'measurementDate': measurementDate.toIso8601String(),
      'weight': weight,
      'weightUnit': weightUnit,
      'notes': notes,
    };
  }

  factory CattleWeight.fromMap(Map<String, dynamic> map) {
    return CattleWeight(
      id: map['id'] as int?,
      cattleId: (map['cattleId'] as num?)?.toInt() ?? 0,
      measurementDate: DateTime.parse(map['measurementDate'] as String),
      weight: (map['weight'] as num).toDouble(),
      weightUnit: map['weightUnit'] as String? ?? 'kg',
      notes: map['notes'] as String?,
    );
  }

  CattleWeight copyWith({
    int? id,
    int? cattleId,
    DateTime? measurementDate,
    double? weight,
    String? weightUnit,
    String? notes,
  }) {
    return CattleWeight(
      id: id ?? this.id,
      cattleId: cattleId ?? this.cattleId,
      measurementDate: measurementDate ?? this.measurementDate,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      notes: notes ?? this.notes,
    );
  }

  /// Display formatted weight with unit
  String get weightDisplay => '${weight.toStringAsFixed(1)} ${weightUnit}';

  /// Calculate weight difference from previous measurement
  double weightDifference(double previousWeight) => weight - previousWeight;

  /// Calculate weight gain percentage from previous measurement
  double weightGainPercentage(double previousWeight) {
    if (previousWeight <= 0) return 0;
    return ((weight - previousWeight) / previousWeight) * 100;
  }
}

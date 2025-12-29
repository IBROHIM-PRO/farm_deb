class CottonDispatch {
  final int? id;
  final int batchId;
  final double weightKg;
  final int units;
  final DateTime dispatchDate;
  final String destination;

  CottonDispatch({
    this.id,
    required this.batchId,
    required this.weightKg,
    required this.units,
    required this.dispatchDate,
    required this.destination,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'weightKg': weightKg,
      'units': units,
      'dispatchDate': dispatchDate.toIso8601String(),
      'destination': destination,
    };
  }

  static CottonDispatch fromMap(Map<String, dynamic> map) {
    return CottonDispatch(
      id: map['id']?.toInt(),
      batchId: map['batchId']?.toInt() ?? 0,
      weightKg: map['weightKg']?.toDouble() ?? 0.0,
      units: map['units']?.toInt() ?? 0,
      dispatchDate: DateTime.parse(map['dispatchDate'] ?? DateTime.now().toIso8601String()),
      destination: map['destination'] ?? '',
    );
  }

  CottonDispatch copyWith({
    int? id,
    int? batchId,
    double? weightKg,
    int? units,
    DateTime? dispatchDate,
    String? destination,
  }) {
    return CottonDispatch(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      weightKg: weightKg ?? this.weightKg,
      units: units ?? this.units,
      dispatchDate: dispatchDate ?? this.dispatchDate,
      destination: destination ?? this.destination,
    );
  }
}

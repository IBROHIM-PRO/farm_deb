enum ActivityType { plowing, irrigation, fertilization, spraying, harvesting, other }

class FieldActivity {
  final int? id;
  final int fieldId;
  final ActivityType type;
  final DateTime date;
  final double cost;
  final String currency;
  final String? description;
  final double? laborHours;

  FieldActivity({
    this.id,
    required this.fieldId,
    required this.type,
    required this.date,
    required this.cost,
    this.currency = 'сомонӣ',
    this.description,
    this.laborHours,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fieldId': fieldId,
      'type': type.name,
      'date': date.toIso8601String(),
      'cost': cost,
      'currency': currency,
      'description': description,
      'laborHours': laborHours,
    };
  }

  factory FieldActivity.fromMap(Map<String, dynamic> map) {
    return FieldActivity(
      id: map['id'] as int?,
      fieldId: (map['fieldId'] as num?)?.toInt() ?? 0,
      type: ActivityType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ActivityType.other,
      ),
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now(),
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'сомонӣ',
      description: map['description'] as String?,
      laborHours: (map['laborHours'] as num?)?.toDouble(),
    );
  }

  String get typeDisplayName {
    switch (type) {
      case ActivityType.plowing: return 'Plowing';
      case ActivityType.irrigation: return 'Irrigation';
      case ActivityType.fertilization: return 'Fertilization';
      case ActivityType.spraying: return 'Spraying';
      case ActivityType.harvesting: return 'Harvesting';
      case ActivityType.other: return 'Other';
    }
  }

  FieldActivity copyWith({
    int? id,
    int? fieldId,
    ActivityType? type,
    DateTime? date,
    double? cost,
    String? currency,
    String? description,
    double? laborHours,
  }) {
    return FieldActivity(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      type: type ?? this.type,
      date: date ?? this.date,
      cost: cost ?? this.cost,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      laborHours: laborHours ?? this.laborHours,
    );
  }
}

class Field {
  final int? id;
  final String name;
  final double area;
  final String areaUnit;
  final String? seedType;
  final DateTime? plantingDate;
  final String? notes;

  Field({
    this.id,
    required this.name,
    required this.area,
    this.areaUnit = 'hectare',
    this.seedType,
    this.plantingDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'area': area,
      'areaUnit': areaUnit,
      'seedType': seedType,
      'plantingDate': plantingDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory Field.fromMap(Map<String, dynamic> map) {
    return Field(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      area: (map['area'] as num?)?.toDouble() ?? 0.0,
      areaUnit: map['areaUnit'] as String? ?? 'hectare',
      seedType: map['seedType'] as String?,
      plantingDate: map['plantingDate'] != null
          ? DateTime.parse(map['plantingDate'] as String)
          : null,
      notes: map['notes'] as String?,
    );
  }

  Field copyWith({
    int? id,
    String? name,
    double? area,
    String? areaUnit,
    String? seedType,
    DateTime? plantingDate,
    String? notes,
  }) {
    return Field(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      areaUnit: areaUnit ?? this.areaUnit,
      seedType: seedType ?? this.seedType,
      plantingDate: plantingDate ?? this.plantingDate,
      notes: notes ?? this.notes,
    );
  }
}

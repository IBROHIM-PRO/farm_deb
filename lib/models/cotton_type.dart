class CottonType {
  final int? id;
  final String name;
  final double pricePerKg;

  CottonType({
    this.id,
    required this.name,
    required this.pricePerKg,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pricePerKg': pricePerKg,
    };
  }

  static CottonType fromMap(Map<String, dynamic> map) {
    return CottonType(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      pricePerKg: map['pricePerKg']?.toDouble() ?? 0.0,
    );
  }

  CottonType copyWith({
    int? id,
    String? name,
    double? pricePerKg,
  }) {
    return CottonType(
      id: id ?? this.id,
      name: name ?? this.name,
      pricePerKg: pricePerKg ?? this.pricePerKg,
    );
  }
}

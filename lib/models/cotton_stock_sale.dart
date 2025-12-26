class CottonStockSale {
  final int? id;
  final int buyerId;
  final DateTime saleDate;
  final double unitWeight;
  final int units;
  final double totalWeight;
  final double? pricePerKg;
  final double? pricePerUnit;
  final double? totalAmount;

  CottonStockSale({
    this.id,
    required this.buyerId,
    required this.saleDate,
    required this.unitWeight,
    required this.units,
    required this.totalWeight,
    this.pricePerKg,
    this.pricePerUnit,
    this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buyerId': buyerId,
      'saleDate': saleDate.toIso8601String(),
      'unitWeight': unitWeight,
      'units': units,
      'totalWeight': totalWeight,
      'pricePerKg': pricePerKg,
      'pricePerUnit': pricePerUnit,
      'totalAmount': totalAmount,
    };
  }

  static CottonStockSale fromMap(Map<String, dynamic> map) {
    return CottonStockSale(
      id: map['id']?.toInt(),
      buyerId: map['buyerId']?.toInt() ?? 0,
      saleDate: DateTime.parse(map['saleDate'] ?? DateTime.now().toIso8601String()),
      unitWeight: map['unitWeight']?.toDouble() ?? 0.0,
      units: map['units']?.toInt() ?? 0,
      totalWeight: map['totalWeight']?.toDouble() ?? 0.0,
      pricePerKg: map['pricePerKg']?.toDouble(),
      pricePerUnit: map['pricePerUnit']?.toDouble(),
      totalAmount: map['totalAmount']?.toDouble(),
    );
  }

  CottonStockSale copyWith({
    int? id,
    int? buyerId,
    DateTime? saleDate,
    double? unitWeight,
    int? units,
    double? totalWeight,
    double? pricePerKg,
    double? pricePerUnit,
    double? totalAmount,
  }) {
    return CottonStockSale(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      saleDate: saleDate ?? this.saleDate,
      unitWeight: unitWeight ?? this.unitWeight,
      units: units ?? this.units,
      totalWeight: totalWeight ?? this.totalWeight,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}

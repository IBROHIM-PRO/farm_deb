enum SaleType { byWeight, byUnits }
enum PaymentStatus { pending, partial, paid }

/// Represents cotton sale with unit-based selling and auto weight calculation
class CottonSale {
  final int? id;
  final int? harvestId;
  final DateTime date;
  final SaleType saleType;
  final double? weight;  // Auto-calculated when selling by units
  final int? units;      // Number of pieces
  final double? weightPerUnit;  // kg per unit (20, 30, etc.)
  final double pricePerUnit;    // Price per kg or per unit
  final double totalAmount;
  final String currency;
  final String? buyerName;
  final String? buyerPhone;
  final PaymentStatus paymentStatus;
  final double paidAmount;
  final String? notes;

  CottonSale({
    this.id,
    this.harvestId,
    required this.date,
    required this.saleType,
    this.weight,
    this.units,
    this.weightPerUnit,
    required this.pricePerUnit,
    required this.totalAmount,
    this.currency = 'сомонӣ',
    this.buyerName,
    this.buyerPhone,
    this.paymentStatus = PaymentStatus.pending,
    this.paidAmount = 0,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'harvestId': harvestId,
      'date': date.toIso8601String(),
      'saleType': saleType.name,
      'weight': weight,
      'units': units,
      'weightPerUnit': weightPerUnit,
      'pricePerUnit': pricePerUnit,
      'totalAmount': totalAmount,
      'currency': currency,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'paymentStatus': paymentStatus.name,
      'paidAmount': paidAmount,
      'notes': notes,
    };
  }

  factory CottonSale.fromMap(Map<String, dynamic> map) {
    return CottonSale(
      id: map['id'] as int?,
      harvestId: (map['harvestId'] as num?)?.toInt(),
      date: DateTime.parse(map['date'] as String),
      saleType: SaleType.values.firstWhere(
        (e) => e.name == map['saleType'],
        orElse: () => SaleType.byWeight,
      ),
      weight: (map['weight'] as num?)?.toDouble(),
      units: (map['units'] as num?)?.toInt(),
      weightPerUnit: (map['weightPerUnit'] as num?)?.toDouble(),
      pricePerUnit: (map['pricePerUnit'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'сомонӣ',
      buyerName: map['buyerName'] as String?,
      buyerPhone: map['buyerPhone'] as String?,
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == map['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
    );
  }

  CottonSale copyWith({
    int? id,
    int? harvestId,
    DateTime? date,
    SaleType? saleType,
    double? weight,
    int? units,
    double? weightPerUnit,
    double? pricePerUnit,
    double? totalAmount,
    String? currency,
    String? buyerName,
    String? buyerPhone,
    PaymentStatus? paymentStatus,
    double? paidAmount,
    String? notes,
  }) {
    return CottonSale(
      id: id ?? this.id,
      harvestId: harvestId ?? this.harvestId,
      date: date ?? this.date,
      saleType: saleType ?? this.saleType,
      weight: weight ?? this.weight,
      units: units ?? this.units,
      weightPerUnit: weightPerUnit ?? this.weightPerUnit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
    );
  }

  double get remainingAmount => totalAmount - paidAmount;

  /// Auto-calculates total weight when selling by units
  /// Formula: Units × Weight per Unit
  static double calculateTotalWeight(int units, double weightPerUnit) {
    return units * weightPerUnit;
  }

  /// Validates sale data based on sale type
  static String? validateSale({
    required SaleType saleType,
    int? units,
    double? weightPerUnit,
    double? weight,
    String? buyerName,
  }) {
    if (buyerName == null || buyerName.trim().isEmpty) {
      return 'Buyer name is required';
    }

    if (saleType == SaleType.byUnits) {
      if (units == null || units <= 0) {
        return 'Units must be greater than zero';
      }
      if (weightPerUnit == null || weightPerUnit <= 0) {
        return 'Weight per unit must be selected';
      }
    } else {
      if (weight == null || weight <= 0) {
        return 'Weight must be greater than zero';
      }
    }

    return null; // Valid
  }
}

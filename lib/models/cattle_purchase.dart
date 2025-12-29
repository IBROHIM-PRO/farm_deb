enum PurchasePaymentStatus { pending, partial, paid }

/// Cattle Purchase Event - Linked to Cattle Registry
/// Records the purchase transaction for a registered cow
class CattlePurchase {
  final int? id;
  final int cattleId;           // Link to CattleRegistry
  final DateTime purchaseDate;
  final double weightAtPurchase; // Weight in kg
  final double? pricePerKg;     // Price per kg (optional)
  final double? totalPrice;     // Total price (optional)
  final String currency;
  final String? sellerName;     // Who sold the cattle
  final double transportationCost; // Transportation/freight cost
  final PurchasePaymentStatus paymentStatus;
  final double paidAmount;      // Amount paid so far
  final String? notes;

  CattlePurchase({
    this.id,
    required this.cattleId,
    required this.purchaseDate,
    required this.weightAtPurchase,
    this.pricePerKg,
    this.totalPrice,
    this.currency = 'TJS',
    this.sellerName,
    this.transportationCost = 0,
    this.paymentStatus = PurchasePaymentStatus.paid,
    this.paidAmount = 0,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cattleId': cattleId,
      'purchaseDate': purchaseDate.toIso8601String(),
      'weightAtPurchase': weightAtPurchase,
      'pricePerKg': pricePerKg,
      'totalPrice': totalPrice,
      'currency': currency,
      'sellerName': sellerName,
      'transportationCost': transportationCost,
      'paymentStatus': paymentStatus.name,
      'paidAmount': paidAmount,
      'notes': notes,
    };
  }

  factory CattlePurchase.fromMap(Map<String, dynamic> map) {
    return CattlePurchase(
      id: map['id'] as int?,
      cattleId: map['cattleId'] as int,
      purchaseDate: DateTime.parse(map['purchaseDate'] as String),
      weightAtPurchase: (map['weightAtPurchase'] as num?)?.toDouble() ?? 0.0,
      pricePerKg: (map['pricePerKg'] as num?)?.toDouble(),
      totalPrice: (map['totalPrice'] as num?)?.toDouble(),
      currency: map['currency'] as String? ?? 'TJS',
      sellerName: map['sellerName'] as String?,
      transportationCost: (map['transportationCost'] as num?)?.toDouble() ?? 0,
      paymentStatus: PurchasePaymentStatus.values.firstWhere(
        (e) => e.name == map['paymentStatus'],
        orElse: () => PurchasePaymentStatus.paid,
      ),
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
    );
  }

  CattlePurchase copyWith({
    int? id,
    int? cattleId,
    DateTime? purchaseDate,
    double? weightAtPurchase,
    double? pricePerKg,
    double? totalPrice,
    String? currency,
    String? sellerName,
    double? transportationCost,
    PurchasePaymentStatus? paymentStatus,
    double? paidAmount,
    String? notes,
  }) {
    return CattlePurchase(
      id: id ?? this.id,
      cattleId: cattleId ?? this.cattleId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      weightAtPurchase: weightAtPurchase ?? this.weightAtPurchase,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalPrice: totalPrice ?? this.totalPrice,
      currency: currency ?? this.currency,
      sellerName: sellerName ?? this.sellerName,
      transportationCost: transportationCost ?? this.transportationCost,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
    );
  }

  /// Calculate total purchase cost including transportation
  double get totalCost {
    final basePrice = totalPrice ?? (pricePerKg != null ? pricePerKg! * weightAtPurchase : 0);
    return basePrice + transportationCost;
  }

  /// Remaining amount to be paid
  double get remainingAmount => totalCost - paidAmount;

  /// Payment status display in Tajik
  String get paymentStatusDisplay {
    switch (paymentStatus) {
      case PurchasePaymentStatus.pending: return 'Интизор';
      case PurchasePaymentStatus.partial: return 'Қисман';
      case PurchasePaymentStatus.paid: return 'Пардохт шуда';
    }
  }
}

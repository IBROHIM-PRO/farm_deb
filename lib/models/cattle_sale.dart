enum CattleSaleType { alive, slaughtered }
enum SalePaymentStatus { pending, partial, paid }

/// Cattle Sale Event - Linked to Cattle Registry
/// Records when a registered cow is sold (alive or slaughtered)
class CattleSale {
  final int? id;
  final int cattleId;          // Link to CattleRegistry
  final CattleSaleType saleType; // Live/Slaughtered
  final DateTime saleDate;
  
  // Weight details
  final double weight;         // Live weight OR meat weight
  final DateTime? slaughterDate; // Only for slaughtered sales
  final double? liveWeight;    // Live weight before slaughter (for reference)
  
  // Pricing
  final double pricePerKg;
  final double totalAmount;
  final String currency;
  
  // Buyer information
  final String? buyerName;
  final String? buyerPhone;
  
  // Payment tracking
  final SalePaymentStatus paymentStatus;
  final double paidAmount;
  
  // Transportation cost for this sale
  final double transportationCost;
  final String? notes;

  CattleSale({
    this.id,
    required this.cattleId,
    required this.saleDate,
    required this.saleType,
    required this.weight,
    this.slaughterDate,
    this.liveWeight,
    required this.pricePerKg,
    required this.totalAmount,
    this.currency = 'TJS',
    this.buyerName,
    this.buyerPhone,
    this.paymentStatus = SalePaymentStatus.pending,
    this.paidAmount = 0,
    this.transportationCost = 0,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cattleId': cattleId,
      'saleDate': saleDate.toIso8601String(),
      'saleType': saleType.name,
      'weight': weight,
      'slaughterDate': slaughterDate?.toIso8601String(),
      'liveWeight': liveWeight,
      'pricePerKg': pricePerKg,
      'totalAmount': totalAmount,
      'currency': currency,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'paymentStatus': paymentStatus.name,
      'paidAmount': paidAmount,
      'transportationCost': transportationCost,
      'notes': notes,
    };
  }

  factory CattleSale.fromMap(Map<String, dynamic> map) {
    return CattleSale(
      id: map['id'] as int?,
      cattleId: (map['cattleId'] as num?)?.toInt() ?? 0,
      saleDate: map['saleDate'] != null ? DateTime.parse(map['saleDate'] as String) : DateTime.now(),
      saleType: CattleSaleType.values.firstWhere(
        (e) => e.name == map['saleType'],
        orElse: () => CattleSaleType.alive,
      ),
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      slaughterDate: map['slaughterDate'] != null
          ? DateTime.parse(map['slaughterDate'] as String)
          : null,
      liveWeight: (map['liveWeight'] as num?)?.toDouble(),
      pricePerKg: (map['pricePerKg'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'TJS',
      buyerName: map['buyerName'] as String?,
      buyerPhone: map['buyerPhone'] as String?,
      paymentStatus: SalePaymentStatus.values.firstWhere(
        (e) => e.name == map['paymentStatus'],
        orElse: () => SalePaymentStatus.pending,
      ),
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      transportationCost: (map['transportationCost'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
    );
  }

  CattleSale copyWith({
    int? id,
    int? cattleId,
    DateTime? saleDate,
    CattleSaleType? saleType,
    double? weight,
    DateTime? slaughterDate,
    double? liveWeight,
    double? pricePerKg,
    double? totalAmount,
    String? currency,
    String? buyerName,
    String? buyerPhone,
    SalePaymentStatus? paymentStatus,
    double? paidAmount,
    double? transportationCost,
    String? notes,
  }) {
    return CattleSale(
      id: id ?? this.id,
      cattleId: cattleId ?? this.cattleId,
      saleDate: saleDate ?? this.saleDate,
      saleType: saleType ?? this.saleType,
      weight: weight ?? this.weight,
      slaughterDate: slaughterDate ?? this.slaughterDate,
      liveWeight: liveWeight ?? this.liveWeight,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      transportationCost: transportationCost ?? this.transportationCost,
      notes: notes ?? this.notes,
    );
  }

  double get remainingAmount => totalAmount - paidAmount;
  
  /// Calculates meat yield percentage (for slaughtered sales)
  /// Formula: (Meat Weight / Live Weight) × 100
  double? get meatYieldPercentage {
    if (saleType == CattleSaleType.slaughtered && liveWeight != null && liveWeight! > 0) {
      return (weight / liveWeight!) * 100;
    }
    return null;
  }
  
  /// Validates sale data
  static String? validate({
    required CattleSaleType saleType,
    required double weight,
    DateTime? slaughterDate,
    double? liveWeight,
    required double pricePerKg,
  }) {
    if (weight <= 0) return 'Weight must be greater than zero';
    if (pricePerKg <= 0) return 'Price per kg must be greater than zero';
    
    if (saleType == CattleSaleType.slaughtered) {
      if (slaughterDate == null) return 'Slaughter date is required for slaughtered sales';
      if (liveWeight != null && liveWeight <= 0) return 'Live weight must be greater than zero';
    }
    
    return null;
  }
}

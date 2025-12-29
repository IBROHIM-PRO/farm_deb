enum CottonType { lint, uluk, valakno }

/// Cotton Purchase Item - Details linked to Purchase Registry
/// Each cotton type purchased is a separate item
class CottonPurchaseItem {
  final int? id;
  final int purchaseId;           // Link to CottonPurchaseRegistry
  final CottonType cottonType;    // Lint/Uluk/Valakno
  final double weight;            // Weight in kg or tons
  final int units;                // Pieces/шт
  final double pricePerKg;        // Price per kg
  final double totalPrice;        // Auto-calculated: weight × pricePerKg
  final String? notes;            // Optional item notes
  final bool transferredToWarehouse; // Track if already transferred to warehouse

  CottonPurchaseItem({
    this.id,
    required this.purchaseId,
    required this.cottonType,
    required this.weight,
    required this.units,
    required this.pricePerKg,
    required this.totalPrice,
    this.notes,
    this.transferredToWarehouse = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchaseId': purchaseId,
      'cottonType': cottonType.name,
      'weight': weight,
      'units': units,
      'pricePerKg': pricePerKg,
      'totalPrice': totalPrice,
      'notes': notes,
      'transferredToWarehouse': transferredToWarehouse ? 1 : 0,
    };
  }

  factory CottonPurchaseItem.fromMap(Map<String, dynamic> map) {
    return CottonPurchaseItem(
      id: map['id'] as int?,
      purchaseId: (map['purchaseId'] as num?)?.toInt() ?? 0,
      cottonType: CottonType.values.firstWhere(
        (e) => e.name == map['cottonType'],
        orElse: () => CottonType.lint,
      ),
      weight: (map['weight'] as num).toDouble(),
      units: (map['units'] as num?)?.toInt() ?? 0,
      pricePerKg: (map['pricePerKg'] as num).toDouble(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }

  CottonPurchaseItem copyWith({
    int? id,
    int? purchaseId,
    CottonType? cottonType,
    double? weight,
    int? units,
    double? pricePerKg,
    double? totalPrice,
    String? notes,
  }) {
    return CottonPurchaseItem(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      cottonType: cottonType ?? this.cottonType,
      weight: weight ?? this.weight,
      units: units ?? this.units,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
    );
  }

  /// Cotton type display in Tajik
  String get cottonTypeDisplay {
    switch (cottonType) {
      case CottonType.lint: return 'Линт';
      case CottonType.uluk: return 'Улук';
      case CottonType.valakno: return 'Валакно';
    }
  }

  /// Auto-calculate total price from weight and price per kg
  static double calculateTotalPrice(double weight, double pricePerKg) {
    return weight * pricePerKg;
  }

  /// Display formatted weight
  String get weightDisplay => '${weight.toStringAsFixed(1)} кг';

  /// Display formatted units
  String get unitsDisplay => '$units дона';

  /// Display formatted price per kg
  String get priceDisplay => '${pricePerKg.toStringAsFixed(2)} TJS/кг';

  /// Display formatted total price
  String get totalPriceDisplay => '${totalPrice.toStringAsFixed(2)} TJS';
}

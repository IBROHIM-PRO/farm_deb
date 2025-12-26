import 'cotton_purchase_item.dart';

enum SalePaymentStatus { pending, partial, paid }

/// Cotton Sale Registry - Records sales of processed cotton
/// Automatically deducts from inventory when sale is confirmed
class CottonSaleRegistry {
  final int? id;
  final DateTime saleDate;
  final String? buyerName;          // Optional buyer name
  final CottonType cottonType;      // Type of cotton sold
  final double batchSize;           // Batch size (kg per unit)
  final int unitsSold;              // Number of units sold
  final double weightSold;          // Total weight sold (calculated)
  final double pricePerKg;          // Price per kg
  final double totalAmount;         // Total sale amount (calculated)
  final SalePaymentStatus paymentStatus; // Payment status
  final int sourceInventoryId;      // Link to inventory record
  final String? notes;              // Optional sale notes

  CottonSaleRegistry({
    this.id,
    required this.saleDate,
    this.buyerName,
    required this.cottonType,
    required this.batchSize,
    required this.unitsSold,
    required this.weightSold,
    required this.pricePerKg,
    required this.totalAmount,
    this.paymentStatus = SalePaymentStatus.pending,
    required this.sourceInventoryId,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleDate': saleDate.toIso8601String(),
      'buyerName': buyerName,
      'cottonType': cottonType.name,
      'batchSize': batchSize,
      'unitsSold': unitsSold,
      'weightSold': weightSold,
      'pricePerKg': pricePerKg,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus.name,
      'sourceInventoryId': sourceInventoryId,
      'notes': notes,
    };
  }

  factory CottonSaleRegistry.fromMap(Map<String, dynamic> map) {
    return CottonSaleRegistry(
      id: map['id'] as int?,
      saleDate: DateTime.parse(map['saleDate'] as String),
      buyerName: map['buyerName'] as String?,
      cottonType: CottonType.values.firstWhere(
        (e) => e.name == map['cottonType'],
        orElse: () => CottonType.lint,
      ),
      batchSize: (map['batchSize'] as num).toDouble(),
      unitsSold: (map['unitsSold'] as num?)?.toInt() ?? 0,
      weightSold: (map['weightSold'] as num).toDouble(),
      pricePerKg: (map['pricePerKg'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      paymentStatus: SalePaymentStatus.values.firstWhere(
        (e) => e.name == map['paymentStatus'],
        orElse: () => SalePaymentStatus.pending,
      ),
      sourceInventoryId: (map['sourceInventoryId'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String?,
    );
  }

  CottonSaleRegistry copyWith({
    int? id,
    DateTime? saleDate,
    String? buyerName,
    CottonType? cottonType,
    double? batchSize,
    int? unitsSold,
    double? weightSold,
    double? pricePerKg,
    double? totalAmount,
    SalePaymentStatus? paymentStatus,
    int? sourceInventoryId,
    String? notes,
  }) {
    return CottonSaleRegistry(
      id: id ?? this.id,
      saleDate: saleDate ?? this.saleDate,
      buyerName: buyerName ?? this.buyerName,
      cottonType: cottonType ?? this.cottonType,
      batchSize: batchSize ?? this.batchSize,
      unitsSold: unitsSold ?? this.unitsSold,
      weightSold: weightSold ?? this.weightSold,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      sourceInventoryId: sourceInventoryId ?? this.sourceInventoryId,
      notes: notes ?? this.notes,
    );
  }

  /// Auto-calculate weight sold from batch size and units sold
  static double calculateWeightSold(double batchSize, int unitsSold) {
    return batchSize * unitsSold;
  }

  /// Auto-calculate total amount from weight sold and price per kg
  static double calculateTotalAmount(double weightSold, double pricePerKg) {
    return weightSold * pricePerKg;
  }

  /// Cotton type display in Tajik
  String get cottonTypeDisplay {
    switch (cottonType) {
      case CottonType.lint: return 'Линт';
      case CottonType.uluk: return 'Улук';
      case CottonType.valakno: return 'Валакно';
    }
  }

  /// Payment status display in Tajik
  String get paymentStatusDisplay {
    switch (paymentStatus) {
      case SalePaymentStatus.pending: return 'Интизор';
      case SalePaymentStatus.partial: return 'Қисман';
      case SalePaymentStatus.paid: return 'Пардохт шуда';
    }
  }

  /// Display formatted batch size
  String get batchSizeDisplay => '${batchSize.toStringAsFixed(1)} кг/дона';

  /// Display formatted units sold
  String get unitsSoldDisplay => '$unitsSold дона';

  /// Display formatted weight sold
  String get weightSoldDisplay => '${weightSold.toStringAsFixed(1)} кг';

  /// Display formatted price per kg
  String get priceDisplay => '${pricePerKg.toStringAsFixed(2)} сомонӣ/кг';

  /// Display formatted total amount
  String get totalAmountDisplay => '${totalAmount.toStringAsFixed(2)} сомонӣ';

  /// Validates sale data before processing
  static String? validate({
    required int unitsSold,
    required double pricePerKg,
    required int availableUnits,
  }) {
    if (unitsSold <= 0) return 'Миқдори фуруш зарур аст';
    if (pricePerKg <= 0) return 'Нархи як кг зарур аст';
    if (unitsSold > availableUnits) return 'Дар анбор кофӣ нест';
    return null;
  }

  /// Creates a sale calculation summary for display
  Map<String, dynamic> get saleCalculation => {
    'cottonType': cottonTypeDisplay,
    'batchSize': batchSizeDisplay,
    'unitsSold': unitsSoldDisplay,
    'weightSold': weightSoldDisplay,
    'pricePerKg': priceDisplay,
    'totalAmount': totalAmountDisplay,
    'paymentStatus': paymentStatusDisplay,
  };
}

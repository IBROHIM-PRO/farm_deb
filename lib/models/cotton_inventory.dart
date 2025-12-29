import 'cotton_purchase_item.dart';

/// Processed Cotton Inventory - Warehouse/Stock View
/// Tracks available processed cotton batches ready for sale
class CottonInventory {
  final int? id;
  final CottonType cottonType;    // Lint/Uluk/Valakno
  final double batchSize;         // Weight per unit (kg)
  final int availableUnits;       // Available pieces in stock
  final double totalWeight;       // Total available weight (calculated)
  final int sourceProcessingId;   // Link to processing that created this batch

  CottonInventory({
    this.id,
    required this.cottonType,
    required this.batchSize,
    required this.availableUnits,
    required this.totalWeight,
    required this.sourceProcessingId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cottonType': cottonType.name,
      'batchSize': batchSize,
      'availableUnits': availableUnits,
      'totalWeight': totalWeight,
      'sourceProcessingId': sourceProcessingId,
    };
  }

  factory CottonInventory.fromMap(Map<String, dynamic> map) {
    return CottonInventory(
      id: map['id'] as int?,
      cottonType: CottonType.values.firstWhere(
        (e) => e.name == map['cottonType'],
        orElse: () => CottonType.lint,
      ),
      batchSize: (map['batchSize'] as num).toDouble(),
      availableUnits: (map['availableUnits'] as num?)?.toInt() ?? 0,
      totalWeight: (map['totalWeight'] as num).toDouble(),
      sourceProcessingId: (map['sourceProcessingId'] as num?)?.toInt() ?? 0,
    );
  }

  CottonInventory copyWith({
    int? id,
    CottonType? cottonType,
    double? batchSize,
    int? availableUnits,
    double? totalWeight,
    int? sourceProcessingId,
  }) {
    return CottonInventory(
      id: id ?? this.id,
      cottonType: cottonType ?? this.cottonType,
      batchSize: batchSize ?? this.batchSize,
      availableUnits: availableUnits ?? this.availableUnits,
      totalWeight: totalWeight ?? this.totalWeight,
      sourceProcessingId: sourceProcessingId ?? this.sourceProcessingId,
    );
  }

  /// Auto-calculate total weight from batch size and available units
  static double calculateTotalWeight(double batchSize, int availableUnits) {
    return batchSize * availableUnits;
  }

  /// Subtract units from inventory (for sales)
  CottonInventory subtractUnits(int unitsSold) {
    final newAvailableUnits = availableUnits - unitsSold;
    final newTotalWeight = calculateTotalWeight(batchSize, newAvailableUnits);
    
    return copyWith(
      availableUnits: newAvailableUnits,
      totalWeight: newTotalWeight,
    );
  }

  /// Add units to inventory (from processing)
  CottonInventory addUnits(int unitsAdded) {
    final newAvailableUnits = availableUnits + unitsAdded;
    final newTotalWeight = calculateTotalWeight(batchSize, newAvailableUnits);
    
    return copyWith(
      availableUnits: newAvailableUnits,
      totalWeight: newTotalWeight,
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

  /// Display formatted batch size
  String get batchSizeDisplay => '${batchSize.toStringAsFixed(1)} кг/дона';

  /// Display formatted available units
  String get availableUnitsDisplay => '$availableUnits дона';

  /// Display formatted total weight
  String get totalWeightDisplay => '${totalWeight.toStringAsFixed(1)} кг';

  /// Check if inventory has sufficient stock for sale
  bool hasSufficientStock(int requestedUnits) {
    return availableUnits >= requestedUnits;
  }

  /// Check if inventory is empty
  bool get isEmpty => availableUnits <= 0;

  /// Check if inventory is running low (less than 10 units)
  bool get isLowStock => availableUnits > 0 && availableUnits < 10;

  /// Inventory status display in Tajik
  String get statusDisplay {
    if (isEmpty) return 'Холӣ';
    if (isLowStock) return 'Кам';
    return 'Мавҷуд';
  }

  /// Validates inventory operation
  static String? validateSale({
    required int requestedUnits,
    required int availableUnits,
  }) {
    if (requestedUnits <= 0) return 'Миқдори фуруш зарур аст';
    if (requestedUnits > availableUnits) return 'Дар анбор кофӣ нест';
    return null;
  }
}

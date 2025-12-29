/// Processed Cotton Warehouse - Stores processed cotton with pieces and total weight
/// Processed cotton has no type distinction - all processed cotton is the same
class ProcessedCottonWarehouse {
  final int? id;
  final int pieces;                    // Number of pieces/bales
  final double totalWeight;            // Total weight in kilograms
  final double weightPerPiece;         // Weight of each piece (20-50 kg typically)
  final DateTime lastUpdated;
  final String notes;                  // Optional notes about this inventory
  final String? batchNumber;           // Optional batch tracking

  ProcessedCottonWarehouse({
    this.id,
    required this.pieces,
    required this.totalWeight,
    required this.weightPerPiece,
    required this.lastUpdated,
    this.notes = '',
    this.batchNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pieces': pieces,
      'totalWeight': totalWeight,
      'weightPerPiece': weightPerPiece,
      'lastUpdated': lastUpdated.toIso8601String(),
      'notes': notes,
      'batchNumber': batchNumber,
    };
  }

  factory ProcessedCottonWarehouse.fromMap(Map<String, dynamic> map) {
    return ProcessedCottonWarehouse(
      id: map['id'] as int?,
      pieces: (map['pieces'] as num?)?.toInt() ?? 0,
      totalWeight: (map['totalWeight'] as num?)?.toDouble() ?? 0.0,
      weightPerPiece: (map['weightPerPiece'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'] as String)
          : DateTime.now(),
      notes: map['notes'] as String? ?? '',
      batchNumber: map['batchNumber'] as String?,
    );
  }

  ProcessedCottonWarehouse copyWith({
    int? id,
    int? pieces,
    double? totalWeight,
    double? weightPerPiece,
    DateTime? lastUpdated,
    String? notes,
    String? batchNumber,
  }) {
    return ProcessedCottonWarehouse(
      id: id ?? this.id,
      pieces: pieces ?? this.pieces,
      totalWeight: totalWeight ?? this.totalWeight,
      weightPerPiece: weightPerPiece ?? this.weightPerPiece,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      notes: notes ?? this.notes,
      batchNumber: batchNumber ?? this.batchNumber,
    );
  }

  /// Add processed inventory (from processing)
  ProcessedCottonWarehouse addInventory({
    required int additionalPieces,
    required double additionalWeight,
    double? newWeightPerPiece,
  }) {
    final totalPieces = pieces + additionalPieces;
    final totalWeightNew = totalWeight + additionalWeight;
    
    // Calculate average weight per piece
    final avgWeightPerPiece = totalPieces > 0 
        ? totalWeightNew / totalPieces 
        : (newWeightPerPiece ?? weightPerPiece);
    
    return copyWith(
      pieces: totalPieces,
      totalWeight: totalWeightNew,
      weightPerPiece: avgWeightPerPiece,
      lastUpdated: DateTime.now(),
    );
  }

  /// Deduct inventory (for sales)
  ProcessedCottonWarehouse deductInventory({
    required int deductPieces,
    required double deductWeight,
  }) {
    if (deductPieces > pieces || deductWeight > totalWeight) {
      throw ArgumentError('Қадри кам карданӣ аз мавҷуд зиёд аст');
    }
    
    return copyWith(
      pieces: pieces - deductPieces,
      totalWeight: totalWeight - deductWeight,
      lastUpdated: DateTime.now(),
    );
  }

  /// Deduct inventory by weight only (calculate pieces automatically)
  ProcessedCottonWarehouse deductByWeight(double deductWeight) {
    if (deductWeight > totalWeight) {
      throw ArgumentError('Вазни кам карданӣ аз мавҷуд зиёд аст');
    }
    
    if (weightPerPiece <= 0) {
      throw ArgumentError('Вазни ҳар қисмат муайян нашудааст');
    }
    
    // Calculate how many pieces this weight represents
    final deductPieces = (deductWeight / weightPerPiece).round();
    
    return deductInventory(
      deductPieces: deductPieces,
      deductWeight: deductWeight,
    );
  }

  /// Check if enough inventory is available
  bool hasEnoughInventory({
    required int requiredPieces,
    required double requiredWeight,
  }) {
    return pieces >= requiredPieces && totalWeight >= requiredWeight;
  }

  /// Check if enough weight is available
  bool hasEnoughWeight(double requiredWeight) {
    return totalWeight >= requiredWeight;
  }

  /// Calculate total value based on price per kg
  double calculateValue(double pricePerKg) {
    return totalWeight * pricePerKg;
  }

  /// Get formatted weight range display
  String get weightRangeDisplay {
    if (pieces <= 0) return '0 қисмат';
    
    final minWeight = (weightPerPiece * 0.9).toStringAsFixed(1);
    final maxWeight = (weightPerPiece * 1.1).toStringAsFixed(1);
    
    return '$pieces қисмат (${minWeight}-${maxWeight} кг ҳар як)';
  }

  /// Validate inventory data
  static String? validate({
    required int pieces,
    required double totalWeight,
    required double weightPerPiece,
  }) {
    if (pieces < 0) return 'Теъдоди қисматҳо наметавонад манфӣ бошад';
    if (totalWeight < 0) return 'Вазн наметавонад манфӣ бошад';
    if (weightPerPiece < 0) return 'Вазни ҳар қисмат наметавонад манфӣ бошад';
    
    if (pieces > 0 && totalWeight <= 0) {
      return 'Агар қисматҳо мавҷуд бошанд, вазн бояд муҳбат бошад';
    }
    
    if (weightPerPiece < 20 || weightPerPiece > 50) {
      return 'Вазни ҳар қисмат бояд байни 20 то 50 кг бошад';
    }
    
    // Check if total weight is reasonable compared to pieces and weight per piece
    if (pieces > 0) {
      final expectedWeight = pieces * weightPerPiece;
      final tolerance = expectedWeight * 0.2; // 20% tolerance
      
      if (Math.abs(totalWeight - expectedWeight) > tolerance) {
        return 'Вазни умумӣ ба теъдоди қисматҳо мувофиқат намекунад';
      }
    }
    
    return null;
  }

  /// Create initial inventory from processing
  static ProcessedCottonWarehouse createFromProcessing({
    required int pieces,
    required double totalWeight,
    required double weightPerPiece,
    String notes = '',
    String? batchNumber,
  }) {
    return ProcessedCottonWarehouse(
      pieces: pieces,
      totalWeight: totalWeight,
      weightPerPiece: weightPerPiece,
      lastUpdated: DateTime.now(),
      notes: notes,
      batchNumber: batchNumber,
    );
  }

  /// Create empty inventory
  static ProcessedCottonWarehouse empty() {
    return ProcessedCottonWarehouse(
      pieces: 0,
      totalWeight: 0.0,
      weightPerPiece: 25.0, // Default 25kg per piece
      lastUpdated: DateTime.now(),
    );
  }
}

// Helper class for calculations
class Math {
  static double abs(double value) {
    return value < 0 ? -value : value;
  }
}

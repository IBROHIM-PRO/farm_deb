/// Raw Cotton Warehouse - Stores 3 types of cotton with pieces and kilograms
enum RawCottonType { lint, sliver, other }

class RawCottonWarehouse {
  final int? id;
  final RawCottonType cottonType;
  final int pieces;           // Number of pieces/bales
  final double totalWeight;   // Total weight in kilograms
  final DateTime lastUpdated;
  final String notes;         // Optional notes about this inventory

  RawCottonWarehouse({
    this.id,
    required this.cottonType,
    required this.pieces,
    required this.totalWeight,
    required this.lastUpdated,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cottonType': cottonType.name,
      'pieces': pieces,
      'totalWeight': totalWeight,
      'lastUpdated': lastUpdated.toIso8601String(),
      'notes': notes,
    };
  }

  factory RawCottonWarehouse.fromMap(Map<String, dynamic> map) {
    return RawCottonWarehouse(
      id: map['id'] as int?,
      cottonType: RawCottonType.values.firstWhere(
        (e) => e.name == map['cottonType'],
        orElse: () => RawCottonType.other,
      ),
      pieces: (map['pieces'] as num?)?.toInt() ?? 0,
      totalWeight: (map['totalWeight'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'] as String)
          : DateTime.now(),
      notes: map['notes'] as String? ?? '',
    );
  }

  RawCottonWarehouse copyWith({
    int? id,
    RawCottonType? cottonType,
    int? pieces,
    double? totalWeight,
    DateTime? lastUpdated,
    String? notes,
  }) {
    return RawCottonWarehouse(
      id: id ?? this.id,
      cottonType: cottonType ?? this.cottonType,
      pieces: pieces ?? this.pieces,
      totalWeight: totalWeight ?? this.totalWeight,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      notes: notes ?? this.notes,
    );
  }

  /// Display name for cotton type in Tajik
  String get cottonTypeDisplay {
    switch (cottonType) {
      case RawCottonType.lint: return 'Линт';
      case RawCottonType.sliver: return 'Слайвер';
      case RawCottonType.other: return 'Дигар';
    }
  }

  /// Average weight per piece
  double get averageWeightPerPiece {
    if (pieces <= 0) return 0.0;
    return totalWeight / pieces;
  }

  /// Add inventory (from purchase)
  RawCottonWarehouse addInventory({
    required int additionalPieces,
    required double additionalWeight,
  }) {
    return copyWith(
      pieces: pieces + additionalPieces,
      totalWeight: totalWeight + additionalWeight,
      lastUpdated: DateTime.now(),
    );
  }

  /// Deduct inventory (for processing)
  RawCottonWarehouse deductInventory({
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

  /// Check if enough inventory is available
  bool hasEnoughInventory({
    required int requiredPieces,
    required double requiredWeight,
  }) {
    return pieces >= requiredPieces && totalWeight >= requiredWeight;
  }

  /// Validate inventory data
  static String? validate({
    required int pieces,
    required double totalWeight,
  }) {
    if (pieces < 0) return 'Теъдоди қисматҳо наметавонад манфӣ бошад';
    if (totalWeight < 0) return 'Вазн наметавонад манфӣ бошад';
    if (pieces > 0 && totalWeight <= 0) return 'Агар қисматҳо мавҷуд бошанд, вазн бояд муҳбат бошад';
    return null;
  }

  /// Create initial inventory from purchase
  static RawCottonWarehouse createFromPurchase({
    required RawCottonType cottonType,
    required int pieces,
    required double totalWeight,
    String notes = '',
  }) {
    return RawCottonWarehouse(
      cottonType: cottonType,
      pieces: pieces,
      totalWeight: totalWeight,
      lastUpdated: DateTime.now(),
      notes: notes,
    );
  }
}

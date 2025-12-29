/// Represents cotton processing record supporting Lint, Uluk, and Valakno types
class CottonHarvest {
  final int? id;
  final int fieldId;
  final DateTime date;
  final double rawWeight;
  final String weightUnit;
  
  // Processing inputs - multiple cotton types
  final double? lintWeight;
  final double? ulukWeight;
  final double? valaknoWeight;
  final double? extraValaknoWeight;  // Optional additional Valakno
  
  final double? processedWeight;
  final int? processedUnits;
  final bool isProcessed;
  final String? notes;

  CottonHarvest({
    this.id,
    required this.fieldId,
    required this.date,
    required this.rawWeight,
    this.weightUnit = 'kg',
    this.lintWeight,
    this.ulukWeight,
    this.valaknoWeight,
    this.extraValaknoWeight,
    this.processedWeight,
    this.processedUnits,
    this.isProcessed = false,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fieldId': fieldId,
      'date': date.toIso8601String(),
      'rawWeight': rawWeight,
      'weightUnit': weightUnit,
      'lintWeight': lintWeight,
      'ulukWeight': ulukWeight,
      'valaknoWeight': valaknoWeight,
      'extraValaknoWeight': extraValaknoWeight,
      'processedWeight': processedWeight,
      'processedUnits': processedUnits,
      'isProcessed': isProcessed ? 1 : 0,
      'notes': notes,
    };
  }

  factory CottonHarvest.fromMap(Map<String, dynamic> map) {
    return CottonHarvest(
      id: map['id'] as int?,
      fieldId: (map['fieldId'] as num?)?.toInt() ?? 0,
      date: DateTime.parse(map['date'] as String),
      rawWeight: (map['rawWeight'] as num?)?.toDouble() ?? 0.0,
      weightUnit: map['weightUnit'] as String? ?? 'kg',
      lintWeight: (map['lintWeight'] as num?)?.toDouble(),
      ulukWeight: (map['ulukWeight'] as num?)?.toDouble(),
      valaknoWeight: (map['valaknoWeight'] as num?)?.toDouble(),
      extraValaknoWeight: (map['extraValaknoWeight'] as num?)?.toDouble(),
      processedWeight: (map['processedWeight'] as num?)?.toDouble(),
      processedUnits: (map['processedUnits'] as num?)?.toInt(),
      isProcessed: map['isProcessed'] == 1,
      notes: map['notes'] as String?,
    );
  }

  CottonHarvest copyWith({
    int? id,
    int? fieldId,
    DateTime? date,
    double? rawWeight,
    String? weightUnit,
    double? lintWeight,
    double? ulukWeight,
    double? valaknoWeight,
    double? extraValaknoWeight,
    double? processedWeight,
    int? processedUnits,
    bool? isProcessed,
    String? notes,
  }) {
    return CottonHarvest(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      date: date ?? this.date,
      rawWeight: rawWeight ?? this.rawWeight,
      weightUnit: weightUnit ?? this.weightUnit,
      lintWeight: lintWeight ?? this.lintWeight,
      ulukWeight: ulukWeight ?? this.ulukWeight,
      valaknoWeight: valaknoWeight ?? this.valaknoWeight,
      extraValaknoWeight: extraValaknoWeight ?? this.extraValaknoWeight,
      processedWeight: processedWeight ?? this.processedWeight,
      processedUnits: processedUnits ?? this.processedUnits,
      isProcessed: isProcessed ?? this.isProcessed,
      notes: notes ?? this.notes,
    );
  }

  /// Calculates total input weight from selected cotton types
  double get totalInputWeight {
    double total = 0.0;
    if (lintWeight != null) total += lintWeight!;
    if (ulukWeight != null) total += ulukWeight!;
    if (valaknoWeight != null) total += valaknoWeight!;
    // Extra Valakno is not included in processing calculation
    return total > 0 ? total : rawWeight;
  }

  /// Calculates yield percentage: (ProcessedWeight / TotalInputWeight) × 100
  double get yieldPercentage {
    if (processedWeight == null) return 0;
    final input = totalInputWeight;
    if (input == 0) return 0;
    return (processedWeight! / input) * 100;
  }

  /// Validates processing rules: Valakno cannot be processed alone
  bool get isValidProcessing {
    final hasLint = lintWeight != null && lintWeight! > 0;
    final hasUluk = ulukWeight != null && ulukWeight! > 0;
    final hasValakno = valaknoWeight != null && valaknoWeight! > 0;
    
    // Valakno alone is not allowed
    if (hasValakno && !hasLint && !hasUluk) return false;
    
    return true;
  }

  /// Auto-calculates recommended Valakno weight when Lint and Uluk are equal
  static double? calculateRecommendedValakno(double? lintWeight, double? ulukWeight) {
    if (lintWeight == null || ulukWeight == null) return null;
    if ((lintWeight - ulukWeight).abs() < 10) { // Approximately equal
      return 250.0; // Standard Valakno weight
    }
    return null;
  }
}

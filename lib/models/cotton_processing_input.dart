import 'cotton_purchase_item.dart';

/// Cotton Processing Input Item - Input cotton used in processing
/// Links to specific cotton purchase items and tracks consumption
class CottonProcessingInput {
  final int? id;
  final int processingId;         // Link to CottonProcessingRegistry
  final CottonType cottonType;    // Lint/Uluk/Valakno
  final int unitsUsed;            // Units consumed from purchase
  final double weightUsed;        // Weight consumed (kg)
  final int sourcePurchaseItemId; // Link to CottonPurchaseItem

  CottonProcessingInput({
    this.id,
    required this.processingId,
    required this.cottonType,
    required this.unitsUsed,
    required this.weightUsed,
    required this.sourcePurchaseItemId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'processingId': processingId,
      'cottonType': cottonType.name,
      'unitsUsed': unitsUsed,
      'weightUsed': weightUsed,
      'sourcePurchaseItemId': sourcePurchaseItemId,
    };
  }

  factory CottonProcessingInput.fromMap(Map<String, dynamic> map) {
    return CottonProcessingInput(
      id: map['id'] as int?,
      processingId: (map['processingId'] as num?)?.toInt() ?? 0,
      cottonType: CottonType.values.firstWhere(
        (e) => e.name == map['cottonType'],
        orElse: () => CottonType.lint,
      ),
      unitsUsed: (map['unitsUsed'] as num?)?.toInt() ?? 0,
      weightUsed: (map['weightUsed'] as num?)?.toDouble() ?? 0.0,
      sourcePurchaseItemId: (map['sourcePurchaseItemId'] as num?)?.toInt() ?? 0,
    );
  }

  CottonProcessingInput copyWith({
    int? id,
    int? processingId,
    CottonType? cottonType,
    int? unitsUsed,
    double? weightUsed,
    int? sourcePurchaseItemId,
  }) {
    return CottonProcessingInput(
      id: id ?? this.id,
      processingId: processingId ?? this.processingId,
      cottonType: cottonType ?? this.cottonType,
      unitsUsed: unitsUsed ?? this.unitsUsed,
      weightUsed: weightUsed ?? this.weightUsed,
      sourcePurchaseItemId: sourcePurchaseItemId ?? this.sourcePurchaseItemId,
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

  /// Display formatted units used
  String get unitsUsedDisplay => '$unitsUsed дона';

  /// Display formatted weight used
  String get weightUsedDisplay => '${weightUsed.toStringAsFixed(1)} кг';

  /// Validates processing input data
  static String? validate({
    required int unitsUsed,
    required double weightUsed,
    required int availableUnits,
  }) {
    if (unitsUsed <= 0) return 'Миқдори истифода зарур аст';
    if (weightUsed <= 0) return 'Вазни истифода зарур аст';
    if (unitsUsed > availableUnits) return 'Миқдор аз мавҷуд зиёд аст';
    return null;
  }
}

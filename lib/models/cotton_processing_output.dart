import 'cotton_purchase_item.dart';

/// Cotton Processing Output - Finished Cotton Batches
/// Records processed cotton packed into bags/lots after processing
class CottonProcessingOutput {
  final int? id;
  final int processingId;         // Link to CottonProcessingRegistry
  final CottonType cottonType;    // Type of processed cotton
  final double batchWeightPerUnit; // Weight per unit (10, 20, 40, 50 kg, etc.)
  final int numberOfUnits;        // Number of pieces/bags
  final double totalWeight;       // Auto-calculated: batchWeightPerUnit × numberOfUnits

  CottonProcessingOutput({
    this.id,
    required this.processingId,
    required this.cottonType,
    required this.batchWeightPerUnit,
    required this.numberOfUnits,
    required this.totalWeight,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'processingId': processingId,
      'cottonType': cottonType.name,
      'batchWeightPerUnit': batchWeightPerUnit,
      'numberOfUnits': numberOfUnits,
      'totalWeight': totalWeight,
    };
  }

  factory CottonProcessingOutput.fromMap(Map<String, dynamic> map) {
    return CottonProcessingOutput(
      id: map['id'] as int?,
      processingId: (map['processingId'] as num?)?.toInt() ?? 0,
      cottonType: CottonType.values.firstWhere(
        (e) => e.name == map['cottonType'],
        orElse: () => CottonType.lint,
      ),
      batchWeightPerUnit: (map['batchWeightPerUnit'] as num?)?.toDouble() ?? 0.0,
      numberOfUnits: (map['numberOfUnits'] as num?)?.toInt() ?? 0,
      totalWeight: (map['totalWeight'] as num?)?.toDouble() ?? 0.0,
    );
  }

  CottonProcessingOutput copyWith({
    int? id,
    int? processingId,
    CottonType? cottonType,
    double? batchWeightPerUnit,
    int? numberOfUnits,
    double? totalWeight,
  }) {
    return CottonProcessingOutput(
      id: id ?? this.id,
      processingId: processingId ?? this.processingId,
      cottonType: cottonType ?? this.cottonType,
      batchWeightPerUnit: batchWeightPerUnit ?? this.batchWeightPerUnit,
      numberOfUnits: numberOfUnits ?? this.numberOfUnits,
      totalWeight: totalWeight ?? this.totalWeight,
    );
  }

  /// Auto-calculate total weight from batch weight and number of units
  static double calculateTotalWeight(double batchWeightPerUnit, int numberOfUnits) {
    return batchWeightPerUnit * numberOfUnits;
  }

  /// Cotton type display in Tajik
  String get cottonTypeDisplay {
    switch (cottonType) {
      case CottonType.lint: return 'Линт';
      case CottonType.uluk: return 'Улук';
      case CottonType.valakno: return 'Валакно';
    }
  }

  /// Display formatted batch weight per unit
  String get batchWeightDisplay => '${batchWeightPerUnit.toStringAsFixed(1)} кг/дона';

  /// Display formatted number of units
  String get unitsDisplay => '$numberOfUnits дона';

  /// Display formatted total weight
  String get totalWeightDisplay => '${totalWeight.toStringAsFixed(1)} кг';

  /// Validates output batch data
  static String? validate({
    required double batchWeightPerUnit,
    required int numberOfUnits,
  }) {
    if (batchWeightPerUnit <= 0) return 'Вазни як дона зарур аст';
    if (numberOfUnits <= 0) return 'Шумораи донаҳо зарур аст';
    return null;
  }

  /// Common batch sizes for quick selection
  static List<double> get commonBatchSizes => [10.0, 20.0, 40.0, 50.0];
}

import 'cotton_purchase_item.dart';

/// Cotton Processing Calculator - Automatic ratio calculations
/// Handles the complex processing formulas and ratios
class CottonProcessingCalculator {
  // Standard base ratios (reference values)
  static const double standardLintKg = 500.0;
  static const double standardUlukKg = 500.0;
  static const double standardValaknoKg = 250.0;

  /// Calculate automatic Valakno for three cotton types processing
  /// Formula: (Lint + Uluk) ≈ 2, Valakno ≈ 0.5
  static double calculateAutoValakno({
    required double lintKg,
    required double ulukKg,
  }) {
    final combinedWeight = lintKg + ulukKg;
    // Ratio calculation: Combined weight relates to Valakno as 2:0.5 = 4:1
    return combinedWeight / 4.0;
  }

  /// Calculate expected output for two cotton types
  /// Formula: Lint or Uluk ≈ 2, Valakno ≈ 1
  static double calculateTwoCottonOutput({
    required double primaryCottonKg,
    required double valaknoKg,
  }) {
    // For two cotton processing, the ratio is 2:1
    return (primaryCottonKg / 2.0) + valaknoKg;
  }

  /// Calculate expected output for single cotton type
  /// Formula: Base ratio 1 → 0.5 logic
  static double calculateSingleCottonOutput({
    required double cottonKg,
  }) {
    return cottonKg * 0.5;
  }

  /// Validate processing inputs against available stock
  static String? validateProcessingInputs({
    required Map<CottonType, double> requestedWeights,
    required Map<CottonType, double> availableWeights,
  }) {
    for (final entry in requestedWeights.entries) {
      final type = entry.key;
      final requested = entry.value;
      final available = availableWeights[type] ?? 0;

      if (requested > available) {
        final typeName = _getCottonTypeName(type);
        return '$typeName: талаб $requested кг, мавҷуд $available кг';
      }
    }
    return null;
  }

  /// Get processing type based on cotton types used
  static ProcessingType determineProcessingType({
    required bool hasLint,
    required bool hasUluk,
    required bool hasValakno,
  }) {
    if (hasLint && hasUluk && hasValakno) {
      return ProcessingType.threeCottonTypes;
    } else if ((hasLint || hasUluk) && hasValakno) {
      return ProcessingType.twoCottonTypes;
    } else {
      return ProcessingType.singleCottonType;
    }
  }

  /// Calculate total processing input weight
  static double calculateTotalInputWeight({
    required double lintKg,
    required double ulukKg,
    required double valaknoKg,
    required double extraValaknoKg,
  }) {
    return lintKg + ulukKg + valaknoKg + extraValaknoKg;
  }

  /// Calculate processing yield percentage
  static double calculateYieldPercentage({
    required double inputWeight,
    required double outputWeight,
  }) {
    if (inputWeight <= 0) return 0;
    return (outputWeight / inputWeight) * 100;
  }

  static String _getCottonTypeName(CottonType type) {
    switch (type) {
      case CottonType.lint: return 'Линт';
      case CottonType.uluk: return 'Улук';
      case CottonType.valakno: return 'Валакно';
    }
  }
}

enum ProcessingType {
  threeCottonTypes,  // Lint + Uluk + Valakno
  twoCottonTypes,    // (Lint OR Uluk) + Valakno  
  singleCottonType,  // Only Lint OR Uluk
}

/// Processing type display in Tajik
extension ProcessingTypeExtension on ProcessingType {
  String get display {
    switch (this) {
      case ProcessingType.threeCottonTypes: return 'Се навъи пахта';
      case ProcessingType.twoCottonTypes: return 'Ду навъи пахта';
      case ProcessingType.singleCottonType: return 'Як навъи пахта';
    }
  }
}

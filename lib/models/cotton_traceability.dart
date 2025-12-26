import 'cotton_purchase_item.dart';

/// Cotton Traceability - Complete tracking from Purchase → Processing → Sale
/// Provides full audit trail for cotton lifecycle
class CottonTraceability {
  final int? id;
  final CottonType cottonType;
  final String traceabilityCode;    // Unique code for tracking
  
  // Purchase information
  final int purchaseId;
  final DateTime purchaseDate;
  final String supplierName;
  final double originalWeight;
  final double originalUnits;
  
  // Processing information (optional)
  final int? processingId;
  final DateTime? processingDate;
  final double? processedWeight;
  final double? processedUnits;
  
  // Sale information (optional)
  final int? saleId;
  final DateTime? saleDate;
  final String? buyerName;
  final double? soldWeight;
  final double? soldUnits;
  
  // Current status
  final TraceabilityStatus status;

  CottonTraceability({
    this.id,
    required this.cottonType,
    required this.traceabilityCode,
    required this.purchaseId,
    required this.purchaseDate,
    required this.supplierName,
    required this.originalWeight,
    required this.originalUnits,
    this.processingId,
    this.processingDate,
    this.processedWeight,
    this.processedUnits,
    this.saleId,
    this.saleDate,
    this.buyerName,
    this.soldWeight,
    this.soldUnits,
    this.status = TraceabilityStatus.purchased,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cottonType': cottonType.name,
      'traceabilityCode': traceabilityCode,
      'purchaseId': purchaseId,
      'purchaseDate': purchaseDate.toIso8601String(),
      'supplierName': supplierName,
      'originalWeight': originalWeight,
      'originalUnits': originalUnits,
      'processingId': processingId,
      'processingDate': processingDate?.toIso8601String(),
      'processedWeight': processedWeight,
      'processedUnits': processedUnits,
      'saleId': saleId,
      'saleDate': saleDate?.toIso8601String(),
      'buyerName': buyerName,
      'soldWeight': soldWeight,
      'soldUnits': soldUnits,
      'status': status.name,
    };
  }

  factory CottonTraceability.fromMap(Map<String, dynamic> map) {
    return CottonTraceability(
      id: map['id'] as int?,
      cottonType: CottonType.values.firstWhere(
        (e) => e.name == map['cottonType'],
        orElse: () => CottonType.lint,
      ),
      traceabilityCode: map['traceabilityCode'] as String? ?? '',
      purchaseId: (map['purchaseId'] as num?)?.toInt() ?? 0,
      purchaseDate: map['purchaseDate'] != null ? DateTime.parse(map['purchaseDate'] as String) : DateTime.now(),
      supplierName: map['supplierName'] as String? ?? '',
      originalWeight: (map['originalWeight'] as num).toDouble(),
      originalUnits: (map['originalUnits'] as num).toDouble(),
      processingId: (map['processingId'] as num?)?.toInt(),
      processingDate: map['processingDate'] != null
          ? DateTime.parse(map['processingDate'] as String)
          : null,
      processedWeight: (map['processedWeight'] as num?)?.toDouble(),
      processedUnits: (map['processedUnits'] as num?)?.toDouble(),
      saleId: (map['saleId'] as num?)?.toInt(),
      saleDate: map['saleDate'] != null
          ? DateTime.parse(map['saleDate'] as String)
          : null,
      buyerName: map['buyerName'] as String?,
      soldWeight: (map['soldWeight'] as num?)?.toDouble(),
      soldUnits: (map['soldUnits'] as num?)?.toDouble(),
      status: TraceabilityStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TraceabilityStatus.purchased,
      ),
    );
  }

  /// Generate unique traceability code
  static String generateTraceabilityCode(CottonType type, DateTime purchaseDate) {
    final typeCode = type.name.toUpperCase().substring(0, 1);
    final dateCode = '${purchaseDate.year}${purchaseDate.month.toString().padLeft(2, '0')}${purchaseDate.day.toString().padLeft(2, '0')}';
    final timeCode = '${purchaseDate.hour.toString().padLeft(2, '0')}${purchaseDate.minute.toString().padLeft(2, '0')}';
    return '$typeCode$dateCode$timeCode';
  }

  /// Cotton type display in Tajik
  String get cottonTypeDisplay {
    switch (cottonType) {
      case CottonType.lint: return 'Линт';
      case CottonType.uluk: return 'Улук';
      case CottonType.valakno: return 'Валакно';
    }
  }

  /// Status display in Tajik
  String get statusDisplay {
    switch (status) {
      case TraceabilityStatus.purchased: return 'Харида шуда';
      case TraceabilityStatus.processed: return 'Коркард шуда';
      case TraceabilityStatus.sold: return 'Фурӯхта шуда';
    }
  }

  /// Get processing yield percentage if processed
  double? get processingYield {
    if (processedWeight != null && originalWeight > 0) {
      return (processedWeight! / originalWeight) * 100;
    }
    return null;
  }

  /// Check if cotton is fully traced (purchased → processed → sold)
  bool get isFullyTraced => status == TraceabilityStatus.sold;

  /// Get current stage description
  String get currentStageDescription {
    switch (status) {
      case TraceabilityStatus.purchased:
        return 'Дар анбор - омода барои коркард';
      case TraceabilityStatus.processed:
        return 'Коркард шуда - омода барои фуруш';
      case TraceabilityStatus.sold:
        return 'Фурӯхта шуда - тамом';
    }
  }
}

enum TraceabilityStatus {
  purchased,  // Хариданӣ
  processed,  // Коркардӣ  
  sold,       // Фурӯхтанӣ
}

/// Cotton Processing Registry - Master Record
/// Groups all cotton types processed in one operation
/// Always linked to an existing Cotton Purchase Registry
class CottonProcessingRegistry {
  final int? id;
  final int linkedPurchaseId;     // Link to CottonPurchaseRegistry
  final DateTime? processingDate; // Optional processing date
  final String? notes;            // Optional processing notes

  CottonProcessingRegistry({
    this.id,
    required this.linkedPurchaseId,
    this.processingDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'linkedPurchaseId': linkedPurchaseId,
      'processingDate': processingDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory CottonProcessingRegistry.fromMap(Map<String, dynamic> map) {
    return CottonProcessingRegistry(
      id: map['id'] as int?,
      linkedPurchaseId: map['linkedPurchaseId'] as int,
      processingDate: map['processingDate'] != null
          ? DateTime.parse(map['processingDate'] as String)
          : null,
      notes: map['notes'] as String?,
    );
  }

  CottonProcessingRegistry copyWith({
    int? id,
    int? linkedPurchaseId,
    DateTime? processingDate,
    String? notes,
  }) {
    return CottonProcessingRegistry(
      id: id ?? this.id,
      linkedPurchaseId: linkedPurchaseId ?? this.linkedPurchaseId,
      processingDate: processingDate ?? this.processingDate,
      notes: notes ?? this.notes,
    );
  }

  /// Validates processing registry data
  static String? validate({required int linkedPurchaseId}) {
    if (linkedPurchaseId <= 0) return 'Алоқаи хариди зарур аст';
    return null;
  }
}

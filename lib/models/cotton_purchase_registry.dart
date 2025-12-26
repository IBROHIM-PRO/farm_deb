/// Cotton Purchase Registry - Master Record
/// Groups all cotton types purchased in one transaction
class CottonPurchaseRegistry {
  final int? id;
  final DateTime purchaseDate;
  final String supplierName;        // Seller name
  final double transportationCost;  // Optional freight cost
  final String? notes;              // Optional purchase notes

  CottonPurchaseRegistry({
    this.id,
    required this.purchaseDate,
    required this.supplierName,
    this.transportationCost = 0,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchaseDate': purchaseDate.toIso8601String(),
      'supplierName': supplierName,
      'transportationCost': transportationCost,
      'notes': notes,
    };
  }

  factory CottonPurchaseRegistry.fromMap(Map<String, dynamic> map) {
    return CottonPurchaseRegistry(
      id: map['id'] as int?,
      purchaseDate: map['purchaseDate'] != null ? DateTime.parse(map['purchaseDate'] as String) : DateTime.now(),
      supplierName: map['supplierName'] as String? ?? '',
      transportationCost: (map['transportationCost'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
    );
  }

  CottonPurchaseRegistry copyWith({
    int? id,
    DateTime? purchaseDate,
    String? supplierName,
    double? transportationCost,
    String? notes,
  }) {
    return CottonPurchaseRegistry(
      id: id ?? this.id,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      supplierName: supplierName ?? this.supplierName,
      transportationCost: transportationCost ?? this.transportationCost,
      notes: notes ?? this.notes,
    );
  }

  /// Validates purchase registry data
  static String? validate({
    required String supplierName,
    required DateTime purchaseDate,
  }) {
    if (supplierName.trim().isEmpty) return 'Номи таъминкунанда зарур аст';
    return null;
  }
}

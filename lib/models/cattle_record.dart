enum RecordType { feeding, medication, weighing, vaccination, other }

/// Represents cattle care records including feeding, medication, and weighing
class CattleRecord {
  final int? id;
  final int cattleId;
  final RecordType type;
  final DateTime date;
  final double cost;
  final String currency;
  final String? description;
  
  // Feeding-specific fields
  final String? feedType;      // Hay, Grain, Concentrates, etc.
  final String? supplier;       // Feed supplier name
  
  // Medication-specific fields
  final String? medicineName;   // Name of medicine/vaccine
  final String? medicineType;   // Vaccine, Treatment, Supplement
  
  // General measurement fields
  final double? weight;         // For weighing records
  final double? quantity;       // Amount of feed/medicine
  final String? quantityUnit;   // kg, ml, dose, tablet, etc.
  
  // Monthly monitoring
  final int? monitoringMonth;   // Month number (1, 2, 3...) from purchase date

  CattleRecord({
    this.id,
    required this.cattleId,
    required this.type,
    required this.date,
    this.cost = 0,
    this.currency = 'TJS',
    this.description,
    this.feedType,
    this.supplier,
    this.medicineName,
    this.medicineType,
    this.weight,
    this.quantity,
    this.quantityUnit,
    this.monitoringMonth,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cattleId': cattleId,
      'type': type.name,
      'date': date.toIso8601String(),
      'cost': cost,
      'currency': currency,
      'description': description,
      'feedType': feedType,
      'supplier': supplier,
      'medicineName': medicineName,
      'medicineType': medicineType,
      'weight': weight,
      'quantity': quantity,
      'quantityUnit': quantityUnit,
      'monitoringMonth': monitoringMonth,
    };
  }

  factory CattleRecord.fromMap(Map<String, dynamic> map) {
    return CattleRecord(
      id: map['id'] as int?,
      cattleId: map['cattleId'] as int,
      type: RecordType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RecordType.other,
      ),
      date: DateTime.parse(map['date'] as String),
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'TJS',
      description: map['description'] as String?,
      feedType: map['feedType'] as String?,
      supplier: map['supplier'] as String?,
      medicineName: map['medicineName'] as String?,
      medicineType: map['medicineType'] as String?,
      weight: (map['weight'] as num?)?.toDouble(),
      quantity: (map['quantity'] as num?)?.toDouble(),
      quantityUnit: map['quantityUnit'] as String?,
      monitoringMonth: map['monitoringMonth'] as int?,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case RecordType.feeding: return 'Feeding';
      case RecordType.medication: return 'Medication';
      case RecordType.weighing: return 'Weighing';
      case RecordType.vaccination: return 'Vaccination';
      case RecordType.other: return 'Other';
    }
  }
  
  CattleRecord copyWith({
    int? id,
    int? cattleId,
    RecordType? type,
    DateTime? date,
    double? cost,
    String? currency,
    String? description,
    String? feedType,
    String? supplier,
    String? medicineName,
    String? medicineType,
    double? weight,
    double? quantity,
    String? quantityUnit,
    int? monitoringMonth,
  }) {
    return CattleRecord(
      id: id ?? this.id,
      cattleId: cattleId ?? this.cattleId,
      type: type ?? this.type,
      date: date ?? this.date,
      cost: cost ?? this.cost,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      feedType: feedType ?? this.feedType,
      supplier: supplier ?? this.supplier,
      medicineName: medicineName ?? this.medicineName,
      medicineType: medicineType ?? this.medicineType,
      weight: weight ?? this.weight,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      monitoringMonth: monitoringMonth ?? this.monitoringMonth,
    );
  }

  /// Validates record based on type
  static String? validate({
    required RecordType type,
    double? quantity,
    double? weight,
    String? feedType,
    String? medicineName,
  }) {
    if (type == RecordType.feeding) {
      if (quantity == null || quantity <= 0) return 'Feed quantity must be greater than zero';
      if (feedType == null || feedType.trim().isEmpty) return 'Feed type is required';
    }
    
    if (type == RecordType.medication || type == RecordType.vaccination) {
      if (medicineName == null || medicineName.trim().isEmpty) return 'Medicine name is required';
    }
    
    if (type == RecordType.weighing) {
      if (weight == null || weight <= 0) return 'Weight must be greater than zero';
    }
    
    return null;
  }
}

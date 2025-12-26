enum CattleStatus { active, sold, deceased }
enum CattleGender { male, female }
enum AgeCategory { calf, young, adult }  // Age classification
enum CattlePurchasePaymentStatus { pending, partial, paid }

/// Represents individual cattle with complete purchase and tracking information
class Cattle {
  final int? id;
  final String earTag;  // Unique identifier (mandatory)
  final String? name;
  final CattleGender gender;
  final AgeCategory ageCategory;  // Calf, Young, Adult
  final DateTime purchaseDate;
  final double purchasePrice;
  final String currency;
  final String? sellerName;  // Who sold the cattle
  final double freightCost;  // Transportation cost at purchase
  final double initialWeight;
  final double currentWeight;
  final String weightUnit;
  final CattleStatus status;
  final String? breed;
  final String? notes;
  // Payment tracking for installment purchases
  final CattlePurchasePaymentStatus purchasePaymentStatus;
  final double paidAmount;

  Cattle({
    this.id,
    required this.earTag,
    this.name,
    required this.gender,
    required this.ageCategory,
    required this.purchaseDate,
    required this.purchasePrice,
    this.currency = 'TJS',
    this.sellerName,
    this.freightCost = 0,
    required this.initialWeight,
    required this.currentWeight,
    this.weightUnit = 'kg',
    this.status = CattleStatus.active,
    this.breed,
    this.notes,
    this.purchasePaymentStatus = CattlePurchasePaymentStatus.paid,
    this.paidAmount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'earTag': earTag,
      'name': name,
      'gender': gender.name,
      'ageCategory': ageCategory.name,
      'purchaseDate': purchaseDate.toIso8601String(),
      'purchasePrice': purchasePrice,
      'currency': currency,
      'sellerName': sellerName,
      'freightCost': freightCost,
      'initialWeight': initialWeight,
      'currentWeight': currentWeight,
      'weightUnit': weightUnit,
      'status': status.name,
      'breed': breed,
      'notes': notes,
      'purchasePaymentStatus': purchasePaymentStatus.name,
      'paidAmount': paidAmount,
    };
  }

  factory Cattle.fromMap(Map<String, dynamic> map) {
    return Cattle(
      id: map['id'] as int?,
      earTag: map['earTag'] as String,
      name: map['name'] as String?,
      gender: CattleGender.values.firstWhere(
        (e) => e.name == map['gender'],
        orElse: () => CattleGender.male,
      ),
      ageCategory: AgeCategory.values.firstWhere(
        (e) => e.name == map['ageCategory'],
        orElse: () => AgeCategory.adult,
      ),
      purchaseDate: DateTime.parse(map['purchaseDate'] as String),
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'TJS',
      sellerName: map['sellerName'] as String?,
      freightCost: (map['freightCost'] as num?)?.toDouble() ?? 0,
      initialWeight: (map['initialWeight'] as num?)?.toDouble() ?? 0.0,
      currentWeight: (map['currentWeight'] as num?)?.toDouble() ?? 0.0,
      weightUnit: map['weightUnit'] as String? ?? 'kg',
      status: CattleStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CattleStatus.active,
      ),
      breed: map['breed'] as String?,
      notes: map['notes'] as String?,
      purchasePaymentStatus: CattlePurchasePaymentStatus.values.firstWhere(
        (e) => e.name == map['purchasePaymentStatus'],
        orElse: () => CattlePurchasePaymentStatus.paid,
      ),
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  Cattle copyWith({
    int? id,
    String? earTag,
    String? name,
    CattleGender? gender,
    AgeCategory? ageCategory,
    DateTime? purchaseDate,
    double? purchasePrice,
    String? currency,
    String? sellerName,
    double? freightCost,
    double? initialWeight,
    double? currentWeight,
    String? weightUnit,
    CattleStatus? status,
    String? breed,
    String? notes,
    CattlePurchasePaymentStatus? purchasePaymentStatus,
    double? paidAmount,
  }) {
    return Cattle(
      id: id ?? this.id,
      earTag: earTag ?? this.earTag,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      ageCategory: ageCategory ?? this.ageCategory,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currency: currency ?? this.currency,
      sellerName: sellerName ?? this.sellerName,
      freightCost: freightCost ?? this.freightCost,
      initialWeight: initialWeight ?? this.initialWeight,
      currentWeight: currentWeight ?? this.currentWeight,
      weightUnit: weightUnit ?? this.weightUnit,
      status: status ?? this.status,
      breed: breed ?? this.breed,
      notes: notes ?? this.notes,
      purchasePaymentStatus: purchasePaymentStatus ?? this.purchasePaymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
    );
  }

  double get weightGain => currentWeight - initialWeight;
  double get weightGainPercentage => (weightGain / initialWeight) * 100;
  
  /// Total purchase cost including freight
  double get totalPurchaseCost => purchasePrice + freightCost;
  
  /// Remaining amount to be paid for installment purchases
  double get remainingPurchaseAmount => purchasePrice - paidAmount;
  
  /// Age category display name
  String get ageCategoryDisplay {
    switch (ageCategory) {
      case AgeCategory.calf: return 'Calf';
      case AgeCategory.young: return 'Young';
      case AgeCategory.adult: return 'Adult';
    }
  }
  
  /// Validates cattle data
  static String? validate({
    required String earTag,
    required double purchasePrice,
    required double initialWeight,
  }) {
    if (earTag.trim().isEmpty) return 'Ear tag code is required';
    if (purchasePrice <= 0) return 'Purchase price must be greater than zero';
    if (initialWeight <= 0) return 'Initial weight must be greater than zero';
    return null;
  }
}

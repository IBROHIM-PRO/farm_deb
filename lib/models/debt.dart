enum DebtType { given, taken }
enum DebtStatus { active, repaid }

/// Debt Entity - Represents a loan or borrowed amount with a person
/// Exactly as specified in theoretical design
class Debt {
  final int? id;
  final int personId;           // Foreign key referencing Persons
  final double totalAmount;    // Original loan amount
  final double remainingAmount; // Outstanding balance (for partial repayment)
  final String currency;       // Currency type (TJS, USD, etc.)
  final DebtType type;         // "Given" or "Taken"
  final DateTime date;         // Date of debt creation
  final DebtStatus status;     // "Active" or "Repaid"

  Debt({
    this.id,
    required this.personId,
    required this.totalAmount,
    required this.remainingAmount,
    required this.currency,
    required this.type,
    required this.date,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personId': personId,
      'totalAmount': totalAmount,
      'remainingAmount': remainingAmount,
      'currency': currency,
      'type': type == DebtType.given ? 'Given' : 'Taken',
      'date': date.toIso8601String(),
      'status': status == DebtStatus.active ? 'Active' : 'Repaid',
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] as int?,
      personId: (map['personId'] as num?)?.toInt() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'сомонӣ',
      type: map['type'] == 'Given' ? DebtType.given : DebtType.taken,
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now(),
      status: map['status'] == 'Active' ? DebtStatus.active : DebtStatus.repaid,
    );
  }

  Debt copyWith({
    int? id,
    int? personId,
    double? totalAmount,
    double? remainingAmount,
    String? currency,
    DebtType? type,
    DateTime? date,
    DebtStatus? status,
  }) {
    return Debt(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }

  /// Debt type display name in Tajik
  String get typeDisplay {
    switch (type) {
      case DebtType.given: return 'Додашуда';
      case DebtType.taken: return 'Гирифташуда';
    }
  }

  /// Status display name in Tajik
  String get statusDisplay {
    switch (status) {
      case DebtStatus.active: return 'Фаъол';
      case DebtStatus.repaid: return 'Пардохт шуда';
    }
  }

  /// Calculate payment progress percentage (0-100)
  double get paymentProgress {
    if (totalAmount <= 0) return 0.0;
    return ((totalAmount - remainingAmount) / totalAmount * 100).clamp(0.0, 100.0);
  }

  /// Amount that has been paid so far
  double get paidAmount => totalAmount - remainingAmount;

  /// Check if debt is fully repaid
  bool get isFullyRepaid => remainingAmount <= 0 || status == DebtStatus.repaid;

  /// Core debt consolidation logic as specified in theoretical design
  /// If debt exists for same person, type, and currency - increase existing debt
  static Debt consolidate(Debt existing, double newAmount) {
    return existing.copyWith(
      totalAmount: existing.totalAmount + newAmount,
      remainingAmount: existing.remainingAmount + newAmount,
      date: DateTime.now(), // Update to current consolidation date
    );
  }

  /// Process partial repayment - core workflow from theoretical design
  /// Deduct payment from remainingAmount, mark as "Repaid" if balance reaches zero
  Debt processPayment(double paymentAmount) {
    if (paymentAmount <= 0) {
      throw ArgumentError('Маблағи пардохт бояд аз сифр зиёд бошад');
    }
    if (paymentAmount > remainingAmount) {
      throw ArgumentError('Маблағи пардохт наметавонад аз боқимонда зиёд бошад');
    }
    
    final newRemaining = remainingAmount - paymentAmount;
    return copyWith(
      remainingAmount: newRemaining,
      status: newRemaining <= 0 ? DebtStatus.repaid : DebtStatus.active,
    );
  }

  /// Check if this debt can be consolidated with another
  /// Same person, type, currency and both active
  bool canConsolidateWith(int otherPersonId, DebtType otherType, String otherCurrency) {
    return personId == otherPersonId &&
           type == otherType &&
           currency == otherCurrency &&
           status == DebtStatus.active;
  }

  /// Validates debt data according to theoretical design
  static String? validate({
    required double totalAmount,
    required String currency,
    required int personId,
  }) {
    if (totalAmount <= 0) return 'Маблағи қарз бояд аз сифр зиёд бошад';
    if (currency.trim().isEmpty) return 'Асъор зарур аст';
    if (personId <= 0) return 'Шахси нодуруст';
    return null;
  }
}

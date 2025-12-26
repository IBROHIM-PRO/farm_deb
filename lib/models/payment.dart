/// Simple Payment model matching database schema and theoretical design
class Payment {
  final int? id;
  final int debtId;
  final double amount;
  final DateTime date;
  final String? note;

  Payment({
    this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debtId': debtId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      debtId: (map['debtId'] as num?)?.toInt() ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null 
          ? DateTime.parse(map['date'] as String) 
          : DateTime.now(),
      note: map['note'] as String?,
    );
  }

  Payment copyWith({
    int? id,
    int? debtId,
    double? amount,
    DateTime? date,
    String? note,
  }) {
    return Payment(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  /// Get formatted payment date
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Simple validation for payment amount
  static String? validate(double amount) {
    if (amount <= 0) return 'Маблағи пардохт бояд аз сифр зиёд бошад';
    return null;
  }
}

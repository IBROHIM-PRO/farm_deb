class DailyExpense {
  final int? id;
  final String category;
  final String itemName;
  final double amount;
  final String currency;
  final DateTime expenseDate;
  final String? notes;

  DailyExpense({
    this.id,
    required this.category,
    required this.itemName,
    required this.amount,
    required this.currency,
    required this.expenseDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'itemName': itemName,
      'amount': amount,
      'currency': currency,
      'expenseDate': expenseDate.toIso8601String().split('T')[0],
      'notes': notes,
    };
  }

  factory DailyExpense.fromMap(Map<String, dynamic> map) {
    return DailyExpense(
      id: map['id'] as int?,
      category: map['category'] as String,
      itemName: map['itemName'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      expenseDate: DateTime.parse(map['expenseDate'] as String),
      notes: map['notes'] as String?,
    );
  }

  DailyExpense copyWith({
    int? id,
    String? category,
    String? itemName,
    double? amount,
    String? currency,
    DateTime? expenseDate,
    String? notes,
  }) {
    return DailyExpense(
      id: id ?? this.id,
      category: category ?? this.category,
      itemName: itemName ?? this.itemName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      expenseDate: expenseDate ?? this.expenseDate,
      notes: notes ?? this.notes,
    );
  }
}

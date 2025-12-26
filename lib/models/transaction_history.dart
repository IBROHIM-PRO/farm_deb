enum TransactionType {
  moneyGiven,      // Debt given
  moneyReceived,   // Debt taken, cotton sales, cattle sales
  moneyPaid,       // Payments made on debts
  goodsSold,       // Cotton, cattle sales
  goodsPurchased,  // Cattle purchases, cotton batches
  stockProcessed,  // Cotton processing
  stockDispatched, // Cotton dispatches
  activity,        // Field activities, cattle records
}

enum TransactionCategory {
  money,
  goods,
  stock,
  activity,
}

class TransactionHistory {
  final int? id;
  final DateTime date;
  final TransactionType type;
  final TransactionCategory category;
  final double? amount;
  final String? currency;
  final double? quantity;
  final String? quantityUnit;
  final String personName;           // Buyer, seller, person name
  final String? personPhone;
  final String description;          // Transaction description
  final String? notes;
  final String sourceTable;          // Original table name
  final int sourceId;               // Original record ID

  TransactionHistory({
    this.id,
    required this.date,
    required this.type,
    required this.category,
    this.amount,
    this.currency,
    this.quantity,
    this.quantityUnit,
    required this.personName,
    this.personPhone,
    required this.description,
    this.notes,
    required this.sourceTable,
    required this.sourceId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type.name,
      'category': category.name,
      'amount': amount,
      'currency': currency,
      'quantity': quantity,
      'quantityUnit': quantityUnit,
      'personName': personName,
      'personPhone': personPhone,
      'description': description,
      'notes': notes,
      'sourceTable': sourceTable,
      'sourceId': sourceId,
    };
  }

  factory TransactionHistory.fromMap(Map<String, dynamic> map) {
    return TransactionHistory(
      id: map['id'] as int?,
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.activity,
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TransactionCategory.activity,
      ),
      amount: (map['amount'] as num?)?.toDouble(),
      currency: map['currency'] as String?,
      quantity: (map['quantity'] as num?)?.toDouble(),
      quantityUnit: map['quantityUnit'] as String?,
      personName: map['personName'] as String,
      personPhone: map['personPhone'] as String?,
      description: map['description'] as String? ?? '',
      notes: map['notes'] as String?,
      sourceTable: map['sourceTable'] as String? ?? '',
      sourceId: (map['sourceId'] as num?)?.toInt() ?? 0,
    );
  }

  TransactionHistory copyWith({
    int? id,
    DateTime? date,
    TransactionType? type,
    TransactionCategory? category,
    double? amount,
    String? currency,
    double? quantity,
    String? quantityUnit,
    String? personName,
    String? personPhone,
    String? description,
    String? notes,
    String? sourceTable,
    int? sourceId,
  }) {
    return TransactionHistory(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      personName: personName ?? this.personName,
      personPhone: personPhone ?? this.personPhone,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      sourceTable: sourceTable ?? this.sourceTable,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.moneyGiven:
        return 'Money Given';
      case TransactionType.moneyReceived:
        return 'Money Received';
      case TransactionType.moneyPaid:
        return 'Payment Made';
      case TransactionType.goodsSold:
        return 'Goods Sold';
      case TransactionType.goodsPurchased:
        return 'Goods Purchased';
      case TransactionType.stockProcessed:
        return 'Stock Processed';
      case TransactionType.stockDispatched:
        return 'Stock Dispatched';
      case TransactionType.activity:
        return 'Activity';
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case TransactionCategory.money:
        return 'Money';
      case TransactionCategory.goods:
        return 'Goods';
      case TransactionCategory.stock:
        return 'Stock';
      case TransactionCategory.activity:
        return 'Activity';
    }
  }
}

class HistoryFilter {
  final DateTime? fromDate;
  final DateTime? toDate;
  final int? month;
  final int? year;
  final String? searchQuery;
  final TransactionCategory? category;
  final TransactionType? type;
  final String? currency;

  HistoryFilter({
    this.fromDate,
    this.toDate,
    this.month,
    this.year,
    this.searchQuery,
    this.category,
    this.type,
    this.currency,
  });

  HistoryFilter copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    int? month,
    int? year,
    String? searchQuery,
    TransactionCategory? category,
    TransactionType? type,
    String? currency,
  }) {
    return HistoryFilter(
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      month: month ?? this.month,
      year: year ?? this.year,
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      type: type ?? this.type,
      currency: currency ?? this.currency,
    );
  }
}

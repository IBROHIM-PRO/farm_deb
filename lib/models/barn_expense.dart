enum BarnExpenseType { feed, medication, water, other }

enum FeedType { press, karma }

/// Barn Expense Model - Barn-level costs
/// Tracks feed (fodder, press), water, medicine and other barn expenses
class BarnExpense {
  final int? id;
  final int barnId;               // Link to Barn
  final BarnExpenseType expenseType;
  final FeedType? feedType;       // Feed subtype (press/karma) - only for feed expenses
  final String itemName;          // Item name (fodder, medicine name, etc.)
  final double quantity;          // Quantity purchased
  final String quantityUnit;      // kg, liters, pieces, etc.
  final double pricePerUnit;      // Price per kg/liter/piece
  final double totalCost;         // Total cost
  final String currency;
  final String? supplier;         // Supplier name (optional)
  final DateTime expenseDate;
  final String? notes;

  BarnExpense({
    this.id,
    required this.barnId,
    required this.expenseType,
    this.feedType,
    required this.itemName,
    required this.quantity,
    required this.quantityUnit,
    required this.pricePerUnit,
    required this.totalCost,
    this.currency = 'TJS',
    this.supplier,
    required this.expenseDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barnId': barnId,
      'expenseType': expenseType.name,
      'feedType': feedType?.name,
      'itemName': itemName,
      'quantity': quantity,
      'quantityUnit': quantityUnit,
      'pricePerUnit': pricePerUnit,
      'totalCost': totalCost,
      'currency': currency,
      'supplier': supplier,
      'expenseDate': expenseDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory BarnExpense.fromMap(Map<String, dynamic> map) {
    return BarnExpense(
      id: map['id'] as int?,
      barnId: (map['barnId'] as num?)?.toInt() ?? 0,
      expenseType: BarnExpenseType.values.firstWhere(
        (e) => e.name == map['expenseType'],
        orElse: () => BarnExpenseType.other,
      ),
      feedType: map['feedType'] != null
          ? FeedType.values.firstWhere(
              (e) => e.name == map['feedType'],
              orElse: () => FeedType.karma,
            )
          : null,
      itemName: map['itemName'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      quantityUnit: map['quantityUnit'] as String? ?? '',
      pricePerUnit: (map['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'TJS',
      supplier: map['supplier'] as String?,
      expenseDate: map['expenseDate'] != null 
          ? DateTime.parse(map['expenseDate'] as String) 
          : DateTime.now(),
      notes: map['notes'] as String?,
    );
  }

  BarnExpense copyWith({
    int? id,
    int? barnId,
    BarnExpenseType? expenseType,
    FeedType? feedType,
    String? itemName,
    double? quantity,
    String? quantityUnit,
    double? pricePerUnit,
    double? totalCost,
    String? currency,
    String? supplier,
    DateTime? expenseDate,
    String? notes,
  }) {
    return BarnExpense(
      id: id ?? this.id,
      barnId: barnId ?? this.barnId,
      expenseType: expenseType ?? this.expenseType,
      feedType: feedType ?? this.feedType,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalCost: totalCost ?? this.totalCost,
      currency: currency ?? this.currency,
      supplier: supplier ?? this.supplier,
      expenseDate: expenseDate ?? this.expenseDate,
      notes: notes ?? this.notes,
    );
  }

  /// Expense type display in Tajik
  String get expenseTypeDisplay {
    switch (expenseType) {
      case BarnExpenseType.feed: return 'Хӯрок';
      case BarnExpenseType.medication: return 'Дово';
      case BarnExpenseType.water: return 'Об';
      case BarnExpenseType.other: return 'Дигар';
    }
  }

  /// Display formatted quantity with unit
  String get quantityDisplay => '${quantity.toStringAsFixed(1)} ${quantityUnit}';
  
  /// Feed type display in Tajik
  String get feedTypeDisplay {
    if (feedType == null) return '';
    switch (feedType!) {
      case FeedType.press: return 'Пресс';
      case FeedType.karma: return 'Корма';
    }
  }
}

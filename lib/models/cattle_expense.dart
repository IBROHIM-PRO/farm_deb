enum ExpenseType { feed, medication, other }

/// Cattle Expense Registry - All costs linked to cattle
/// Central expense tracking for feeding, medication, and other costs
class CattleExpense {
  final int? id;
  final int cattleId;          // Link to CattleRegistry
  final ExpenseType expenseType; // Feed/Medication/Other
  final String itemName;       // Feed type or medicine name
  final double quantity;       // kg for feed, units/doses for medicine
  final String quantityUnit;   // kg, units, doses, etc.
  final double cost;           // Total cost for this expense
  final String currency;
  final String? supplier;      // Supplier name (optional)
  final DateTime expenseDate;
  final String? notes;

  CattleExpense({
    this.id,
    required this.cattleId,
    required this.expenseType,
    required this.itemName,
    required this.quantity,
    required this.quantityUnit,
    required this.cost,
    this.currency = 'TJS',
    this.supplier,
    required this.expenseDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cattleId': cattleId,
      'expenseType': expenseType.name,
      'itemName': itemName,
      'quantity': quantity,
      'quantityUnit': quantityUnit,
      'cost': cost,
      'currency': currency,
      'supplier': supplier,
      'expenseDate': expenseDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory CattleExpense.fromMap(Map<String, dynamic> map) {
    return CattleExpense(
      id: map['id'] as int?,
      cattleId: (map['cattleId'] as num?)?.toInt() ?? 0,
      expenseType: ExpenseType.values.firstWhere(
        (e) => e.name == map['expenseType'],
        orElse: () => ExpenseType.feed,
      ),
      itemName: map['itemName'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      quantityUnit: map['quantityUnit'] as String? ?? '',
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'TJS',
      supplier: map['supplier'] as String?,
      expenseDate: map['expenseDate'] != null ? DateTime.parse(map['expenseDate'] as String) : DateTime.now(),
      notes: map['notes'] as String?,
    );
  }

  CattleExpense copyWith({
    int? id,
    int? cattleId,
    ExpenseType? expenseType,
    String? itemName,
    double? quantity,
    String? quantityUnit,
    double? cost,
    String? currency,
    String? supplier,
    DateTime? expenseDate,
    String? notes,
  }) {
    return CattleExpense(
      id: id ?? this.id,
      cattleId: cattleId ?? this.cattleId,
      expenseType: expenseType ?? this.expenseType,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      cost: cost ?? this.cost,
      currency: currency ?? this.currency,
      supplier: supplier ?? this.supplier,
      expenseDate: expenseDate ?? this.expenseDate,
      notes: notes ?? this.notes,
    );
  }

  /// Expense type display in Tajik
  String get expenseTypeDisplay {
    switch (expenseType) {
      case ExpenseType.feed: return 'Хӯрок';
      case ExpenseType.medication: return 'Дово';
      case ExpenseType.other: return 'Дигар';
    }
  }

  /// Cost per unit calculation
  double get costPerUnit => quantity > 0 ? cost / quantity : 0;

  /// Display formatted quantity with unit
  String get quantityDisplay => '${quantity.toStringAsFixed(1)} ${quantityUnit}';
}

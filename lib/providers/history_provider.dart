import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/transaction_history.dart';
import '../models/debt.dart';
import '../models/payment.dart';
import '../models/cotton_sale.dart';
import '../models/cattle_sale.dart';
import '../models/field_activity.dart';
import '../models/cattle_record.dart';
import '../models/cotton_batch.dart';
import '../models/cotton_dispatch.dart';
import '../models/person.dart';
import '../models/cattle.dart';

class HistoryProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  List<TransactionHistory> _allHistory = [];
  List<TransactionHistory> _filteredHistory = [];
  HistoryFilter _currentFilter = HistoryFilter();
  bool _isLoading = false;

  // Getters
  List<TransactionHistory> get allHistory => _allHistory;
  List<TransactionHistory> get filteredHistory => _filteredHistory;
  HistoryFilter get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;

  // Load all transaction history
  Future<void> loadAllHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allHistory = await _db.getAllTransactionHistory();
      _filteredHistory = List.from(_allHistory);
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  // Apply filters to transaction history
  Future<void> applyFilter(HistoryFilter filter) async {
    _isLoading = true;
    _currentFilter = filter;
    notifyListeners();
    
    try {
      _filteredHistory = await _db.getFilteredTransactionHistory(filter);
    } catch (e) {
      debugPrint('Error applying filter: $e');
      _filteredHistory = List.from(_allHistory);
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Clear all filters
  Future<void> clearFilter() async {
    _currentFilter = HistoryFilter();
    _filteredHistory = List.from(_allHistory);
    notifyListeners();
  }

  // Get history by category
  Future<List<TransactionHistory>> getHistoryByCategory(TransactionCategory category) async {
    return await _db.getTransactionHistoryByCategory(category);
  }

  // Search by person name
  Future<void> searchByPerson(String personName) async {
    if (personName.isEmpty) {
      await clearFilter();
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _filteredHistory = await _db.getTransactionHistoryByPerson(personName);
      _currentFilter = _currentFilter.copyWith(searchQuery: personName);
    } catch (e) {
      debugPrint('Error searching by person: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Helper methods for creating transaction history entries
  Future<void> addDebtHistory(Debt debt, Person person) async {
    final history = TransactionHistory(
      date: debt.date,
      type: debt.type == DebtType.given ? TransactionType.moneyGiven : TransactionType.moneyReceived,
      category: TransactionCategory.money,
      amount: debt.totalAmount,
      currency: debt.currency,
      personName: person.fullName,
      personPhone: person.phone,
      description: '${debt.type == DebtType.given ? 'Money given to' : 'Money received from'} ${person.fullName}',
      notes: null,
      sourceTable: 'debts',
      sourceId: debt.id!,
    );
    
    await _db.insertTransactionHistory(history);
    await loadAllHistory();
  }

  Future<void> addPaymentHistory(Payment payment, Debt debt, Person person) async {
    final history = TransactionHistory(
      date: payment.date,
      type: TransactionType.moneyPaid,
      category: TransactionCategory.money,
      amount: payment.amount,
      currency: debt.currency,
      personName: person.fullName,
      personPhone: person.phone,
      description: 'Payment ${debt.type == DebtType.given ? 'received from' : 'made to'} ${person.fullName}',
      notes: payment.note,
      sourceTable: 'payments',
      sourceId: payment.id!,
    );
    
    await _db.insertTransactionHistory(history);
    await loadAllHistory();
  }

  Future<void> addCottonSaleHistory(CottonSale sale) async {
    final history = TransactionHistory(
      date: sale.date,
      type: TransactionType.goodsSold,
      category: TransactionCategory.goods,
      amount: sale.totalAmount,
      currency: sale.currency,
      quantity: sale.weight,
      quantityUnit: sale.saleType == SaleType.byUnits ? '${sale.units} units' : 'kg',
      personName: sale.buyerName ?? 'Unknown Buyer',
      personPhone: sale.buyerPhone,
      description: 'Cotton sold to ${sale.buyerName ?? 'Unknown Buyer'}',
      notes: sale.notes,
      sourceTable: 'cotton_sales',
      sourceId: sale.id!,
    );
    
    await _db.insertTransactionHistory(history);
    await loadAllHistory();
  }

  Future<void> addCattleSaleHistory(CattleSale sale) async {
    final history = TransactionHistory(
      date: sale.saleDate,
      type: TransactionType.goodsSold,
      category: TransactionCategory.goods,
      amount: sale.totalAmount,
      currency: sale.currency,
      quantity: sale.weight,
      quantityUnit: 'kg',
      personName: sale.buyerName ?? 'Unknown Buyer',
      personPhone: sale.buyerPhone,
      description: 'Cattle sold to ${sale.buyerName ?? 'Unknown Buyer'} (${sale.saleType})',
      notes: sale.notes,
      sourceTable: 'cattle_sales',
      sourceId: sale.id!,
    );
    
    await _db.insertTransactionHistory(history);
    await loadAllHistory();
  }

  Future<void> addFieldActivityHistory(FieldActivity activity) async {
    final history = TransactionHistory(
      date: activity.date,
      type: TransactionType.activity,
      category: TransactionCategory.activity,
      amount: activity.cost,
      currency: activity.currency,
      personName: 'Field Operation',
      description: '${activity.type} - ${activity.description ?? 'Field activity'}',
      sourceTable: 'field_activities',
      sourceId: activity.id!,
    );
    
    await _db.insertTransactionHistory(history);
    await loadAllHistory();
  }

  Future<void> addCattleRecordHistory(CattleRecord record) async {
    final history = TransactionHistory(
      date: record.date,
      type: TransactionType.activity,
      category: TransactionCategory.activity,
      amount: record.cost,
      currency: record.currency,
      quantity: record.quantity,
      quantityUnit: record.quantityUnit,
      personName: record.supplier ?? 'Cattle Management',
      description: '${record.type} - ${record.description ?? 'Cattle care'}',
      sourceTable: 'cattle_records',
      sourceId: record.id!,
    );
    
    await _db.insertTransactionHistory(history);
    await loadAllHistory();
  }

  Future<void> addCottonBatchHistory(CottonBatch batch) async {
    final history = TransactionHistory(
      date: batch.arrivalDate,
      type: TransactionType.goodsPurchased,
      category: TransactionCategory.stock,
      amount: batch.totalCost,
      currency: 'TJS', // Default currency for cotton batches
      quantity: batch.weightKg,
      quantityUnit: 'kg (${batch.units} units)',
      personName: batch.source,
      description: 'Cotton batch purchased from ${batch.source}',
      sourceTable: 'cotton_batches',
      sourceId: batch.id!,
    );
    
    await _db.insertTransactionHistory(history);
    await loadAllHistory();
  }

  Future<void> addCottonDispatchHistory(CottonDispatch dispatch) async {
    final history = TransactionHistory(
      date: dispatch.dispatchDate,
      type: TransactionType.stockDispatched,
      category: TransactionCategory.stock,
      quantity: dispatch.weightKg,
      quantityUnit: 'kg (${dispatch.units} units)',
      personName: dispatch.destination,
      description: 'Cotton dispatched to ${dispatch.destination}',
      sourceTable: 'cotton_dispatches',
      sourceId: dispatch.id!,
    );
    
    await _db.insertTransactionHistory(history);
    await loadAllHistory();
  }

  Future<void> addCattlePurchaseHistory(Cattle cattle) async {
    final history = TransactionHistory(
      date: cattle.purchaseDate,
      type: TransactionType.goodsPurchased,
      category: TransactionCategory.goods,
      amount: cattle.purchasePrice,
      currency: cattle.currency,
      quantity: cattle.initialWeight,
      quantityUnit: 'kg',
      personName: cattle.sellerName ?? 'Cattle Purchase',
      description: 'Cattle purchased (${cattle.earTag}) - ${cattle.breed ?? 'Unknown breed'}',
      notes: cattle.notes,
      sourceTable: 'cattle',
      sourceId: cattle.id!,
    );
    
    await _db.insertTransactionHistory(history);
    await loadAllHistory();
  }

  // Remove history when source record is deleted
  Future<void> removeHistoryBySource(String sourceTable, int sourceId) async {
    await _db.deleteTransactionHistoryBySource(sourceTable, sourceId);
    await loadAllHistory();
  }

  // Get summary statistics
  Future<Map<String, dynamic>> getTransactionSummary() async {
    return await _db.getTransactionSummaryByCategory();
  }

  Future<Map<String, dynamic>> getMonthlyTransactionSummary(int year) async {
    return await _db.getMonthlyTransactionSummary(year);
  }

  // Get unique currencies from history
  List<String> get availableCurrencies {
    final currencies = _allHistory
        .where((h) => h.currency != null && h.currency!.isNotEmpty)
        .map((h) => h.currency!)
        .toSet()
        .toList();
    currencies.sort();
    return currencies;
  }

  // Get unique person names from history
  List<String> get availablePersons {
    final persons = _allHistory
        .map((h) => h.personName)
        .toSet()
        .toList();
    persons.sort();
    return persons;
  }

  // Get available years from history
  List<int> get availableYears {
    final years = _allHistory
        .map((h) => h.date.year)
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a)); // Descending order
    return years;
  }

  // Get monthly totals for a specific year and category
  Map<int, double> getMonthlyTotals(int year, TransactionCategory? category) {
    final monthlyTotals = <int, double>{};
    
    final yearHistory = _allHistory.where((h) => 
      h.date.year == year && 
      (category == null || h.category == category)
    );
    
    for (final history in yearHistory) {
      final month = history.date.month;
      monthlyTotals[month] = (monthlyTotals[month] ?? 0.0) + (history.amount ?? 0.0);
    }
    
    return monthlyTotals;
  }
}

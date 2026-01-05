import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/daily_expense.dart';

class DailyExpenseProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  List<DailyExpense> _expenses = [];
  List<DailyExpense> _todayExpenses = [];
  bool _isLoading = false;
  String? _error;

  List<DailyExpense> get expenses => _expenses;
  List<DailyExpense> get todayExpenses => _todayExpenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DailyExpenseProvider() {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final expensesData = await _dbHelper.getAllDailyExpenses();
      _expenses = expensesData.map((m) => DailyExpense.fromMap(m)).toList();
      
      await loadTodayExpenses();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTodayExpenses() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final expensesData = await _dbHelper.getDailyExpensesByDate(today);
      _todayExpenses = expensesData.map((m) => DailyExpense.fromMap(m)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addExpense(DailyExpense expense) async {
    try {
      await _dbHelper.insertDailyExpense(expense.toMap());
      await loadExpenses();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpense(DailyExpense expense) async {
    try {
      await _dbHelper.updateDailyExpense(expense.id!, expense.toMap());
      await loadExpenses();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await _dbHelper.deleteDailyExpense(id);
      await loadExpenses();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  double getTotalExpensesForToday() {
    return _todayExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> getExpensesByCategory() {
    final Map<String, double> categoryTotals = {};
    for (var expense in _expenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    return categoryTotals;
  }
}

import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/barn.dart';
import '../models/barn_expense.dart';

class BarnProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  List<Barn> _barns = [];
  Map<int, List<BarnExpense>> _barnExpenses = {};
  Map<int, int> _cattleCountPerBarn = {};
  bool _isLoading = false;
  String? _error;

  List<Barn> get barns => _barns;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BarnProvider() {
    loadBarns();
  }

  Future<void> loadBarns() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _barns = await _dbHelper.getAllBarns();
      
      // Load cattle count for each barn
      for (var barn in _barns) {
        if (barn.id != null) {
          _cattleCountPerBarn[barn.id!] = await _dbHelper.getCattleCountInBarn(barn.id!);
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBarn(Barn barn) async {
    try {
      final id = await _dbHelper.insertBarn(barn);
      await loadBarns();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateBarn(Barn barn) async {
    try {
      await _dbHelper.updateBarn(barn);
      await loadBarns();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteBarn(int id) async {
    try {
      await _dbHelper.deleteBarn(id);
      await loadBarns();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Barn? getBarnById(int? barnId) {
    if (barnId == null) return null;
    try {
      return _barns.firstWhere((barn) => barn.id == barnId);
    } catch (e) {
      return null;
    }
  }

  int getCattleCount(int barnId) {
    return _cattleCountPerBarn[barnId] ?? 0;
  }

  bool isAtCapacity(int barnId) {
    final barn = getBarnById(barnId);
    if (barn?.capacity == null) return false;
    final count = getCattleCount(barnId);
    return count >= barn!.capacity!;
  }

  // Barn Expense Operations
  Future<void> loadBarnExpenses(int barnId) async {
    try {
      final expenses = await _dbHelper.getBarnExpensesByBarnId(barnId);
      _barnExpenses[barnId] = expenses;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<BarnExpense> getBarnExpenses(int barnId) {
    return _barnExpenses[barnId] ?? [];
  }

  Future<void> addBarnExpense(BarnExpense expense) async {
    try {
      await _dbHelper.insertBarnExpense(expense);
      await loadBarnExpenses(expense.barnId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateBarnExpense(BarnExpense expense) async {
    try {
      await _dbHelper.updateBarnExpense(expense);
      await loadBarnExpenses(expense.barnId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteBarnExpense(int id, int barnId) async {
    try {
      await _dbHelper.deleteBarnExpense(id);
      await loadBarnExpenses(barnId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<double> getTotalBarnExpenses(int barnId) async {
    try {
      return await _dbHelper.getTotalBarnExpenses(barnId);
    } catch (e) {
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> getBarnExpensesByType(int barnId) async {
    try {
      return await _dbHelper.getBarnExpensesByType(barnId);
    } catch (e) {
      return {'expensesByType': []};
    }
  }

  // Summary Statistics
  Map<String, dynamic> getBarnSummary(int barnId) {
    final barn = getBarnById(barnId);
    final cattleCount = getCattleCount(barnId);
    final expenses = getBarnExpenses(barnId);
    final totalExpenses = expenses.fold<double>(
      0.0, 
      (sum, expense) => sum + expense.totalCost
    );

    return {
      'barn': barn,
      'cattleCount': cattleCount,
      'capacity': barn?.capacity,
      'isAtCapacity': isAtCapacity(barnId),
      'totalExpenses': totalExpenses,
      'expenseCount': expenses.length,
    };
  }

  Map<String, dynamic> get overallStatistics {
    final totalBarns = _barns.length;
    final totalCattle = _cattleCountPerBarn.values.fold<int>(0, (sum, count) => sum + count);
    
    return {
      'totalBarns': totalBarns,
      'totalCattle': totalCattle,
      'averageCattlePerBarn': totalBarns > 0 ? (totalCattle / totalBarns).toStringAsFixed(1) : '0',
    };
  }
}

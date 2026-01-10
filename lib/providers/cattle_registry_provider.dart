import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/cattle_registry.dart';
import '../models/cattle_purchase.dart';
import '../models/cattle_expense.dart';
import '../models/cattle_weight.dart';
import '../models/cattle_sale.dart';

/// Cattle Registry Provider - Registry-based cattle management
/// Handles all cattle operations following the Registry design pattern
class CattleRegistryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  List<CattleRegistry> _cattleRegistry = [];
  List<CattlePurchase> _cattlePurchases = [];
  List<CattleExpense> _cattleExpenses = [];
  List<CattleWeight> _cattleWeights = [];
  List<CattleSale> _cattleSales = [];
  
  bool _isLoading = false;

  // Getters
  List<CattleRegistry> get cattleRegistry => _cattleRegistry;
  List<CattleRegistry> get allCattle => _cattleRegistry; // Alias for screens
  List<CattlePurchase> get cattlePurchases => _cattlePurchases;
  List<CattleExpense> get cattleExpenses => _cattleExpenses;
  List<CattleWeight> get cattleWeights => _cattleWeights;
  List<CattleSale> get cattleSales => _cattleSales;
  bool get isLoading => _isLoading;

  /// Load all cattle registry data
  Future<void> loadAllData() async {
    _setLoading(true);
    try {
      await Future.wait([
        loadCattleRegistry(),
        loadCattlePurchases(),
        loadCattleExpenses(),
        loadCattleWeights(),
        loadCattleSales(),
      ]);
      debugPrint('✅ CattleRegistryProvider loaded successfully');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ============ CATTLE REGISTRY OPERATIONS ============

  /// Load cattle registry (master records only)
  Future<void> loadCattleRegistry() async {
    final db = await _dbHelper.database;
    final maps = await db.query('cattle_registry', orderBy: 'registrationDate DESC');
    _cattleRegistry = maps.map((map) => CattleRegistry.fromMap(map)).toList();
    notifyListeners();
  }

  /// Add new cattle to registry
  Future<int> addCattleToRegistry(CattleRegistry cattle) async {
    final db = await _dbHelper.database;
    final id = await db.insert('cattle_registry', cattle.toMap());
    await loadCattleRegistry();
    debugPrint('✅ Database automatically refreshed after cattle registry addition');
    return id;
  }

  /// Update cattle in registry
  Future<void> updateCattleInRegistry(CattleRegistry cattle) async {
    final db = await _dbHelper.database;
    await db.update(
      'cattle_registry',
      cattle.toMap(),
      where: 'id = ?',
      whereArgs: [cattle.id],
    );
    await loadCattleRegistry();
  }

  /// Alias for updateCattleInRegistry
  Future<void> updateCattle(CattleRegistry cattle) async {
    return updateCattleInRegistry(cattle);
  }

  /// Delete cattle from registry (and all linked data)
  Future<void> deleteCattleFromRegistry(int cattleId) async {
    final db = await _dbHelper.database;
    await db.delete('cattle_registry', where: 'id = ?', whereArgs: [cattleId]);
    await loadAllData(); // Reload all data as linked records are deleted
  }

  /// Get cattle by ID
  CattleRegistry? getCattleById(int cattleId) {
    return _cattleRegistry.where((c) => c.id == cattleId).firstOrNull;
  }

  /// Check if ear tag already exists
  bool isEarTagExists(String earTag, {int? excludeId}) {
    return _cattleRegistry.any((c) => 
      c.earTag.toLowerCase() == earTag.toLowerCase() && 
      (excludeId == null || c.id != excludeId)
    );
  }

  /// Get active cattle only
  List<CattleRegistry> get activeCattle => 
      _cattleRegistry.where((cattle) => cattle.status == CattleStatus.active).toList();

  /// Get sold cattle only
  List<CattleRegistry> get soldCattle => 
      _cattleRegistry.where((cattle) => cattle.status == CattleStatus.sold).toList();

  // ============ CATTLE PURCHASE OPERATIONS ============

  /// Load cattle purchases
  Future<void> loadCattlePurchases() async {
    final db = await _dbHelper.database;
    final maps = await db.query('cattle_purchases', orderBy: 'purchaseDate DESC');
    _cattlePurchases = maps.map((map) => CattlePurchase.fromMap(map)).toList();
    notifyListeners();
  }

  /// Add cattle purchase
  Future<int> addCattlePurchase(CattlePurchase purchase) async {
    final db = await _dbHelper.database;
    final id = await db.insert('cattle_purchases', purchase.toMap());
    await loadCattlePurchases();
    debugPrint('✅ Database automatically refreshed after cattle purchase');
    return id;
  }

  /// Get purchase for specific cattle
  CattlePurchase? getPurchaseForCattle(int cattleId) {
    return _cattlePurchases.where((p) => p.cattleId == cattleId).firstOrNull;
  }

  /// Get purchases list for specific cattle (returns as list for compatibility)
  List<CattlePurchase> getCattlePurchases(int cattleId) {
    final purchase = getPurchaseForCattle(cattleId);
    return purchase != null ? [purchase] : [];
  }

  // ============ CATTLE EXPENSE OPERATIONS ============

  /// Load cattle expenses
  Future<void> loadCattleExpenses() async {
    final db = await _dbHelper.database;
    final maps = await db.query('cattle_expenses', orderBy: 'expenseDate DESC');
    _cattleExpenses = maps.map((map) => CattleExpense.fromMap(map)).toList();
    notifyListeners();
  }

  /// Add cattle expense
  Future<int> addCattleExpense(CattleExpense expense) async {
    final db = await _dbHelper.database;
    final id = await db.insert('cattle_expenses', expense.toMap());
    await loadCattleExpenses();
    debugPrint('✅ Database automatically refreshed after cattle expense');
    return id;
  }

  /// Get expenses for specific cattle
  List<CattleExpense> getExpensesForCattle(int cattleId) {
    return _cattleExpenses.where((e) => e.cattleId == cattleId).toList();
  }

  /// Alias for screens
  List<CattleExpense> getCattleExpenses(int cattleId) {
    return getExpensesForCattle(cattleId);
  }

  /// Get total expenses for cattle
  double getTotalExpensesForCattle(int cattleId) {
    return getExpensesForCattle(cattleId).fold(0.0, (sum, expense) => sum + expense.cost);
  }

  /// Get expenses by type for cattle
  List<CattleExpense> getExpensesByType(int cattleId, ExpenseType type) {
    return getExpensesForCattle(cattleId).where((e) => e.expenseType == type).toList();
  }

  // ============ CATTLE WEIGHT OPERATIONS ============

  /// Load cattle weights
  Future<void> loadCattleWeights() async {
    final db = await _dbHelper.database;
    final maps = await db.query('cattle_weights', orderBy: 'measurementDate DESC');
    _cattleWeights = maps.map((map) => CattleWeight.fromMap(map)).toList();
    notifyListeners();
  }

  /// Add cattle weight measurement
  Future<int> addCattleWeight(CattleWeight weight) async {
    final db = await _dbHelper.database;
    final id = await db.insert('cattle_weights', weight.toMap());
    await loadCattleWeights();
    debugPrint('✅ Database automatically refreshed after cattle weight measurement');
    return id;
  }

  /// Delete cattle weight
  Future<void> deleteCattleWeight(int weightId) async {
    final db = await _dbHelper.database;
    await db.delete('cattle_weights', where: 'id = ?', whereArgs: [weightId]);
    await loadCattleWeights();
    debugPrint('✅ Cattle weight deleted');
  }

  /// Get weights for specific cattle
  List<CattleWeight> getWeightsForCattle(int cattleId) {
    return _cattleWeights.where((w) => w.cattleId == cattleId).toList()
        ..sort((a, b) => a.measurementDate.compareTo(b.measurementDate));
  }

  /// Alias for screens
  List<CattleWeight> getCattleWeights(int cattleId) {
    return getWeightsForCattle(cattleId);
  }

  /// Get latest weight for cattle
  CattleWeight? getLatestWeightForCattle(int cattleId) {
    final weights = getWeightsForCattle(cattleId);
    return weights.isNotEmpty ? weights.last : null;
  }

  /// Calculate weight gain for cattle
  double? getWeightGainForCattle(int cattleId) {
    final purchase = getPurchaseForCattle(cattleId);
    final latestWeight = getLatestWeightForCattle(cattleId);
    
    if (purchase != null && latestWeight != null) {
      return latestWeight.weight - purchase.weightAtPurchase;
    }
    return null;
  }

  // ============ CATTLE SALE OPERATIONS ============

  /// Load cattle sales
  Future<void> loadCattleSales() async {
    final db = await _dbHelper.database;
    final maps = await db.query('cattle_sales', orderBy: 'date DESC');
    _cattleSales = maps.map((map) => CattleSale.fromMap(map)).toList();
    notifyListeners();
  }

  /// Add cattle sale (and mark cattle as sold)
  Future<int> sellCattle(CattleSale sale) async {
    final db = await _dbHelper.database;
    
    // Start transaction to ensure data consistency
    return await db.transaction((txn) async {
      // Add sale record
      final saleId = await txn.insert('cattle_sales', sale.toMap());
      
      // Mark cattle as sold in registry
      await txn.update(
        'cattle_registry',
        {'status': CattleStatus.sold.name},
        where: 'id = ?',
        whereArgs: [sale.cattleId],
      );
      
      return saleId;
    });
  }

  /// Get sale for specific cattle
  CattleSale? getSaleForCattle(int cattleId) {
    return _cattleSales.where((s) => s.cattleId == cattleId).firstOrNull;
  }

  /// Get sales list for specific cattle (returns as list for compatibility)
  List<CattleSale> getCattleSales(int cattleId) {
    final sale = getSaleForCattle(cattleId);
    return sale != null ? [sale] : [];
  }

  // ============ ANALYTICS & REPORTING ============

  /// Get complete cattle summary including all events
  Map<String, dynamic> getCattleSummary(int cattleId) {
    final registry = _cattleRegistry.where((c) => c.id == cattleId).firstOrNull;
    final purchase = getPurchaseForCattle(cattleId);
    final expenses = getExpensesForCattle(cattleId);
    final weights = getWeightsForCattle(cattleId);
    final sale = getSaleForCattle(cattleId);
    
    final totalExpenses = getTotalExpensesForCattle(cattleId);
    final purchaseCost = purchase?.totalCost ?? 0;
    final saleRevenue = sale?.totalAmount ?? 0;
    final profit = saleRevenue - purchaseCost - totalExpenses;
    
    return {
      'registry': registry,
      'purchase': purchase,
      'totalExpenses': totalExpenses,
      'expenseCount': expenses.length,
      'weightRecords': weights.length,
      'latestWeight': getLatestWeightForCattle(cattleId),
      'weightGain': getWeightGainForCattle(cattleId),
      'sale': sale,
      'profit': profit,
      'isComplete': sale != null,
    };
  }

  /// Get overall cattle statistics
  Map<String, dynamic> get overallStatistics {
    final activeCattleCount = activeCattle.length;
    final soldCattleCount = soldCattle.length;
    final totalPurchaseCost = _cattlePurchases.fold(0.0, (sum, p) => sum + p.totalCost);
    final totalExpenses = _cattleExpenses.fold(0.0, (sum, e) => sum + e.cost);
    final totalSalesRevenue = _cattleSales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final totalProfit = totalSalesRevenue - totalPurchaseCost - totalExpenses;
    
    return {
      'totalCattle': _cattleRegistry.length,
      'activeCattle': activeCattleCount,
      'soldCattle': soldCattleCount,
      'totalPurchaseCost': totalPurchaseCost,
      'totalExpenses': totalExpenses,
      'totalSalesRevenue': totalSalesRevenue,
      'totalProfit': totalProfit,
      'averageProfitPerCattle': soldCattleCount > 0 ? totalProfit / soldCattleCount : 0,
    };
  }
}

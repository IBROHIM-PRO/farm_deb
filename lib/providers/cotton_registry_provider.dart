import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/cotton_purchase_registry.dart';
import '../models/cotton_purchase_item.dart';
import '../models/cotton_processing_registry.dart';
import '../models/cotton_processing_input.dart';
import '../models/cotton_processing_output.dart';
import '../models/cotton_processing_calculator.dart';
import '../models/cotton_inventory.dart';
import '../models/cotton_sale_registry.dart';
import '../models/cotton_traceability.dart';

/// Cotton Registry Provider - Registry-based cotton management
/// Handles the complete cotton workflow: Purchase → Processing → Inventory → Sales
class CottonRegistryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  List<CottonPurchaseRegistry> _purchaseRegistry = [];
  List<CottonPurchaseItem> _purchaseItems = [];
  List<CottonProcessingRegistry> _processingRegistry = [];
  List<CottonProcessingInput> _processingInputs = [];
  List<CottonProcessingOutput> _processingOutputs = [];
  List<CottonInventory> _cottonInventory = [];
  List<CottonSaleRegistry> _saleRegistry = [];
  List<CottonTraceability> _traceability = [];
  
  bool _isLoading = false;

  // Getters
  List<CottonPurchaseRegistry> get purchaseRegistry => _purchaseRegistry;
  List<CottonPurchaseItem> get purchaseItems => _purchaseItems;
  List<CottonProcessingRegistry> get processingRegistry => _processingRegistry;
  List<CottonProcessingInput> get processingInputs => _processingInputs;
  List<CottonProcessingOutput> get processingOutputs => _processingOutputs;
  List<CottonInventory> get cottonInventory => _cottonInventory;
  List<CottonSaleRegistry> get saleRegistry => _saleRegistry;
  List<CottonTraceability> get traceability => _traceability;
  bool get isLoading => _isLoading;

  /// Load all cotton registry data
  Future<void> loadAllData() async {
    _setLoading(true);
    try {
      await Future.wait([
        loadPurchaseRegistry(),
        loadPurchaseItems(),
        loadProcessingRegistry(),
        loadProcessingInputs(),
        loadProcessingOutputs(),
        loadCottonInventory(),
        loadSaleRegistry(),
        loadTraceability(),
      ]);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ============ COTTON PURCHASE REGISTRY OPERATIONS ============

  /// Load cotton purchase registry (master records)
  Future<void> loadPurchaseRegistry() async {
    final db = await _dbHelper.database;
    final maps = await db.query('cotton_purchase_registry', orderBy: 'purchaseDate DESC');
    _purchaseRegistry = maps.map((map) => CottonPurchaseRegistry.fromMap(map)).toList();
    notifyListeners();
  }

  /// Load cotton purchase items (detailed items)
  Future<void> loadPurchaseItems() async {
    final db = await _dbHelper.database;
    final maps = await db.query('cotton_purchase_items', orderBy: 'id ASC');
    _purchaseItems = maps.map((map) => CottonPurchaseItem.fromMap(map)).toList();
    notifyListeners();
  }

  /// Add complete cotton purchase (master + items)
  Future<int> addCottonPurchase({
    required CottonPurchaseRegistry registry,
    required List<CottonPurchaseItem> items,
  }) async {
    final db = await _dbHelper.database;
    
    return await db.transaction((txn) async {
      // Add master purchase record
      final purchaseId = await txn.insert('cotton_purchase_registry', registry.toMap());
      
      // Add all cotton type items
      for (final item in items) {
        final itemWithPurchaseId = item.copyWith(purchaseId: purchaseId);
        await txn.insert('cotton_purchase_items', itemWithPurchaseId.toMap());
        
        // Create traceability record for each cotton type
        final traceabilityCode = CottonTraceability.generateTraceabilityCode(
          item.cottonType, 
          registry.purchaseDate
        );
        
        final traceability = CottonTraceability(
          cottonType: item.cottonType,
          traceabilityCode: traceabilityCode,
          purchaseId: purchaseId,
          purchaseDate: registry.purchaseDate,
          supplierName: registry.supplierName,
          originalWeight: item.weight,
          originalUnits: item.units.toDouble(),
        );
        
        await txn.insert('cotton_traceability', traceability.toMap());
      }
      
      return purchaseId;
    });
  }

  /// Get purchase items for specific purchase
  List<CottonPurchaseItem> getItemsForPurchase(int purchaseId) {
    return _purchaseItems.where((item) => item.purchaseId == purchaseId).toList();
  }

  /// Get purchase summary with items
  Map<String, dynamic> getPurchaseSummary(int purchaseId) {
    final registry = _purchaseRegistry.where((p) => p.id == purchaseId).firstOrNull;
    final items = getItemsForPurchase(purchaseId);
    final totalWeight = items.fold(0.0, (sum, item) => sum + item.weight);
    final totalUnits = items.fold(0, (sum, item) => sum + item.units);
    final totalCost = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final grandTotal = totalCost + (registry?.transportationCost ?? 0);
    
    return {
      'registry': registry,
      'items': items,
      'totalWeight': totalWeight,
      'totalUnits': totalUnits,
      'totalCost': totalCost,
      'grandTotal': grandTotal,
    };
  }

  // ============ COTTON PROCESSING OPERATIONS ============

  /// Load cotton processing registry
  Future<void> loadProcessingRegistry() async {
    final db = await _dbHelper.database;
    final maps = await db.query('cotton_processing_registry', orderBy: 'id DESC');
    _processingRegistry = maps.map((map) => CottonProcessingRegistry.fromMap(map)).toList();
    notifyListeners();
  }

  /// Load cotton processing inputs
  Future<void> loadProcessingInputs() async {
    final db = await _dbHelper.database;
    final maps = await db.query('cotton_processing_inputs', orderBy: 'id ASC');
    _processingInputs = maps.map((map) => CottonProcessingInput.fromMap(map)).toList();
    notifyListeners();
  }

  /// Load cotton processing outputs
  Future<void> loadProcessingOutputs() async {
    final db = await _dbHelper.database;
    final maps = await db.query('cotton_processing_outputs', orderBy: 'id ASC');
    _processingOutputs = maps.map((map) => CottonProcessingOutput.fromMap(map)).toList();
    notifyListeners();
  }

  /// Add complete cotton processing operation
  Future<int> addCottonProcessing({
    required CottonProcessingRegistry registry,
    required List<CottonProcessingInput> inputs,
    required List<CottonProcessingOutput> outputs,
  }) async {
    final db = await _dbHelper.database;
    
    return await db.transaction((txn) async {
      // Add master processing record
      final processingId = await txn.insert('cotton_processing_registry', registry.toMap());
      
      // Add processing inputs
      for (final input in inputs) {
        final inputWithProcessingId = input.copyWith(processingId: processingId);
        await txn.insert('cotton_processing_inputs', inputWithProcessingId.toMap());
        
        // Update purchase item remaining stock
        await _deductFromPurchaseItem(txn, input.sourcePurchaseItemId, input.unitsUsed);
      }
      
      // Add processing outputs and create inventory
      for (final output in outputs) {
        final outputWithProcessingId = output.copyWith(processingId: processingId);
        await txn.insert('cotton_processing_outputs', outputWithProcessingId.toMap());
        
        // Create or update inventory
        await _addToInventory(txn, output.cottonType, output.batchWeightPerUnit, 
                              output.numberOfUnits, processingId);
      }
      
      // Update traceability
      await _updateTraceabilityForProcessing(txn, registry.linkedPurchaseId, 
                                           processingId, inputs, outputs);
      
      return processingId;
    });
  }

  /// Deduct units from purchase item (internal method)
  Future<void> _deductFromPurchaseItem(Transaction txn, int purchaseItemId, int unitsUsed) async {
    // This would normally update a remaining stock field in purchase items
    // For now, we track this through processing inputs
  }

  /// Add processed cotton to inventory
  Future<void> _addToInventory(Transaction txn, CottonType cottonType, 
                              double batchSize, int units, int processingId) async {
    // Check if inventory record exists for this cotton type and batch size
    final existing = await txn.query(
      'cotton_inventory',
      where: 'cottonType = ? AND batchSize = ? AND sourceProcessingId = ?',
      whereArgs: [cottonType.name, batchSize, processingId],
    );
    
    if (existing.isNotEmpty) {
      // Update existing inventory
      final currentUnits = existing.first['availableUnits'] as int;
      final newUnits = currentUnits + units;
      final newTotalWeight = CottonInventory.calculateTotalWeight(batchSize, newUnits);
      
      await txn.update(
        'cotton_inventory',
        {
          'availableUnits': newUnits,
          'totalWeight': newTotalWeight,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      // Create new inventory record
      final inventory = CottonInventory(
        cottonType: cottonType,
        batchSize: batchSize,
        availableUnits: units,
        totalWeight: CottonInventory.calculateTotalWeight(batchSize, units),
        sourceProcessingId: processingId,
      );
      
      await txn.insert('cotton_inventory', inventory.toMap());
    }
  }

  /// Update traceability for processing
  Future<void> _updateTraceabilityForProcessing(
    Transaction txn, 
    int purchaseId, 
    int processingId,
    List<CottonProcessingInput> inputs,
    List<CottonProcessingOutput> outputs,
  ) async {
    // Update traceability records for processed cotton types
    for (final input in inputs) {
      await txn.update(
        'cotton_traceability',
        {
          'processingId': processingId,
          'processingDate': DateTime.now().toIso8601String(),
          'processedWeight': input.weightUsed,
          'processedUnits': input.unitsUsed.toDouble(),
          'status': TraceabilityStatus.processed.name,
        },
        where: 'purchaseId = ? AND cottonType = ?',
        whereArgs: [purchaseId, input.cottonType.name],
      );
    }
  }

  // ============ COTTON INVENTORY OPERATIONS ============

  /// Load cotton inventory
  Future<void> loadCottonInventory() async {
    final db = await _dbHelper.database;
    final maps = await db.query('cotton_inventory', orderBy: 'cottonType, batchSize');
    _cottonInventory = maps.map((map) => CottonInventory.fromMap(map)).toList();
    notifyListeners();
  }

  /// Get available inventory by cotton type
  List<CottonInventory> getInventoryByType(CottonType type) {
    return _cottonInventory.where((inv) => inv.cottonType == type && !inv.isEmpty).toList();
  }

  /// Get inventory for specific batch
  CottonInventory? getInventoryForBatch(CottonType type, double batchSize) {
    return _cottonInventory.where((inv) => 
      inv.cottonType == type && 
      inv.batchSize == batchSize && 
      !inv.isEmpty
    ).firstOrNull;
  }

  // ============ COTTON SALES OPERATIONS ============

  /// Load cotton sale registry
  Future<void> loadSaleRegistry() async {
    final db = await _dbHelper.database;
    final maps = await db.query('cotton_sale_registry', orderBy: 'saleDate DESC');
    _saleRegistry = maps.map((map) => CottonSaleRegistry.fromMap(map)).toList();
    notifyListeners();
  }

  /// Add cotton sale with automatic inventory deduction
  Future<int> sellCotton(CottonSaleRegistry sale) async {
    final db = await _dbHelper.database;
    
    return await db.transaction((txn) async {
      // Validate inventory availability
      final inventory = await txn.query(
        'cotton_inventory',
        where: 'id = ?',
        whereArgs: [sale.sourceInventoryId],
      );
      
      if (inventory.isEmpty) {
        throw Exception('Инвентори ёфт нашуд');
      }
      
      final currentUnits = inventory.first['availableUnits'] as int;
      if (currentUnits < sale.unitsSold) {
        throw Exception('Дар анбор кофӣ нест');
      }
      
      // Add sale record
      final saleId = await txn.insert('cotton_sale_registry', sale.toMap());
      
      // Deduct from inventory
      final newUnits = currentUnits - sale.unitsSold;
      final newTotalWeight = CottonInventory.calculateTotalWeight(sale.batchSize, newUnits);
      
      await txn.update(
        'cotton_inventory',
        {
          'availableUnits': newUnits,
          'totalWeight': newTotalWeight,
        },
        where: 'id = ?',
        whereArgs: [sale.sourceInventoryId],
      );
      
      // Update traceability to mark as sold
      await txn.update(
        'cotton_traceability',
        {
          'saleId': saleId,
          'saleDate': sale.saleDate.toIso8601String(),
          'buyerName': sale.buyerName,
          'soldWeight': sale.weightSold,
          'soldUnits': sale.unitsSold.toDouble(),
          'status': TraceabilityStatus.sold.name,
        },
        where: 'cottonType = ? AND status = ?',
        whereArgs: [sale.cottonType.name, TraceabilityStatus.processed.name],
      );
      
      return saleId;
    });
  }

  // ============ TRACEABILITY OPERATIONS ============

  /// Load cotton traceability
  Future<void> loadTraceability() async {
    final db = await _dbHelper.database;
    final maps = await db.query('cotton_traceability', orderBy: 'purchaseDate DESC');
    _traceability = maps.map((map) => CottonTraceability.fromMap(map)).toList();
    notifyListeners();
  }

  /// Get traceability by code
  CottonTraceability? getTraceabilityByCode(String code) {
    return _traceability.where((t) => t.traceabilityCode == code).firstOrNull;
  }

  /// Get traceability by status
  List<CottonTraceability> getTraceabilityByStatus(TraceabilityStatus status) {
    return _traceability.where((t) => t.status == status).toList();
  }

  // ============ ANALYTICS & REPORTING ============

  /// Get cotton processing calculator results
  Map<String, dynamic> calculateProcessing({
    required double lintKg,
    required double ulukKg,
    required double valaknoKg,
    bool autoCalculateValakno = false,
  }) {
    double calculatedValakno = valaknoKg;
    
    if (autoCalculateValakno) {
      calculatedValakno = CottonProcessingCalculator.calculateAutoValakno(
        lintKg: lintKg,
        ulukKg: ulukKg,
      );
    }
    
    final processingType = CottonProcessingCalculator.determineProcessingType(
      hasLint: lintKg > 0,
      hasUluk: ulukKg > 0,
      hasValakno: calculatedValakno > 0,
    );
    
    final totalInputWeight = CottonProcessingCalculator.calculateTotalInputWeight(
      lintKg: lintKg,
      ulukKg: ulukKg,
      valaknoKg: calculatedValakno,
      extraValaknoKg: 0,
    );
    
    return {
      'processingType': processingType,
      'calculatedValakno': calculatedValakno,
      'totalInputWeight': totalInputWeight,
      'recommendations': _getProcessingRecommendations(processingType),
    };
  }

  List<String> _getProcessingRecommendations(ProcessingType type) {
    switch (type) {
      case ProcessingType.threeCottonTypes:
        return [
          'Линт + Улук комбинатсия истифода мешавад',
          'Валакно автоматӣ ҳисоб карда мешавад',
          'Нисбати стандартӣ: 2:0.5',
        ];
      case ProcessingType.twoCottonTypes:
        return [
          'Ду навъи пахта коркард мешавад',
          'Нисбати тавсияшуда: 2:1',
          'Самаранокии баланд интизор аст',
        ];
      case ProcessingType.singleCottonType:
        return [
          'Як навъи пахта коркард мешавад',
          'Нисбати асосӣ: 1:0.5',
          'Самаранокии стандартӣ',
        ];
    }
  }

  /// Get overall cotton statistics
  Map<String, dynamic> get overallStatistics {
    final totalPurchases = _purchaseRegistry.length;
    final totalProcessed = _processingRegistry.length;
    final totalSales = _saleRegistry.length;
    
    final totalPurchaseCost = _purchaseItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final totalSalesRevenue = _saleRegistry.fold(0.0, (sum, sale) => sum + sale.totalAmount);
    final totalInventoryValue = _cottonInventory.fold(0.0, (sum, inv) => sum + inv.totalWeight);
    
    return {
      'totalPurchases': totalPurchases,
      'totalProcessed': totalProcessed,
      'totalSales': totalSales,
      'totalPurchaseCost': totalPurchaseCost,
      'totalSalesRevenue': totalSalesRevenue,
      'totalProfit': totalSalesRevenue - totalPurchaseCost,
      'totalInventoryWeight': totalInventoryValue,
      'processingEfficiency': totalProcessed > 0 ? (totalSales / totalProcessed) * 100.0 : 0.0,
    };
  }
}

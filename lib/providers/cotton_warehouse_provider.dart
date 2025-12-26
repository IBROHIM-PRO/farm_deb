import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/raw_cotton_warehouse.dart';
import '../models/processed_cotton_warehouse.dart';

/// Provider for managing both raw and processed cotton warehouses
class CottonWarehouseProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Raw cotton warehouse inventory by type
  List<RawCottonWarehouse> _rawCottonInventory = [];
  
  // Processed cotton warehouse inventory 
  List<ProcessedCottonWarehouse> _processedCottonInventory = [];
  
  bool _isLoading = false;

  // Getters
  List<RawCottonWarehouse> get rawCottonInventory => _rawCottonInventory;
  List<ProcessedCottonWarehouse> get processedCottonInventory => _processedCottonInventory;
  bool get isLoading => _isLoading;

  /// Get total inventory for specific raw cotton type
  RawCottonWarehouse? getRawCottonByType(RawCottonType type) {
    try {
      return _rawCottonInventory.firstWhere((item) => item.cottonType == type);
    } catch (e) {
      return null;
    }
  }

  /// Get total processed cotton inventory
  ProcessedCottonWarehouse? get totalProcessedCotton {
    if (_processedCottonInventory.isEmpty) return null;
    
    // Sum all processed cotton entries
    int totalPieces = 0;
    double totalWeight = 0.0;
    double avgWeightPerPiece = 0.0;
    DateTime latestUpdate = DateTime.fromMillisecondsSinceEpoch(0);
    
    for (final inventory in _processedCottonInventory) {
      totalPieces += inventory.pieces;
      totalWeight += inventory.totalWeight;
      if (inventory.lastUpdated.isAfter(latestUpdate)) {
        latestUpdate = inventory.lastUpdated;
      }
    }
    
    // Calculate average weight per piece
    if (totalPieces > 0) {
      avgWeightPerPiece = totalWeight / totalPieces;
    }
    
    return ProcessedCottonWarehouse(
      pieces: totalPieces,
      totalWeight: totalWeight,
      weightPerPiece: avgWeightPerPiece,
      lastUpdated: latestUpdate,
      notes: 'Ҷамъи умумӣ',
    );
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Load all warehouse data
  Future<void> loadAllData() async {
    _setLoading(true);
    try {
      await Future.wait([
        loadRawCottonInventory(),
        loadProcessedCottonInventory(),
      ]);
    } finally {
      _setLoading(false);
    }
  }

  /// Load raw cotton warehouse inventory
  Future<void> loadRawCottonInventory() async {
    final db = await _dbHelper.database;
    final maps = await db.query('raw_cotton_warehouse', orderBy: 'cottonType ASC');
    _rawCottonInventory = maps.map((map) => RawCottonWarehouse.fromMap(map)).toList();
    notifyListeners();
  }

  /// Load processed cotton warehouse inventory
  Future<void> loadProcessedCottonInventory() async {
    final db = await _dbHelper.database;
    final maps = await db.query('processed_cotton_warehouse', orderBy: 'lastUpdated DESC');
    _processedCottonInventory = maps.map((map) => ProcessedCottonWarehouse.fromMap(map)).toList();
    notifyListeners();
  }

  /// Add inventory to raw cotton warehouse (from purchases)
  Future<void> addToRawWarehouse({
    required RawCottonType cottonType,
    required int pieces,
    required double totalWeight,
    String notes = '',
  }) async {
    final db = await _dbHelper.database;
    
    // Check if inventory for this type already exists
    final existingInventory = getRawCottonByType(cottonType);
    
    if (existingInventory != null) {
      // Update existing inventory
      final updatedInventory = existingInventory.addInventory(
        additionalPieces: pieces,
        additionalWeight: totalWeight,
      );
      
      await db.update(
        'raw_cotton_warehouse',
        updatedInventory.toMap(),
        where: 'id = ?',
        whereArgs: [existingInventory.id],
      );
    } else {
      // Create new inventory entry
      final newInventory = RawCottonWarehouse.createFromPurchase(
        cottonType: cottonType,
        pieces: pieces,
        totalWeight: totalWeight,
        notes: notes,
      );
      
      await db.insert('raw_cotton_warehouse', newInventory.toMap());
    }
    
    await loadRawCottonInventory();
  }

  /// Deduct inventory from raw cotton warehouse (for processing)
  Future<void> deductFromRawWarehouse({
    required RawCottonType cottonType,
    required int pieces,
    required double totalWeight,
  }) async {
    final existingInventory = getRawCottonByType(cottonType);
    
    if (existingInventory == null) {
      throw ArgumentError('Ин навъи пахтаи хом дар анбор мавҷуд нест');
    }
    
    if (!existingInventory.hasEnoughInventory(
      requiredPieces: pieces,
      requiredWeight: totalWeight,
    )) {
      throw ArgumentError('Дар анбор пахтаи кофӣ нест');
    }
    
    final updatedInventory = existingInventory.deductInventory(
      deductPieces: pieces,
      deductWeight: totalWeight,
    );
    
    final db = await _dbHelper.database;
    await db.update(
      'raw_cotton_warehouse',
      updatedInventory.toMap(),
      where: 'id = ?',
      whereArgs: [existingInventory.id],
    );
    
    await loadRawCottonInventory();
  }

  /// Add inventory to processed cotton warehouse (from processing)
  Future<void> addToProcessedWarehouse({
    required int pieces,
    required double totalWeight,
    required double weightPerPiece,
    String notes = '',
    String? batchNumber,
  }) async {
    final db = await _dbHelper.database;
    
    // For processed cotton, we can either add to existing or create new entry
    // Let's create a new entry for each processing batch for better tracking
    final newInventory = ProcessedCottonWarehouse.createFromProcessing(
      pieces: pieces,
      totalWeight: totalWeight,
      weightPerPiece: weightPerPiece,
      notes: notes,
      batchNumber: batchNumber,
    );
    
    await db.insert('processed_cotton_warehouse', newInventory.toMap());
    await loadProcessedCottonInventory();
  }

  /// Deduct inventory from processed cotton warehouse (for sales)
  Future<void> deductFromProcessedWarehouse({
    required double deductWeight,
  }) async {
    final totalInventory = totalProcessedCotton;
    
    if (totalInventory == null || !totalInventory.hasEnoughWeight(deductWeight)) {
      throw ArgumentError('Дар анбори пахтаи коркардшуда қадри кофӣ нест');
    }
    
    final db = await _dbHelper.database;
    
    // Deduct from inventory entries in FIFO order (oldest first)
    double remainingToDeduct = deductWeight;
    
    for (final inventory in _processedCottonInventory.reversed) { // Oldest first
      if (remainingToDeduct <= 0) break;
      
      final availableWeight = inventory.totalWeight;
      final deductFromThis = availableWeight >= remainingToDeduct 
          ? remainingToDeduct 
          : availableWeight;
      
      if (deductFromThis >= availableWeight) {
        // Remove this inventory entry completely
        await db.delete(
          'processed_cotton_warehouse',
          where: 'id = ?',
          whereArgs: [inventory.id],
        );
      } else {
        // Partially deduct from this inventory
        final updatedInventory = inventory.deductByWeight(deductFromThis);
        await db.update(
          'processed_cotton_warehouse',
          updatedInventory.toMap(),
          where: 'id = ?',
          whereArgs: [inventory.id],
        );
      }
      
      remainingToDeduct -= deductFromThis;
    }
    
    await loadProcessedCottonInventory();
  }

  /// Process cotton: deduct from raw warehouse, add to processed warehouse
  Future<void> processCotton({
    required Map<RawCottonType, double> rawCottonUsage, // Type -> weight used
    required int producedPieces,
    required double producedWeight,
    required double weightPerPiece,
    String notes = '',
    String? batchNumber,
  }) async {
    // First, validate that we have enough raw cotton
    for (final entry in rawCottonUsage.entries) {
      final type = entry.key;
      final weightNeeded = entry.value;
      
      final inventory = getRawCottonByType(type);
      if (inventory == null || inventory.totalWeight < weightNeeded) {
        throw ArgumentError('Пахтаи хоми ${type.name} дар анбор кофӣ нест');
      }
    }
    
    // Deduct from raw cotton warehouse
    for (final entry in rawCottonUsage.entries) {
      final type = entry.key;
      final weightUsed = entry.value;
      final inventory = getRawCottonByType(type)!;
      
      // Calculate pieces based on average weight per piece
      final piecesToDeduct = inventory.averageWeightPerPiece > 0 
          ? (weightUsed / inventory.averageWeightPerPiece).round()
          : 0;
      
      await deductFromRawWarehouse(
        cottonType: type,
        pieces: piecesToDeduct,
        totalWeight: weightUsed,
      );
    }
    
    // Add to processed cotton warehouse
    await addToProcessedWarehouse(
      pieces: producedPieces,
      totalWeight: producedWeight,
      weightPerPiece: weightPerPiece,
      notes: notes,
      batchNumber: batchNumber,
    );
  }

  /// Get warehouse summary
  Map<String, dynamic> getWarehouseSummary() {
    // Raw cotton summary
    int totalRawPieces = 0;
    double totalRawWeight = 0.0;
    Map<String, Map<String, double>> rawSummary = {};
    
    for (final inventory in _rawCottonInventory) {
      totalRawPieces += inventory.pieces;
      totalRawWeight += inventory.totalWeight;
      
      rawSummary[inventory.cottonTypeDisplay] = {
        'pieces': inventory.pieces.toDouble(),
        'weight': inventory.totalWeight,
      };
    }
    
    // Processed cotton summary
    final processedTotal = totalProcessedCotton;
    
    return {
      'rawCotton': {
        'totalPieces': totalRawPieces,
        'totalWeight': totalRawWeight,
        'byType': rawSummary,
      },
      'processedCotton': {
        'totalPieces': processedTotal?.pieces ?? 0,
        'totalWeight': processedTotal?.totalWeight ?? 0.0,
        'averageWeightPerPiece': processedTotal?.weightPerPiece ?? 0.0,
      },
    };
  }
}

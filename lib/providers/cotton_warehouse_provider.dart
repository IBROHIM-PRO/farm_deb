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
  bool _tablesInitialized = false;

  /// Constructor - ensure tables exist on provider creation
  CottonWarehouseProvider() {
    _initializeTables();
  }

  /// Initialize tables when provider is created
  void _initializeTables() async {
    if (_tablesInitialized) return;
    
    try {
      await _createTablesSync();
      _tablesInitialized = true;
      debugPrint('✅ Cotton warehouse tables initialized in constructor');
    } catch (e) {
      debugPrint('❌ Error initializing cotton warehouse tables in constructor: $e');
    }
  }

  /// Create tables synchronously  
  Future<void> _createTablesSync() async {
    final db = await _dbHelper.database;
    
    debugPrint('🔄 Creating cotton warehouse tables synchronously...');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS raw_cotton_warehouse (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cottonType TEXT NOT NULL,
        pieces INTEGER NOT NULL DEFAULT 0,
        totalWeight REAL NOT NULL DEFAULT 0.0,
        lastUpdated TEXT NOT NULL,
        notes TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS processed_cotton_warehouse (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pieces INTEGER NOT NULL DEFAULT 0,
        totalWeight REAL NOT NULL DEFAULT 0.0,
        weightPerPiece REAL NOT NULL DEFAULT 25.0,
        lastUpdated TEXT NOT NULL,
        notes TEXT DEFAULT '',
        batchNumber TEXT
      )
    ''');

    debugPrint('✅ Cotton warehouse tables created synchronously');
  }

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

  /// Ensure cotton warehouse tables exist in database
  Future<void> ensureCottonWarehouseTables() async {
    debugPrint('🔄 Starting cotton warehouse table creation...');
    try {
      final db = await _dbHelper.database;
      debugPrint('🔄 Database connection obtained');
      
      // Create raw cotton warehouse table
      debugPrint('🔄 Creating raw_cotton_warehouse table...');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS raw_cotton_warehouse (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cottonType TEXT NOT NULL,
          pieces INTEGER NOT NULL DEFAULT 0,
          totalWeight REAL NOT NULL DEFAULT 0.0,
          lastUpdated TEXT NOT NULL,
          notes TEXT DEFAULT ''
        )
      ''');
      debugPrint('✅ Raw cotton warehouse table created');

      // Create processed cotton warehouse table
      debugPrint('🔄 Creating processed_cotton_warehouse table...');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS processed_cotton_warehouse (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pieces INTEGER NOT NULL DEFAULT 0,
          totalWeight REAL NOT NULL DEFAULT 0.0,
          weightPerPiece REAL NOT NULL DEFAULT 25.0,
          lastUpdated TEXT NOT NULL,
          notes TEXT DEFAULT '',
          batchNumber TEXT
        )
      ''');
      debugPrint('✅ Processed cotton warehouse table created');

      // Create indexes
      debugPrint('🔄 Creating indexes...');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_raw_cotton_type 
        ON raw_cotton_warehouse (cottonType)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_processed_cotton_date 
        ON processed_cotton_warehouse (lastUpdated DESC)
      ''');
      
      debugPrint('✅ Cotton warehouse tables and indexes created successfully');
    } catch (e) {
      debugPrint('❌ Error creating cotton warehouse tables: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Load all warehouse data
  Future<void> loadAllData() async {
    debugPrint('🔄 CottonWarehouseProvider.loadAllData() started');
    _setLoading(true);
    try {
      // Create tables synchronously BEFORE any other operations
      final db = await _dbHelper.database;
      
      debugPrint('🔄 Creating raw cotton warehouse table...');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS raw_cotton_warehouse (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cottonType TEXT NOT NULL,
          pieces INTEGER NOT NULL DEFAULT 0,
          totalWeight REAL NOT NULL DEFAULT 0.0,
          lastUpdated TEXT NOT NULL,
          notes TEXT DEFAULT ''
        )
      ''');
      
      debugPrint('🔄 Creating processed cotton warehouse table...');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS processed_cotton_warehouse (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pieces INTEGER NOT NULL DEFAULT 0,
          totalWeight REAL NOT NULL DEFAULT 0.0,
          weightPerPiece REAL NOT NULL DEFAULT 25.0,
          lastUpdated TEXT NOT NULL,
          notes TEXT DEFAULT '',
          batchNumber TEXT
        )
      ''');
      
      debugPrint('✅ Cotton warehouse tables created, now loading data...');
      
      // Load raw cotton data
      final rawMaps = await db.query('raw_cotton_warehouse', orderBy: 'cottonType ASC');
      _rawCottonInventory = rawMaps.map((map) => RawCottonWarehouse.fromMap(map)).toList();
      
      // Load processed cotton data
      final processedMaps = await db.query('processed_cotton_warehouse', orderBy: 'lastUpdated DESC');
      _processedCottonInventory = processedMaps.map((map) => ProcessedCottonWarehouse.fromMap(map)).toList();
      
      debugPrint('✅ Cotton warehouse loaded: ${_rawCottonInventory.length} raw, ${_processedCottonInventory.length} processed');
    } catch (e) {
      debugPrint('❌ Error in CottonWarehouseProvider.loadAllData(): $e');
      _rawCottonInventory = [];
      _processedCottonInventory = [];
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Load raw cotton warehouse inventory
  Future<void> loadRawCottonInventory() async {
    try {
      final db = await _dbHelper.database;
      
      // Ensure table exists before querying
      await db.execute('''
        CREATE TABLE IF NOT EXISTS raw_cotton_warehouse (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cottonType TEXT NOT NULL,
          pieces INTEGER NOT NULL DEFAULT 0,
          totalWeight REAL NOT NULL DEFAULT 0.0,
          lastUpdated TEXT NOT NULL,
          notes TEXT DEFAULT ''
        )
      ''');
      
      final maps = await db.query('raw_cotton_warehouse', orderBy: 'cottonType ASC');
      _rawCottonInventory = maps.map((map) => RawCottonWarehouse.fromMap(map)).toList();
      debugPrint('✅ Raw cotton warehouse loaded: ${_rawCottonInventory.length} items');
    } catch (e) {
      debugPrint('❌ Error loading raw cotton warehouse: $e');
      _rawCottonInventory = []; // Ensure we have an empty list on error
    }
    notifyListeners();
  }

  /// Load processed cotton warehouse inventory
  Future<void> loadProcessedCottonInventory() async {
    try {
      final db = await _dbHelper.database;
      
      // Ensure table exists before querying
      await db.execute('''
        CREATE TABLE IF NOT EXISTS processed_cotton_warehouse (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pieces INTEGER NOT NULL DEFAULT 0,
          totalWeight REAL NOT NULL DEFAULT 0.0,
          weightPerPiece REAL NOT NULL DEFAULT 25.0,
          lastUpdated TEXT NOT NULL,
          notes TEXT DEFAULT '',
          batchNumber TEXT
        )
      ''');
      
      final maps = await db.query('processed_cotton_warehouse', orderBy: 'lastUpdated DESC');
      _processedCottonInventory = maps.map((map) => ProcessedCottonWarehouse.fromMap(map)).toList();
      debugPrint('✅ Processed cotton warehouse loaded: ${_processedCottonInventory.length} items');
    } catch (e) {
      debugPrint('❌ Error loading processed cotton warehouse: $e');
      _processedCottonInventory = []; // Ensure we have an empty list on error
    }
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
    
    await loadAllData();
    debugPrint('✅ Database refreshed after raw cotton warehouse addition');
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

  /// Remove specific cotton from processed warehouse by weight category and pieces (for sales)
  Future<void> removeFromProcessedWarehouse({
    required double weightPerPiece,
    required int pieces,
  }) async {
    final db = await _dbHelper.database;
    
    // Find matching batches with this weight per piece (within 0.1kg tolerance)
    final matchingBatches = _processedCottonInventory.where((batch) => 
      (batch.weightPerPiece - weightPerPiece).abs() <= 0.1).toList();
    
    if (matchingBatches.isEmpty) {
      throw ArgumentError('Вазни ${weightPerPiece.toStringAsFixed(1)} кг дар анбор мавҷуд нест');
    }
    
    final totalAvailablePieces = matchingBatches.fold<int>(0, (sum, batch) => sum + batch.pieces);
    
    if (pieces > totalAvailablePieces) {
      throw ArgumentError('Дар анбор танҳо $totalAvailablePieces дона мавҷуд, дархост $pieces дона');
    }
    
    // Remove pieces from matching batches (FIFO - oldest first)
    int remainingToRemove = pieces;
    final sortedBatches = List<ProcessedCottonWarehouse>.from(matchingBatches)
      ..sort((a, b) => a.lastUpdated.compareTo(b.lastUpdated));
    
    for (final batch in sortedBatches) {
      if (remainingToRemove <= 0) break;
      
      final piecesToRemoveFromThis = batch.pieces >= remainingToRemove 
          ? remainingToRemove 
          : batch.pieces;
      
      if (piecesToRemoveFromThis >= batch.pieces) {
        // Remove this batch completely
        await db.delete(
          'processed_cotton_warehouse',
          where: 'id = ?',
          whereArgs: [batch.id],
        );
      } else {
        // Partially remove from this batch
        final newPieces = batch.pieces - piecesToRemoveFromThis;
        final newTotalWeight = newPieces * batch.weightPerPiece;
        
        final updatedBatch = ProcessedCottonWarehouse(
          id: batch.id,
          pieces: newPieces,
          totalWeight: newTotalWeight,
          weightPerPiece: batch.weightPerPiece,
          lastUpdated: DateTime.now(),
          notes: batch.notes,
          batchNumber: batch.batchNumber,
        );
        
        await db.update(
          'processed_cotton_warehouse',
          updatedBatch.toMap(),
          where: 'id = ?',
          whereArgs: [batch.id],
        );
      }
      
      remainingToRemove -= piecesToRemoveFromThis;
    }
    
    await loadProcessedCottonInventory();
    debugPrint('✅ Removed $pieces pieces of ${weightPerPiece.toStringAsFixed(1)}kg cotton from warehouse');
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

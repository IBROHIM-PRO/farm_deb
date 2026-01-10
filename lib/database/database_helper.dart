import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/person.dart';
import '../models/debt.dart';
import '../models/payment.dart';
import '../models/field.dart';
import '../models/field_activity.dart';
import '../models/cotton_harvest.dart';
import '../models/cotton_sale.dart';
import '../models/cattle.dart';
import '../models/cattle_record.dart';
import '../models/cattle_sale.dart';
import '../models/cotton_type.dart' as OldCottonType;
import '../models/cotton_batch.dart';
import '../models/cotton_dispatch.dart';
import '../models/cotton_processing.dart';
import '../models/buyer.dart';
import '../models/cotton_stock_sale.dart';
import '../models/transaction_history.dart';
import '../providers/history_provider.dart';
// Registry-based Models
import '../models/cattle_registry.dart';
import '../models/cattle_purchase.dart';
import '../models/cattle_expense.dart';
import '../models/cattle_weight.dart';
import '../models/cotton_purchase_registry.dart';
import '../models/cotton_purchase_item.dart';
import '../models/cotton_processing_registry.dart';
import '../models/cotton_processing_input.dart';
import '../models/cotton_processing_output.dart';
import '../models/cotton_inventory.dart';
import '../models/cotton_sale_registry.dart';
import '../models/cotton_traceability.dart';
import '../models/barn.dart';
import '../models/barn_expense.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('farm_debt_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path, 
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Debt Management Tables
    await db.execute('''
      CREATE TABLE persons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        phone TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        personId INTEGER NOT NULL,
        totalAmount REAL NOT NULL,
        remainingAmount REAL NOT NULL,
        currency TEXT NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (personId) REFERENCES persons (id) ON DELETE CASCADE
      )
    ''');

    // Create index for faster debt lookups
    await db.execute('''
      CREATE INDEX idx_debts_person_type_currency_status 
      ON debts (personId, type, currency, status)
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debtId INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (debtId) REFERENCES debts (id) ON DELETE CASCADE
      )
    ''');

    // Create index for faster payment history lookups
    await db.execute('''
      CREATE INDEX idx_payments_debt 
      ON payments (debtId, date DESC)
    ''');

    // Cotton Warehouse Tables
    await db.execute('''
      CREATE TABLE raw_cotton_warehouse (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cottonType TEXT NOT NULL,
        pieces INTEGER NOT NULL DEFAULT 0,
        totalWeight REAL NOT NULL DEFAULT 0.0,
        lastUpdated TEXT NOT NULL,
        notes TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE processed_cotton_warehouse (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pieces INTEGER NOT NULL DEFAULT 0,
        totalWeight REAL NOT NULL DEFAULT 0.0,
        weightPerPiece REAL NOT NULL DEFAULT 25.0,
        lastUpdated TEXT NOT NULL,
        notes TEXT DEFAULT '',
        batchNumber TEXT
      )
    ''');

    // Create indexes for warehouse tables
    await db.execute('''
      CREATE INDEX idx_raw_cotton_type 
      ON raw_cotton_warehouse (cottonType)
    ''');

    await db.execute('''
      CREATE INDEX idx_processed_cotton_date 
      ON processed_cotton_warehouse (lastUpdated DESC)
    ''');

    // Cotton Management Tables
    await db.execute('''
      CREATE TABLE fields (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        area REAL NOT NULL,
        areaUnit TEXT DEFAULT 'hectare',
        seedType TEXT,
        plantingDate TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE field_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fieldId INTEGER NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        cost REAL NOT NULL,
        currency TEXT DEFAULT 'TJS',
        description TEXT,
        laborHours REAL,
        FOREIGN KEY (fieldId) REFERENCES fields (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE cotton_harvests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fieldId INTEGER NOT NULL,
        date TEXT NOT NULL,
        rawWeight REAL NOT NULL,
        weightUnit TEXT DEFAULT 'kg',
        lintWeight REAL,
        ulukWeight REAL,
        valaknoWeight REAL,
        extraValaknoWeight REAL,
        processedWeight REAL,
        processedUnits INTEGER,
        isProcessed INTEGER DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (fieldId) REFERENCES fields (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE cotton_sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        harvestId INTEGER,
        date TEXT NOT NULL,
        saleType TEXT NOT NULL,
        weight REAL,
        units INTEGER,
        weightPerUnit REAL,
        pricePerUnit REAL NOT NULL,
        totalAmount REAL NOT NULL,
        currency TEXT DEFAULT 'TJS',
        buyerName TEXT,
        buyerPhone TEXT,
        paymentStatus TEXT DEFAULT 'pending',
        paidAmount REAL DEFAULT 0,
        notes TEXT
      )
    ''');

    // Cattle Management Tables
    await db.execute('''
      CREATE TABLE cattle (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        earTag TEXT NOT NULL UNIQUE,
        name TEXT,
        gender TEXT NOT NULL,
        ageCategory TEXT NOT NULL,
        purchaseDate TEXT NOT NULL,
        purchasePrice REAL NOT NULL,
        currency TEXT DEFAULT 'TJS',
        sellerName TEXT,
        freightCost REAL DEFAULT 0,
        initialWeight REAL NOT NULL,
        currentWeight REAL NOT NULL,
        weightUnit TEXT DEFAULT 'kg',
        status TEXT DEFAULT 'active',
        breed TEXT,
        notes TEXT,
        purchasePaymentStatus TEXT DEFAULT 'paid',
        paidAmount REAL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE cattle_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cattleId INTEGER NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        cost REAL DEFAULT 0,
        currency TEXT DEFAULT 'TJS',
        description TEXT,
        feedType TEXT,
        supplier TEXT,
        medicineName TEXT,
        medicineType TEXT,
        weight REAL,
        quantity REAL,
        quantityUnit TEXT,
        monitoringMonth INTEGER,
        FOREIGN KEY (cattleId) REFERENCES cattle (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE cattle_sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cattleId INTEGER NOT NULL,
        date TEXT NOT NULL,
        saleType TEXT NOT NULL,
        weight REAL NOT NULL,
        slaughterDate TEXT,
        liveWeight REAL,
        pricePerKg REAL NOT NULL,
        totalAmount REAL NOT NULL,
        currency TEXT DEFAULT 'TJS',
        buyerName TEXT,
        buyerPhone TEXT,
        paymentStatus TEXT DEFAULT 'pending',
        paidAmount REAL DEFAULT 0,
        freightCost REAL DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (cattleId) REFERENCES cattle (id) ON DELETE CASCADE
      )
    ''');

    // Cotton Stock Management Tables
    await db.execute('''
      CREATE TABLE cotton_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        pricePerKg REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cotton_batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cottonTypeId INTEGER NOT NULL,
        weightKg REAL NOT NULL,
        units INTEGER NOT NULL,
        arrivalDate TEXT NOT NULL,
        source TEXT NOT NULL,
        pricePerKg REAL NOT NULL,
        freightCost REAL NOT NULL,
        totalCost REAL NOT NULL,
        remainingWeightKg REAL NOT NULL,
        remainingUnits INTEGER NOT NULL,
        FOREIGN KEY (cottonTypeId) REFERENCES cotton_types (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE cotton_dispatches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batchId INTEGER NOT NULL,
        weightKg REAL NOT NULL,
        units INTEGER NOT NULL,
        dispatchDate TEXT NOT NULL,
        destination TEXT NOT NULL,
        FOREIGN KEY (batchId) REFERENCES cotton_batches (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE cotton_processing (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        processingDate TEXT NOT NULL,
        lintWeight REAL,
        ulukWeight REAL,
        valaknoWeight REAL,
        extraValaknoWeight REAL,
        lintUnits INTEGER,
        ulukUnits INTEGER,
        valaknoUnits INTEGER,
        extraValaknoUnits INTEGER,
        totalInputWeight REAL NOT NULL,
        processedOutputWeight REAL NOT NULL,
        processedUnits INTEGER NOT NULL,
        yieldPercentage REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE buyers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        phone TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cotton_stock_sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        buyerId INTEGER NOT NULL,
        saleDate TEXT NOT NULL,
        unitWeight REAL NOT NULL,
        units INTEGER NOT NULL,
        totalWeight REAL NOT NULL,
        pricePerKg REAL,
        pricePerUnit REAL,
        totalAmount REAL,
        freightCost REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (buyerId) REFERENCES buyers (id) ON DELETE CASCADE
      )
    ''');

    // Insert default cotton types
    await db.execute('INSERT INTO cotton_types (name, pricePerKg) VALUES (?, ?)', ['Lint', 500.0]);
    await db.execute('INSERT INTO cotton_types (name, pricePerKg) VALUES (?, ?)', ['Uluk', 500.0]);
    await db.execute('INSERT INTO cotton_types (name, pricePerKg) VALUES (?, ?)', ['Valakno', 250.0]);

    // Transaction History Table
    await db.execute('''
      CREATE TABLE transaction_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL,
        currency TEXT,
        quantity REAL,
        quantityUnit TEXT,
        personName TEXT NOT NULL,
        personPhone TEXT,
        description TEXT NOT NULL,
        notes TEXT,
        sourceTable TEXT NOT NULL,
        sourceId INTEGER NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_transaction_history_date ON transaction_history (date DESC)');
    await db.execute('CREATE INDEX idx_transaction_history_person ON transaction_history (personName)');
    await db.execute('CREATE INDEX idx_transaction_history_type ON transaction_history (type, category)');

    // Cotton Registry Management Tables
    await db.execute('''
      CREATE TABLE cotton_purchase_registry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchaseDate TEXT NOT NULL,
        supplierName TEXT NOT NULL,
        transportationCost REAL NOT NULL,
        freightCost REAL NOT NULL DEFAULT 0,
        notes TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE cotton_purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchaseId INTEGER NOT NULL,
        cottonType TEXT NOT NULL,
        weight REAL NOT NULL,
        units INTEGER NOT NULL,
        pricePerKg REAL NOT NULL,
        totalPrice REAL NOT NULL,
        notes TEXT,
        transferredToWarehouse INTEGER DEFAULT 0,
        FOREIGN KEY (purchaseId) REFERENCES cotton_purchase_registry (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE cotton_processing_registry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        linkedPurchaseId INTEGER NOT NULL,
        processingDate TEXT,
        notes TEXT,
        FOREIGN KEY (linkedPurchaseId) REFERENCES cotton_purchase_registry (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE cotton_processing_inputs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        processingId INTEGER NOT NULL,
        cottonType TEXT NOT NULL,
        unitsUsed INTEGER NOT NULL,
        weightUsed REAL NOT NULL,
        sourcePurchaseItemId INTEGER NOT NULL,
        FOREIGN KEY (processingId) REFERENCES cotton_processing_registry (id) ON DELETE CASCADE,
        FOREIGN KEY (sourcePurchaseItemId) REFERENCES cotton_purchase_items (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE cotton_processing_outputs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        processingId INTEGER NOT NULL,
        cottonType TEXT NOT NULL,
        batchWeightPerUnit REAL NOT NULL,
        numberOfUnits INTEGER NOT NULL,
        totalWeight REAL NOT NULL,
        FOREIGN KEY (processingId) REFERENCES cotton_processing_registry (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE cotton_inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cottonType TEXT NOT NULL,
        batchSize REAL NOT NULL,
        availableUnits INTEGER NOT NULL,
        totalWeight REAL NOT NULL,
        sourceProcessingId INTEGER NOT NULL,
        FOREIGN KEY (sourceProcessingId) REFERENCES cotton_processing_registry (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE cotton_sale_registry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleDate TEXT NOT NULL,
        buyerName TEXT,
        cottonType TEXT NOT NULL,
        batchSize REAL NOT NULL,
        unitsSold INTEGER NOT NULL,
        weightSold REAL NOT NULL,
        pricePerKg REAL NOT NULL,
        totalAmount REAL NOT NULL,
        paymentStatus TEXT NOT NULL,
        sourceInventoryId INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (sourceInventoryId) REFERENCES cotton_inventory (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE cotton_traceability (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cottonType TEXT NOT NULL,
        traceabilityCode TEXT NOT NULL UNIQUE,
        purchaseId INTEGER NOT NULL,
        purchaseDate TEXT NOT NULL,
        supplierName TEXT NOT NULL,
        originalWeight REAL NOT NULL,
        originalUnits REAL NOT NULL,
        processingId INTEGER,
        processingDate TEXT,
        processedWeight REAL,
        processedUnits REAL,
        saleId INTEGER,
        saleDate TEXT,
        buyerName TEXT,
        soldWeight REAL,
        soldUnits REAL,
        status TEXT NOT NULL,
        FOREIGN KEY (purchaseId) REFERENCES cotton_purchase_registry (id) ON DELETE CASCADE,
        FOREIGN KEY (processingId) REFERENCES cotton_processing_registry (id) ON DELETE SET NULL,
        FOREIGN KEY (saleId) REFERENCES cotton_sale_registry (id) ON DELETE SET NULL
      )
    ''');

    // Barn Management Tables
    await db.execute('''
      CREATE TABLE barns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT,
        capacity INTEGER,
        createdDate TEXT NOT NULL,
        notes TEXT,
        isActive INTEGER DEFAULT 1
      )
    ''');
    
    await db.execute('''
      CREATE TABLE barn_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barnId INTEGER NOT NULL,
        expenseType TEXT NOT NULL,
        feedType TEXT,
        itemName TEXT NOT NULL,
        quantity REAL NOT NULL,
        quantityUnit TEXT NOT NULL,
        pricePerUnit REAL NOT NULL,
        totalCost REAL NOT NULL,
        currency TEXT NOT NULL,
        supplier TEXT,
        expenseDate TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (barnId) REFERENCES barns (id) ON DELETE CASCADE
      )
    ''');

    // Cattle Registry Management Tables
    await db.execute('''
      CREATE TABLE cattle_registry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        earTag TEXT NOT NULL,
        name TEXT,
        gender TEXT NOT NULL,
        ageCategory TEXT NOT NULL,
        barnId INTEGER,
        breederId INTEGER,
        registrationDate TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (barnId) REFERENCES barns (id) ON DELETE SET NULL,
        FOREIGN KEY (breederId) REFERENCES persons (id) ON DELETE SET NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE cattle_purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cattleId INTEGER NOT NULL,
        purchaseDate TEXT NOT NULL,
        weightAtPurchase REAL NOT NULL,
        pricePerKg REAL,
        totalPrice REAL,
        currency TEXT NOT NULL,
        sellerName TEXT,
        transportationCost REAL NOT NULL,
        paymentStatus TEXT NOT NULL,
        paidAmount REAL NOT NULL,
        notes TEXT,
        FOREIGN KEY (cattleId) REFERENCES cattle_registry (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE cattle_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cattleId INTEGER NOT NULL,
        expenseType TEXT NOT NULL,
        itemName TEXT NOT NULL,
        quantity REAL NOT NULL,
        quantityUnit TEXT NOT NULL,
        cost REAL NOT NULL,
        currency TEXT NOT NULL,
        supplier TEXT,
        expenseDate TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (cattleId) REFERENCES cattle_registry (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE cattle_weights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cattleId INTEGER NOT NULL,
        measurementDate TEXT NOT NULL,
        weight REAL NOT NULL,
        weightUnit TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (cattleId) REFERENCES cattle_registry (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for registry tables
    await db.execute('CREATE INDEX idx_barn_expenses_barn ON barn_expenses (barnId, expenseDate DESC)');
    await db.execute('CREATE INDEX idx_cattle_registry_barn ON cattle_registry (barnId)');
    await db.execute('CREATE INDEX idx_cattle_registry_eartag ON cattle_registry (earTag)');
    await db.execute('CREATE INDEX idx_cattle_registry_status ON cattle_registry (status)');
    await db.execute('CREATE INDEX idx_cattle_expenses_cattle ON cattle_expenses (cattleId, expenseDate DESC)');
    await db.execute('CREATE INDEX idx_cattle_weights_cattle ON cattle_weights (cattleId, measurementDate DESC)');
    await db.execute('CREATE INDEX idx_cotton_purchase_date ON cotton_purchase_registry (purchaseDate DESC)');
    await db.execute('CREATE INDEX idx_cotton_inventory_type_batch ON cotton_inventory (cottonType, batchSize)');
    await db.execute('CREATE INDEX idx_cotton_traceability_code ON cotton_traceability (traceabilityCode)');
    await db.execute('CREATE INDEX idx_cotton_traceability_status ON cotton_traceability (status)');

    // Daily Expenses Table
    await db.execute('''
      CREATE TABLE daily_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        itemName TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        expenseDate TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_daily_expenses_date ON daily_expenses (expenseDate DESC)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Remove UNIQUE constraint from earTag in cattle_registry table
      // SQLite doesn't support ALTER TABLE to modify constraints, so we need to recreate the table
      
      // Step 1: Create temporary table with new schema (without UNIQUE constraint)
      await db.execute('''
        CREATE TABLE cattle_registry_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          earTag TEXT NOT NULL,
          name TEXT,
          gender TEXT NOT NULL,
          ageCategory TEXT NOT NULL,
          barnId INTEGER,
          breederId INTEGER,
          registrationDate TEXT NOT NULL,
          status TEXT NOT NULL,
          FOREIGN KEY (barnId) REFERENCES barns (id) ON DELETE SET NULL,
          FOREIGN KEY (breederId) REFERENCES persons (id) ON DELETE SET NULL
        )
      ''');
      
      // Step 2: Copy data from old table to new table
      await db.execute('''
        INSERT INTO cattle_registry_new (id, earTag, name, gender, ageCategory, barnId, breederId, registrationDate, status)
        SELECT id, earTag, name, gender, ageCategory, barnId, breederId, registrationDate, status
        FROM cattle_registry
      ''');
      
      // Step 3: Drop old table
      await db.execute('DROP TABLE cattle_registry');
      
      // Step 4: Rename new table to original name
      await db.execute('ALTER TABLE cattle_registry_new RENAME TO cattle_registry');
      
      // Step 5: Recreate indexes
      await db.execute('CREATE INDEX idx_cattle_registry_barn ON cattle_registry (barnId)');
      await db.execute('CREATE INDEX idx_cattle_registry_eartag ON cattle_registry (earTag)');
      await db.execute('CREATE INDEX idx_cattle_registry_status ON cattle_registry (status)');
      
      // Add freightCost column to cotton_purchase_registry table
      await db.execute('ALTER TABLE cotton_purchase_registry ADD COLUMN freightCost REAL NOT NULL DEFAULT 0');
      
      // Add freightCost column to cotton_stock_sales table
      await db.execute('ALTER TABLE cotton_stock_sales ADD COLUMN freightCost REAL NOT NULL DEFAULT 0');
      
      // Ensure freightCost columns exist (for databases that might have issues)
      try {
        // Check if columns exist, if not add them
        final registryInfo = await db.rawQuery('PRAGMA table_info(cotton_purchase_registry)');
        final hasFreightCost = registryInfo.any((col) => col['name'] == 'freightCost');
        
        if (!hasFreightCost) {
          await db.execute('ALTER TABLE cotton_purchase_registry ADD COLUMN freightCost REAL NOT NULL DEFAULT 0');
        }
      } catch (e) {
        // Column might already exist, ignore
      }
      
      try {
        final salesInfo = await db.rawQuery('PRAGMA table_info(cotton_stock_sales)');
        final hasFreightCost = salesInfo.any((col) => col['name'] == 'freightCost');
        
        if (!hasFreightCost) {
          await db.execute('ALTER TABLE cotton_stock_sales ADD COLUMN freightCost REAL NOT NULL DEFAULT 0');
        }
      } catch (e) {
        // Column might already exist, ignore
      }
    }
  }

  // Person CRUD
  Future<int> insertPerson(Person p) async => (await database).insert('persons', p.toMap());
  Future<List<Person>> getAllPersons() async => (await (await database).query('persons', orderBy: 'fullName ASC')).map((m) => Person.fromMap(m)).toList();
  Future<int> updatePerson(Person p) async => (await database).update('persons', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  Future<int> deletePerson(int id) async => (await database).delete('persons', where: 'id = ?', whereArgs: [id]);

  // Debt CRUD
  Future<int> insertDebt(Debt d) async => (await database).insert('debts', d.toMap());
  Future<List<Debt>> getAllDebts() async => (await (await database).query('debts', orderBy: 'date DESC')).map((m) => Debt.fromMap(m)).toList();
  Future<Debt?> getActiveDebt(int personId, String type, String currency) async {
    final result = await (await database).query('debts', where: 'personId = ? AND type = ? AND currency = ? AND status = ?', whereArgs: [personId, type, currency, 'Active']);
    return result.isNotEmpty ? Debt.fromMap(result.first) : null;
  }
  Future<int> updateDebt(Debt d) async => (await database).update('debts', d.toMap(), where: 'id = ?', whereArgs: [d.id]);
  Future<int> deleteDebt(int id) async => (await database).delete('debts', where: 'id = ?', whereArgs: [id]);

  // Payment CRUD
  Future<int> insertPayment(Payment p) async => (await database).insert('payments', p.toMap());
  Future<List<Payment>> getPaymentsByDebtId(int debtId) async => (await (await database).query('payments', where: 'debtId = ?', whereArgs: [debtId], orderBy: 'date DESC')).map((m) => Payment.fromMap(m)).toList();
  Future<Payment?> getPaymentById(int id) async {
    final maps = await (await database).query('payments', where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isEmpty ? null : Payment.fromMap(maps.first);
  }
  Future<int> deletePayment(int id) async => (await database).delete('payments', where: 'id = ?', whereArgs: [id]);

  // Field CRUD
  Future<int> insertField(Field f) async => (await database).insert('fields', f.toMap());
  Future<List<Field>> getAllFields() async => (await (await database).query('fields', orderBy: 'name ASC')).map((m) => Field.fromMap(m)).toList();
  Future<int> updateField(Field f) async => (await database).update('fields', f.toMap(), where: 'id = ?', whereArgs: [f.id]);
  Future<int> deleteField(int id) async => (await database).delete('fields', where: 'id = ?', whereArgs: [id]);

  // Field Activity CRUD
  Future<int> insertFieldActivity(FieldActivity a) async => (await database).insert('field_activities', a.toMap());
  Future<List<FieldActivity>> getAllFieldActivities() async => (await (await database).query('field_activities', orderBy: 'date DESC')).map((m) => FieldActivity.fromMap(m)).toList();
  Future<int> deleteFieldActivity(int id) async => (await database).delete('field_activities', where: 'id = ?', whereArgs: [id]);

  // Cotton Harvest CRUD
  Future<int> insertCottonHarvest(CottonHarvest h) async => (await database).insert('cotton_harvests', h.toMap());
  Future<List<CottonHarvest>> getAllCottonHarvests() async => (await (await database).query('cotton_harvests', orderBy: 'date DESC')).map((m) => CottonHarvest.fromMap(m)).toList();
  Future<int> updateCottonHarvest(CottonHarvest h) async => (await database).update('cotton_harvests', h.toMap(), where: 'id = ?', whereArgs: [h.id]);
  Future<int> deleteCottonHarvest(int id) async => (await database).delete('cotton_harvests', where: 'id = ?', whereArgs: [id]);

  // Cotton Sale CRUD
  Future<int> insertCottonSale(CottonSale s) async => (await database).insert('cotton_sales', s.toMap());
  Future<List<CottonSale>> getAllCottonSales() async => (await (await database).query('cotton_sales', orderBy: 'date DESC')).map((m) => CottonSale.fromMap(m)).toList();
  Future<int> updateCottonSale(CottonSale s) async => (await database).update('cotton_sales', s.toMap(), where: 'id = ?', whereArgs: [s.id]);

  // Cattle CRUD
  Future<int> insertCattle(Cattle c) async => (await database).insert('cattle', c.toMap());
  Future<List<Cattle>> getAllCattle() async => (await (await database).query('cattle', orderBy: 'purchaseDate DESC')).map((m) => Cattle.fromMap(m)).toList();
  Future<int> updateCattle(Cattle c) async => (await database).update('cattle', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  Future<int> deleteCattle(int id) async => (await database).delete('cattle', where: 'id = ?', whereArgs: [id]);

  // Cattle Record CRUD
  Future<int> insertCattleRecord(CattleRecord r) async => (await database).insert('cattle_records', r.toMap());
  Future<List<CattleRecord>> getAllCattleRecords() async => (await (await database).query('cattle_records', orderBy: 'date DESC')).map((m) => CattleRecord.fromMap(m)).toList();
  Future<int> deleteCattleRecord(int id) async => (await database).delete('cattle_records', where: 'id = ?', whereArgs: [id]);

  // Cattle Sale CRUD
  Future<int> insertCattleSale(CattleSale s) async => (await database).insert('cattle_sales', s.toMap());
  Future<List<CattleSale>> getAllCattleSales() async => (await (await database).query('cattle_sales', orderBy: 'date DESC')).map((m) => CattleSale.fromMap(m)).toList();
  Future<int> updateCattleSale(CattleSale s) async => (await database).update('cattle_sales', s.toMap(), where: 'id = ?', whereArgs: [s.id]);

  // Statistics
  Future<double> getTotalCottonSales() async {
    final r = await (await database).rawQuery('SELECT SUM(totalAmount) as total FROM cotton_sales');
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }
  Future<double> getTotalCattleSales() async {
    final r = await (await database).rawQuery('SELECT SUM(totalAmount) as total FROM cattle_sales');
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }
  Future<double> getTotalFieldActivityCosts() async {
    final r = await (await database).rawQuery('SELECT SUM(cost) as total FROM field_activities');
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }
  Future<double> getTotalCattleRecordCosts() async {
    final r = await (await database).rawQuery('SELECT SUM(cost) as total FROM cattle_records');
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }
  Future<double> getTotalCattlePurchaseCosts() async {
    final r = await (await database).rawQuery('SELECT SUM(purchasePrice) as total FROM cattle');
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }

  // Debt Statistics
  Future<double> getTotalPaymentsForDebt(int debtId) async {
    final r = await (await database).rawQuery('SELECT SUM(amount) as total FROM payments WHERE debtId = ?', [debtId]);
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> getActiveDebtsCount() async {
    final r = await (await database).rawQuery("SELECT COUNT(*) as count FROM debts WHERE status = 'Active'");
    return (r.first['count'] as int?) ?? 0;
  }

  Future<int> getRepaidDebtsCount() async {
    final r = await (await database).rawQuery("SELECT COUNT(*) as count FROM debts WHERE status = 'Repaid'");
    return (r.first['count'] as int?) ?? 0;
  }

  // Cotton Statistics
  Future<Map<String, double>> getCottonProcessingStats() async {
    final r = await (await database).rawQuery('''
      SELECT 
        SUM(lintWeight) as totalLint,
        SUM(ulukWeight) as totalUluk,
        SUM(valaknoWeight) as totalValakno,
        SUM(processedWeight) as totalProcessed,
        COUNT(CASE WHEN isProcessed = 1 THEN 1 END) as processedCount
      FROM cotton_harvests
    ''');
    
    final row = r.first;
    return {
      'totalLint': (row['totalLint'] as num?)?.toDouble() ?? 0,
      'totalUluk': (row['totalUluk'] as num?)?.toDouble() ?? 0,
      'totalValakno': (row['totalValakno'] as num?)?.toDouble() ?? 0,
      'totalProcessed': (row['totalProcessed'] as num?)?.toDouble() ?? 0,
      'processedCount': (row['processedCount'] as num?)?.toDouble() ?? 0,
    };
  }

  Future<Map<String, dynamic>> getCottonSalesStats() async {
    final r = await (await database).rawQuery('''
      SELECT 
        SUM(weight) as totalWeight,
        SUM(units) as totalUnits,
        SUM(totalAmount) as totalRevenue,
        COUNT(*) as salesCount
      FROM cotton_sales
    ''');
    
    final row = r.first;
    return {
      'totalWeight': (row['totalWeight'] as num?)?.toDouble() ?? 0,
      'totalUnits': (row['totalUnits'] as int?) ?? 0,
      'totalRevenue': (row['totalRevenue'] as num?)?.toDouble() ?? 0,
      'salesCount': (row['salesCount'] as int?) ?? 0,
    };
  }

  // Cattle Statistics
  Future<Map<String, dynamic>> getCattleInventoryStats() async {
    final r = await (await database).rawQuery('''
      SELECT 
        COUNT(CASE WHEN status = 'active' THEN 1 END) as activeCount,
        COUNT(CASE WHEN status = 'sold' THEN 1 END) as soldCount,
        COUNT(CASE WHEN status = 'deceased' THEN 1 END) as deceasedCount,
        AVG(CASE WHEN status = 'active' THEN currentWeight - initialWeight END) as avgWeightGain
      FROM cattle
    ''');
    
    final row = r.first;
    return {
      'activeCount': (row['activeCount'] as int?) ?? 0,
      'soldCount': (row['soldCount'] as int?) ?? 0,
      'deceasedCount': (row['deceasedCount'] as int?) ?? 0,
      'avgWeightGain': (row['avgWeightGain'] as num?)?.toDouble() ?? 0,
    };
  }

  Future<Map<String, int>> getCattleByAgeCategory() async {
    final r = await (await database).rawQuery('''
      SELECT 
        ageCategory,
        COUNT(*) as count
      FROM cattle
      WHERE status = 'active'
      GROUP BY ageCategory
    ''');
    
    final Map<String, int> result = {};
    for (final row in r) {
      result[row['ageCategory'] as String] = (row['count'] as int?) ?? 0;
    }
    return result;
  }

  Future<Map<String, dynamic>> getCattleFeedingStats() async {
    final r = await (await database).rawQuery('''
      SELECT 
        feedType,
        SUM(quantity) as totalQuantity,
        SUM(cost) as totalCost,
        COUNT(*) as recordCount
      FROM cattle_records
      WHERE type = 'feeding' AND feedType IS NOT NULL
      GROUP BY feedType
      ORDER BY totalCost DESC
    ''');
    
    return {'feedingByType': r};
  }

  Future<List<Map<String, dynamic>>> getCattleSalesByBuyer() async {
    final r = await (await database).rawQuery('''
      SELECT 
        buyerName,
        COUNT(*) as cattleCount,
        SUM(totalAmount) as totalAmount,
        SUM(paidAmount) as paidAmount,
        AVG(weight) as avgWeight
      FROM cattle_sales
      WHERE buyerName IS NOT NULL
      GROUP BY buyerName
      ORDER BY totalAmount DESC
    ''');
    
    return r;
  }

  Future<Map<String, dynamic>> getCattleSalesComparison() async {
    final r = await (await database).rawQuery('''
      SELECT 
        COUNT(CASE WHEN saleType = 'alive' THEN 1 END) as aliveSales,
        COUNT(CASE WHEN saleType = 'slaughtered' THEN 1 END) as slaughteredSales,
        SUM(CASE WHEN saleType = 'alive' THEN totalAmount ELSE 0 END) as aliveRevenue,
        SUM(CASE WHEN saleType = 'slaughtered' THEN totalAmount ELSE 0 END) as slaughteredRevenue,
        AVG(CASE WHEN saleType = 'slaughtered' AND liveWeight > 0 THEN (weight / liveWeight) * 100 END) as avgMeatYield
      FROM cattle_sales
    ''');
    
    final row = r.first;
    return {
      'aliveSales': (row['aliveSales'] as int?) ?? 0,
      'slaughteredSales': (row['slaughteredSales'] as int?) ?? 0,
      'aliveRevenue': (row['aliveRevenue'] as num?)?.toDouble() ?? 0,
      'slaughteredRevenue': (row['slaughteredRevenue'] as num?)?.toDouble() ?? 0,
      'avgMeatYield': (row['avgMeatYield'] as num?)?.toDouble() ?? 0,
    };
  }

  // Cotton Stock Management CRUD Operations

  // Cotton Type CRUD
  Future<int> insertCottonType(OldCottonType.CottonType t) async => (await database).insert('cotton_types', t.toMap());
  Future<List<OldCottonType.CottonType>> getAllCottonTypes() async => (await (await database).query('cotton_types', orderBy: 'name ASC')).map((m) => OldCottonType.CottonType.fromMap(m)).toList();
  Future<int> updateCottonType(OldCottonType.CottonType t) async => (await database).update('cotton_types', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  Future<int> deleteCottonType(int id) async => (await database).delete('cotton_types', where: 'id = ?', whereArgs: [id]);

  // Cotton Batch CRUD
  Future<int> insertCottonBatch(CottonBatch b) async => (await database).insert('cotton_batches', b.toMap());
  Future<List<CottonBatch>> getAllCottonBatches() async => (await (await database).query('cotton_batches', orderBy: 'arrivalDate DESC')).map((m) => CottonBatch.fromMap(m)).toList();
  Future<List<CottonBatch>> getCottonBatchesByType(int cottonTypeId) async => (await (await database).query('cotton_batches', where: 'cottonTypeId = ?', whereArgs: [cottonTypeId], orderBy: 'arrivalDate DESC')).map((m) => CottonBatch.fromMap(m)).toList();
  Future<List<CottonBatch>> getAvailableCottonBatches() async => (await (await database).query('cotton_batches', where: 'remainingWeightKg > 0 AND remainingUnits > 0', orderBy: 'arrivalDate ASC')).map((m) => CottonBatch.fromMap(m)).toList();
  Future<int> updateCottonBatch(CottonBatch b) async => (await database).update('cotton_batches', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
  Future<int> deleteCottonBatch(int id) async => (await database).delete('cotton_batches', where: 'id = ?', whereArgs: [id]);

  // Cotton Dispatch CRUD
  Future<int> insertCottonDispatch(CottonDispatch d) async => (await database).insert('cotton_dispatches', d.toMap());
  Future<List<CottonDispatch>> getAllCottonDispatches() async => (await (await database).query('cotton_dispatches', orderBy: 'dispatchDate DESC')).map((m) => CottonDispatch.fromMap(m)).toList();
  Future<List<CottonDispatch>> getCottonDispatchesByBatch(int batchId) async => (await (await database).query('cotton_dispatches', where: 'batchId = ?', whereArgs: [batchId], orderBy: 'dispatchDate DESC')).map((m) => CottonDispatch.fromMap(m)).toList();
  Future<int> deleteCottonDispatch(int id) async => (await database).delete('cotton_dispatches', where: 'id = ?', whereArgs: [id]);

  // Cotton Processing CRUD
  Future<int> insertCottonProcessing(CottonProcessing p) async => (await database).insert('cotton_processing', p.toMap());
  Future<List<CottonProcessing>> getAllCottonProcessing() async => (await (await database).query('cotton_processing', orderBy: 'processingDate DESC')).map((m) => CottonProcessing.fromMap(m)).toList();
  Future<int> updateCottonProcessing(CottonProcessing p) async => (await database).update('cotton_processing', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  Future<int> deleteCottonProcessing(int id) async => (await database).delete('cotton_processing', where: 'id = ?', whereArgs: [id]);

  // Buyer CRUD
  Future<int> insertBuyer(Buyer b) async => (await database).insert('buyers', b.toMap());
  Future<List<Buyer>> getAllBuyers() async => (await (await database).query('buyers', orderBy: 'name ASC')).map((m) => Buyer.fromMap(m)).toList();
  Future<Buyer?> getBuyerById(int id) async {
    final maps = await (await database).query('buyers', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Buyer.fromMap(maps.first) : null;
  }
  Future<int> updateBuyer(Buyer b) async => (await database).update('buyers', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
  Future<int> deleteBuyer(int id) async => (await database).delete('buyers', where: 'id = ?', whereArgs: [id]);

  // Cotton Stock Sale CRUD
  Future<int> insertCottonStockSale(CottonStockSale s) async => (await database).insert('cotton_stock_sales', s.toMap());
  Future<List<CottonStockSale>> getAllCottonStockSales() async => (await (await database).query('cotton_stock_sales', orderBy: 'saleDate DESC')).map((m) => CottonStockSale.fromMap(m)).toList();
  Future<List<CottonStockSale>> getCottonStockSalesByBuyer(int buyerId) async => (await (await database).query('cotton_stock_sales', where: 'buyerId = ?', whereArgs: [buyerId], orderBy: 'saleDate DESC')).map((m) => CottonStockSale.fromMap(m)).toList();
  Future<int> updateCottonStockSale(CottonStockSale s) async => (await database).update('cotton_stock_sales', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  Future<int> deleteCottonStockSale(int id) async => (await database).delete('cotton_stock_sales', where: 'id = ?', whereArgs: [id]);

  // Cotton Purchase Registry CRUD Operations
  Future<int> addCottonPurchaseRegistry(CottonPurchaseRegistry registry, List<CottonPurchaseItem> items) async {
    final db = await database;
    return await db.transaction((txn) async {
      // Insert registry
      final registryId = await txn.insert('cotton_purchase_registry', registry.toMap());
      
      // Insert items
      for (final item in items) {
        await txn.insert('cotton_purchase_items', item.copyWith(purchaseId: registryId).toMap());
      }
      
      return registryId;
    });
  }

  Future<List<CottonPurchaseRegistry>> getAllCottonPurchaseRegistries() async {
    final maps = await (await database).query('cotton_purchase_registry', orderBy: 'purchaseDate DESC');
    return maps.map((map) => CottonPurchaseRegistry.fromMap(map)).toList();
  }

  Future<List<CottonPurchaseItem>> getCottonPurchaseItemsByRegistry(int registryId) async {
    final maps = await (await database).query('cotton_purchase_items', 
        where: 'purchaseId = ?', whereArgs: [registryId], orderBy: 'id');
    return maps.map((map) => CottonPurchaseItem.fromMap(map)).toList();
  }

  Future<List<String>> getSupplierNames({String? searchQuery}) async {
    final db = await database;
    String query = 'SELECT DISTINCT supplierName FROM cotton_purchase_registry';
    List<dynamic> args = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query += ' WHERE supplierName LIKE ?';
      args.add('%$searchQuery%');
    }
    
    query += ' ORDER BY supplierName ASC';
    
    final result = await db.rawQuery(query, args);
    return result.map((row) => row['supplierName'] as String).toList();
  }

  Future<List<CottonPurchaseRegistry>> getCottonPurchasesBySupplier(String supplierName) async {
    final maps = await (await database).query('cotton_purchase_registry', 
        where: 'supplierName = ?', whereArgs: [supplierName], orderBy: 'purchaseDate DESC');
    return maps.map((map) => CottonPurchaseRegistry.fromMap(map)).toList();
  }

  // Person and Debt management methods for autocomplete and grouping
  Future<List<String>> getPersonNames({String? searchQuery}) async {
    final db = await database;
    String query = 'SELECT DISTINCT fullName FROM persons';
    List<dynamic> args = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query += ' WHERE fullName LIKE ?';
      args.add('%$searchQuery%');
    }
    
    query += ' ORDER BY fullName ASC';
    
    final result = await db.rawQuery(query, args);
    return result.map((row) => row['fullName'] as String).toList();
  }

  Future<List<Debt>> getDebtsByPersonName(String personName) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT d.* FROM debts d
      JOIN persons p ON d.personId = p.id
      WHERE p.fullName = ?
      ORDER BY d.date DESC
    ''', [personName]);
    return result.map((map) => Debt.fromMap(map)).toList();
  }

  // Cotton sales buyer management methods for autocomplete and grouping
  Future<List<String>> getBuyerNames({String? searchQuery}) async {
    final db = await database;
    String query = 'SELECT DISTINCT buyerName FROM cotton_sales WHERE buyerName IS NOT NULL';
    List<dynamic> args = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query += ' AND buyerName LIKE ?';
      args.add('%$searchQuery%');
    }
    
    query += ' ORDER BY buyerName ASC';
    
    final result = await db.rawQuery(query, args);
    return result.map((row) => row['buyerName'] as String).toList();
  }

  Future<List<CottonSale>> getCottonSalesByBuyer(String buyerName) async {
    final maps = await (await database).query('cotton_sales', 
        where: 'buyerName = ?', whereArgs: [buyerName], orderBy: 'date DESC');
    return maps.map((map) => CottonSale.fromMap(map)).toList();
  }

  // Cotton Stock Statistics
  Future<Map<String, dynamic>> getCottonStockSummary() async {
    final r = await (await database).rawQuery('''
      SELECT 
        ct.name as cottonType,
        SUM(cb.remainingWeightKg) as totalWeight,
        SUM(cb.remainingUnits) as totalUnits,
        COUNT(cb.id) as batchCount
      FROM cotton_batches cb
      JOIN cotton_types ct ON cb.cottonTypeId = ct.id
      WHERE cb.remainingWeightKg > 0 AND cb.remainingUnits > 0
      GROUP BY ct.id, ct.name
      ORDER BY ct.name
    ''');
    
    return {'stockByType': r};
  }

  Future<Map<String, dynamic>> getCottonProcessingStatistics() async {
    final r = await (await database).rawQuery('''
      SELECT 
        COUNT(*) as totalProcessings,
        SUM(totalInputWeight) as totalInputWeight,
        SUM(processedOutputWeight) as totalOutputWeight,
        AVG(yieldPercentage) as avgYield,
        SUM(processedUnits) as totalUnits
      FROM cotton_processing
    ''');
    
    final row = r.first;
    return {
      'totalProcessings': (row['totalProcessings'] as int?) ?? 0,
      'totalInputWeight': (row['totalInputWeight'] as num?)?.toDouble() ?? 0,
      'totalOutputWeight': (row['totalOutputWeight'] as num?)?.toDouble() ?? 0,
      'avgYield': (row['avgYield'] as num?)?.toDouble() ?? 0,
      'totalUnits': (row['totalUnits'] as int?) ?? 0,
    };
  }

  Future<Map<String, dynamic>> getCottonStockSalesSummary() async {
    final r = await (await database).rawQuery('''
      SELECT 
        COUNT(*) as totalSales,
        SUM(units) as totalUnits,
        SUM(totalWeight) as totalWeight,
        SUM(totalAmount) as totalRevenue
      FROM cotton_stock_sales
      WHERE totalAmount IS NOT NULL
    ''');
    
    final row = r.first;
    return {
      'totalSales': (row['totalSales'] as int?) ?? 0,
      'totalUnits': (row['totalUnits'] as int?) ?? 0,
      'totalWeight': (row['totalWeight'] as num?)?.toDouble() ?? 0,
      'totalRevenue': (row['totalRevenue'] as num?)?.toDouble() ?? 0,
    };
  }

  // Helper method to dispatch cotton from batch
  Future<void> dispatchCottonFromBatch(int batchId, double weightKg, int units, String destination) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Get current batch
      final batchResults = await txn.query('cotton_batches', where: 'id = ?', whereArgs: [batchId]);
      if (batchResults.isEmpty) throw Exception('Batch not found');
      
      final batch = CottonBatch.fromMap(batchResults.first);
      
      // Validate dispatch quantities
      if (weightKg > batch.remainingWeightKg) {
        throw Exception('Dispatch weight exceeds remaining weight');
      }
      if (units > batch.remainingUnits) {
        throw Exception('Dispatch units exceed remaining units');
      }
      
      // Create dispatch record
      final dispatch = CottonDispatch(
        batchId: batchId,
        weightKg: weightKg,
        units: units,
        dispatchDate: DateTime.now(),
        destination: destination,
      );
      final dispatchId = await txn.insert('cotton_dispatches', dispatch.toMap());
      
      // Create history entry for dispatch
      final historyProvider = HistoryProvider();
      await historyProvider.addCottonDispatchHistory(dispatch.copyWith(id: dispatchId));
      
      // Update batch remaining quantities
      final updatedBatch = batch.copyWith(
        remainingWeightKg: batch.remainingWeightKg - weightKg,
        remainingUnits: batch.remainingUnits - units,
      );
      await txn.update('cotton_batches', updatedBatch.toMap(), where: 'id = ?', whereArgs: [batchId]);
    });
  }

  // Transaction History CRUD
  Future<int> insertTransactionHistory(TransactionHistory history) async {
    return (await database).insert('transaction_history', history.toMap());
  }

  Future<List<TransactionHistory>> getAllTransactionHistory() async {
    final result = await (await database).query(
      'transaction_history', 
      orderBy: 'date DESC'
    );
    return result.map((m) => TransactionHistory.fromMap(m)).toList();
  }

  Future<List<TransactionHistory>> getFilteredTransactionHistory(HistoryFilter filter) async {
    final db = await database;
    List<String> conditions = [];
    List<dynamic> args = [];

    // Date filtering
    if (filter.fromDate != null) {
      conditions.add('date >= ?');
      args.add(filter.fromDate!.toIso8601String());
    }
    if (filter.toDate != null) {
      conditions.add('date <= ?');
      args.add(filter.toDate!.toIso8601String());
    }

    // Month/Year filtering (priority over fromDate/toDate if specified)
    if (filter.month != null && filter.year != null) {
      final startDate = DateTime(filter.year!, filter.month!);
      final endDate = DateTime(filter.year!, filter.month! + 1).subtract(Duration(days: 1));
      conditions.clear();
      args.clear();
      conditions.add('date >= ? AND date <= ?');
      args.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
    } else if (filter.year != null) {
      final startDate = DateTime(filter.year!);
      final endDate = DateTime(filter.year! + 1).subtract(Duration(days: 1));
      conditions.clear();
      args.clear();
      conditions.add('date >= ? AND date <= ?');
      args.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
    }

    // Category filtering
    if (filter.category != null) {
      conditions.add('category = ?');
      args.add(filter.category!.name);
    }

    // Type filtering
    if (filter.type != null) {
      conditions.add('type = ?');
      args.add(filter.type!.name);
    }

    // Currency filtering
    if (filter.currency != null && filter.currency!.isNotEmpty) {
      conditions.add('currency = ?');
      args.add(filter.currency);
    }

    // Name search
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      conditions.add('(personName LIKE ? OR description LIKE ? OR notes LIKE ?)');
      final searchPattern = '%${filter.searchQuery}%';
      args.addAll([searchPattern, searchPattern, searchPattern]);
    }

    String whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : '';
    
    final result = await db.query(
      'transaction_history',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'date DESC',
    );

    return result.map((m) => TransactionHistory.fromMap(m)).toList();
  }

  Future<List<TransactionHistory>> getTransactionHistoryByCategory(TransactionCategory category) async {
    final result = await (await database).query(
      'transaction_history',
      where: 'category = ?',
      whereArgs: [category.name],
      orderBy: 'date DESC',
    );
    return result.map((m) => TransactionHistory.fromMap(m)).toList();
  }

  Future<List<TransactionHistory>> getTransactionHistoryByPerson(String personName) async {
    final result = await (await database).query(
      'transaction_history',
      where: 'personName LIKE ?',
      whereArgs: ['%$personName%'],
      orderBy: 'date DESC',
    );
    return result.map((m) => TransactionHistory.fromMap(m)).toList();
  }

  Future<int> deleteTransactionHistory(int id) async {
    return (await database).delete('transaction_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTransactionHistoryBySource(String sourceTable, int sourceId) async {
    return (await database).delete(
      'transaction_history', 
      where: 'sourceTable = ? AND sourceId = ?', 
      whereArgs: [sourceTable, sourceId]
    );
  }

  // History Statistics
  Future<Map<String, dynamic>> getTransactionSummaryByCategory() async {
    final result = await (await database).rawQuery('''
      SELECT 
        category,
        type,
        currency,
        COUNT(*) as count,
        SUM(amount) as totalAmount,
        SUM(quantity) as totalQuantity
      FROM transaction_history 
      WHERE amount IS NOT NULL
      GROUP BY category, type, currency
      ORDER BY category, type
    ''');
    
    return {'summaryByCategory': result};
  }

  Future<Map<String, dynamic>> getMonthlyTransactionSummary(int year) async {
    final result = await (await database).rawQuery('''
      SELECT 
        strftime('%m', date) as month,
        category,
        COUNT(*) as count,
        SUM(amount) as totalAmount
      FROM transaction_history 
      WHERE strftime('%Y', date) = ? AND amount IS NOT NULL
      GROUP BY month, category
      ORDER BY month
    ''', [year.toString()]);
    
    return {'monthlyTransactions': result};
  }

  // Barn CRUD Operations
  Future<int> insertBarn(Barn barn) async {
    return (await database).insert('barns', barn.toMap());
  }

  Future<List<Barn>> getAllBarns() async {
    final result = await (await database).query('barns', orderBy: 'name ASC');
    return result.map((m) => Barn.fromMap(m)).toList();
  }

  Future<Barn?> getBarnById(int id) async {
    final result = await (await database).query(
      'barns',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? Barn.fromMap(result.first) : null;
  }

  Future<int> updateBarn(Barn barn) async {
    return (await database).update(
      'barns',
      barn.toMap(),
      where: 'id = ?',
      whereArgs: [barn.id],
    );
  }

  Future<int> deleteBarn(int id) async {
    return (await database).delete('barns', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getCattleCountInBarn(int barnId) async {
    final result = await (await database).rawQuery(
      'SELECT COUNT(*) as count FROM cattle_registry WHERE barnId = ? AND status = ?',
      [barnId, 'active'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalCattleCountInBarn(int barnId) async {
    final result = await (await database).rawQuery(
      'SELECT COUNT(*) as count FROM cattle_registry WHERE barnId = ?',
      [barnId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Barn Expense CRUD Operations
  Future<int> insertBarnExpense(BarnExpense expense) async {
    return (await database).insert('barn_expenses', expense.toMap());
  }

  Future<List<BarnExpense>> getBarnExpensesByBarnId(int barnId) async {
    final result = await (await database).query(
      'barn_expenses',
      where: 'barnId = ?',
      whereArgs: [barnId],
      orderBy: 'expenseDate DESC',
    );
    return result.map((m) => BarnExpense.fromMap(m)).toList();
  }

  Future<BarnExpense?> getBarnExpenseById(int id) async {
    final result = await (await database).query(
      'barn_expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? BarnExpense.fromMap(result.first) : null;
  }

  Future<int> updateBarnExpense(BarnExpense expense) async {
    return (await database).update(
      'barn_expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteBarnExpense(int id) async {
    return (await database).delete(
      'barn_expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Daily Expenses CRUD
  Future<int> insertDailyExpense(Map<String, dynamic> expense) async {
    return (await database).insert('daily_expenses', expense);
  }

  Future<List<Map<String, dynamic>>> getAllDailyExpenses() async {
    return (await database).query('daily_expenses', orderBy: 'expenseDate DESC, id DESC');
  }

  Future<List<Map<String, dynamic>>> getDailyExpensesByDate(String date) async {
    return (await database).query(
      'daily_expenses',
      where: 'expenseDate = ?',
      whereArgs: [date],
      orderBy: 'id DESC',
    );
  }

  Future<Map<String, dynamic>?> getDailyExpenseById(int id) async {
    final result = await (await database).query(
      'daily_expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateDailyExpense(int id, Map<String, dynamic> expense) async {
    return (await database).update(
      'daily_expenses',
      expense,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteDailyExpense(int id) async {
    return (await database).delete(
      'daily_expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalBarnExpenses(int barnId) async {
    final result = await (await database).rawQuery(
      'SELECT SUM(totalCost) as total FROM barn_expenses WHERE barnId = ?',
      [barnId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, dynamic>> getBarnExpensesByType(int barnId) async {
    final result = await (await database).rawQuery('''
      SELECT 
        expenseType,
        SUM(totalCost) as totalCost,
        SUM(quantity) as totalQuantity,
        COUNT(*) as count
      FROM barn_expenses 
      WHERE barnId = ?
      GROUP BY expenseType
    ''', [barnId]);
    
    return {'expensesByType': result};
  }
}

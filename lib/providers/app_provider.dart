import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
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
import '../models/transaction_history.dart';
import 'history_provider.dart';

class AppProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final HistoryProvider _historyProvider = HistoryProvider();

  // Debt Management Data
  List<Person> _persons = [];
  List<Debt> _debts = [];
  
  // Cotton Management Data
  List<Field> _fields = [];
  List<FieldActivity> _fieldActivities = [];
  List<CottonHarvest> _cottonHarvests = [];
  List<CottonSale> _cottonSales = [];
  
  // Cattle Management Data
  List<Cattle> _cattleList = [];
  List<CattleRecord> _cattleRecords = [];
  List<CattleSale> _cattleSales = [];

  bool _isLoading = false;

  // Getters
  List<Person> get persons => _persons;
  List<Debt> get debts => _debts;
  List<Field> get fields => _fields;
  List<FieldActivity> get fieldActivities => _fieldActivities;
  List<CottonHarvest> get cottonHarvests => _cottonHarvests;
  List<CottonSale> get cottonSales => _cottonSales;
  List<Cattle> get cattleList => _cattleList;
  List<CattleRecord> get cattleRecords => _cattleRecords;
  List<CattleSale> get cattleSales => _cattleSales;
  bool get isLoading => _isLoading;

  List<Debt> get activeDebts => _debts.where((d) => d.status == DebtStatus.active).toList();
  List<Cattle> get activeCattle => _cattleList.where((c) => c.status == CattleStatus.active).toList();
  List<Cattle> get soldCattle => _cattleList.where((c) => c.status == CattleStatus.sold).toList();

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _persons = await _db.getAllPersons();
      _debts = await _db.getAllDebts();
      _fields = await _db.getAllFields();
      _fieldActivities = await _db.getAllFieldActivities();
      _cottonHarvests = await _db.getAllCottonHarvests();
      _cottonSales = await _db.getAllCottonSales();
      _cattleList = await _db.getAllCattle();
      _cattleRecords = await _db.getAllCattleRecords();
      _cattleSales = await _db.getAllCattleSales();
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  // ===== DEBT MANAGEMENT =====
  
  /// Adds a new person to the database.
  /// 
  /// Throws [ArgumentError] if the person's name is empty.
  /// Returns the ID of the newly created person.
  Future<int> addPerson(Person person) async {
    // Validation
    if (person.fullName.trim().isEmpty) {
      throw ArgumentError('Person name cannot be empty');
    }
    
    final id = await _db.insertPerson(person);
    await loadAllData();
    return id;
  }

  Future<void> updatePerson(Person person) async {
    // Validation
    if (person.fullName.trim().isEmpty) {
      throw ArgumentError('Person name cannot be empty');
    }
    
    await _db.updatePerson(person);
    await loadAllData();
  }

  /// Deletes a person from the database.
  /// 
  /// Throws [StateError] if the person has any active debts.
  /// This prevents accidental data loss.
  Future<void> deletePerson(int id) async {
    // Check for active debts before deletion
    final personDebts = getDebtsForPerson(id);
    final activeDebts = personDebts.where((d) => d.status == DebtStatus.active);
    if (activeDebts.isNotEmpty) {
      throw StateError('Cannot delete person with ${activeDebts.length} active debt(s). Please settle or delete debts first.');
    }
    
    await _db.deletePerson(id);
    await loadAllData();
  }

  Person? getPersonById(int id) {
    try { return _persons.firstWhere((p) => p.id == id); } catch (e) { return null; }
  }

  /// Add Debt - Core workflow from theoretical design
  /// 
  /// Check if active debt exists for same person, type, and currency:
  /// - If yes → update totalAmount and remainingAmount (consolidate)
  /// - If no → create new debt entry
  /// 
  /// Throws [ArgumentError] if validation fails
  Future<void> addDebt({required int personId, required double amount, required String currency, required DebtType type}) async {
    // Core validation as per theoretical design
    final validationError = Debt.validate(
      totalAmount: amount,
      currency: currency,
      personId: personId,
    );
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    
    // Verify person exists
    final person = getPersonById(personId);
    if (person == null) {
      throw ArgumentError('Person with ID $personId not found');
    }
    
    // Check for existing active debt (exact match: person + type + currency)
    final typeString = type == DebtType.given ? 'Given' : 'Taken';
    final existingDebt = await _db.getActiveDebt(personId, typeString, currency);
    
    if (existingDebt != null) {
      // CONSOLIDATE: Update existing debt instead of creating new one
      final consolidatedDebt = Debt.consolidate(existingDebt, amount);
      await _db.updateDebt(consolidatedDebt);
      await _historyProvider.addDebtHistory(consolidatedDebt, person);
    } else {
      // CREATE: New debt entry
      final newDebt = Debt(
        personId: personId,
        totalAmount: amount,
        remainingAmount: amount,
        currency: currency,
        type: type,
        date: DateTime.now(),
        status: DebtStatus.active,
      );
      
      final debtId = await _db.insertDebt(newDebt);
      await _historyProvider.addDebtHistory(newDebt.copyWith(id: debtId), person);
    }
    await loadAllData();
  }

  /// Partial Repayment - Core workflow from theoretical design
  /// 
  /// Deduct payment from remainingAmount
  /// If remainingAmount == 0, update status to "Repaid"
  /// 
  /// Throws [ArgumentError] if validation fails
  Future<void> makePayment({required Debt debt, required double amount}) async {
    // Process payment using core debt logic
    final updatedDebt = debt.processPayment(amount);
    
    // Simple payment record for history tracking
    final payment = Payment(
      debtId: debt.id!,
      amount: amount,
      date: DateTime.now(),
    );
    
    final paymentId = await _db.insertPayment(payment);
    
    // Update debt with new balance and status
    await _db.updateDebt(updatedDebt);
    
    // Create payment history entry
    final person = getPersonById(debt.personId);
    if (person != null) {
      await _historyProvider.addPaymentHistory(payment.copyWith(id: paymentId), updatedDebt, person);
    }
    
    await loadAllData();
  }

  Future<List<Payment>> getPaymentsForDebt(int debtId) async => await _db.getPaymentsByDebtId(debtId);
  List<Debt> getDebtsForPerson(int personId) => _debts.where((d) => d.personId == personId).toList();
  Future<void> deleteDebt(int id) async { await _db.deleteDebt(id); await loadAllData(); }

  Map<String, Map<String, double>> getDebtTotalsByCurrency() {
    final currencies = _debts.map((d) => d.currency).toSet();
    final result = <String, Map<String, double>>{};
    for (final c in currencies) {
      result[c] = {
        'given': activeDebts.where((d) => d.type == DebtType.given && d.currency == c).fold(0.0, (s, d) => s + d.remainingAmount),
        'taken': activeDebts.where((d) => d.type == DebtType.taken && d.currency == c).fold(0.0, (s, d) => s + d.remainingAmount),
      };
    }
    return result;
  }

  // Get total remaining debt for a specific person
  double getTotalDebtForPerson(int personId, {DebtType? type, String? currency}) {
    var personDebts = getDebtsForPerson(personId).where((d) => d.status == DebtStatus.active);
    
    if (type != null) {
      personDebts = personDebts.where((d) => d.type == type);
    }
    if (currency != null) {
      personDebts = personDebts.where((d) => d.currency == currency);
    }
    
    return personDebts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);
  }

  // ===== COTTON MANAGEMENT =====
  
  /// Adds a new cotton field with validation.
  Future<int> addField(Field field) async {
    if (field.name.trim().isEmpty) {
      throw ArgumentError('Field name cannot be empty');
    }
    if (field.area <= 0) {
      throw ArgumentError('Field area must be greater than zero');
    }
    
    final id = await _db.insertField(field);
    await loadAllData();
    return id;
  }
  
  Future<void> updateField(Field field) async {
    if (field.name.trim().isEmpty) {
      throw ArgumentError('Field name cannot be empty');
    }
    if (field.area <= 0) {
      throw ArgumentError('Field area must be greater than zero');
    }
    
    await _db.updateField(field);
    await loadAllData();
  }
  
  Future<void> deleteField(int id) async { await _db.deleteField(id); await loadAllData(); }
  Field? getFieldById(int id) { try { return _fields.firstWhere((f) => f.id == id); } catch (e) { return null; } }

  Future<void> addFieldActivity(FieldActivity activity) async { 
    final id = await _db.insertFieldActivity(activity); 
    await _historyProvider.addFieldActivityHistory(activity.copyWith(id: id));
    await loadAllData(); 
  }
  Future<void> deleteFieldActivity(int id) async { await _db.deleteFieldActivity(id); await loadAllData(); }
  List<FieldActivity> getActivitiesForField(int fieldId) => _fieldActivities.where((a) => a.fieldId == fieldId).toList();

  /// Adds cotton processing record with validation.
  /// 
  /// Validates:
  /// - Valakno cannot be processed alone
  /// - All weights must be positive
  /// - Processed units must be positive when provided
  /// 
  /// Throws [ArgumentError] if validation fails.
  Future<int> addCottonHarvest(CottonHarvest harvest) async {
    // Validation
    if (!harvest.isValidProcessing) {
      throw ArgumentError('Invalid processing: Valakno cannot be processed alone. Must include Lint or Uluk.');
    }
    
    if (harvest.processedWeight != null && harvest.processedWeight! <= 0) {
      throw ArgumentError('Processed weight must be greater than zero');
    }
    
    if (harvest.processedUnits != null && harvest.processedUnits! <= 0) {
      throw ArgumentError('Processed units must be greater than zero');
    }
    
    final id = await _db.insertCottonHarvest(harvest);
    await loadAllData();
    return id;
  }
  /// Updates cotton processing record with validation.
  Future<void> updateCottonHarvest(CottonHarvest harvest) async {
    // Validation
    if (!harvest.isValidProcessing) {
      throw ArgumentError('Invalid processing: Valakno cannot be processed alone. Must include Lint or Uluk.');
    }
    
    if (harvest.processedWeight != null && harvest.processedWeight! <= 0) {
      throw ArgumentError('Processed weight must be greater than zero');
    }
    
    await _db.updateCottonHarvest(harvest);
    await loadAllData();
  }
  List<CottonHarvest> getHarvestsForField(int fieldId) => _cottonHarvests.where((h) => h.fieldId == fieldId).toList();

  /// Adds cotton sale with validation.
  /// 
  /// For unit-based sales:
  /// - Automatically calculates weight from units × weightPerUnit
  /// - Validates buyer name, units, and weightPerUnit
  /// 
  /// Throws [ArgumentError] if validation fails.
  Future<void> addCottonSale(CottonSale sale) async {
    // Validate sale data
    final validationError = CottonSale.validateSale(
      saleType: sale.saleType,
      units: sale.units,
      weightPerUnit: sale.weightPerUnit,
      weight: sale.weight,
      buyerName: sale.buyerName,
    );
    
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    
    final id = await _db.insertCottonSale(sale);
    await _historyProvider.addCottonSaleHistory(sale.copyWith(id: id));
    await loadAllData();
  }
  Future<void> updateCottonSale(CottonSale sale) async { await _db.updateCottonSale(sale); await loadAllData(); }

  double get totalCottonHarvested => _cottonHarvests.fold(0.0, (s, h) => s + h.rawWeight);
  double get totalCottonProcessed => _cottonHarvests.where((h) => h.isProcessed).fold(0.0, (s, h) => s + (h.processedWeight ?? 0));
  double get totalCottonSalesAmount => _cottonSales.fold(0.0, (s, sale) => s + sale.totalAmount);

  /// Calculate total Lint weight processed
  double get totalLintProcessed => _cottonHarvests.where((h) => h.isProcessed && h.lintWeight != null).fold(0.0, (s, h) => s + h.lintWeight!);
  
  /// Calculate total Uluk weight processed
  double get totalUlukProcessed => _cottonHarvests.where((h) => h.isProcessed && h.ulukWeight != null).fold(0.0, (s, h) => s + h.ulukWeight!);
  
  /// Calculate total Valakno weight processed
  double get totalValaknoProcessed => _cottonHarvests.where((h) => h.isProcessed && h.valaknoWeight != null).fold(0.0, (s, h) => s + h.valaknoWeight!);
  
  /// Calculate average yield percentage for all processed cotton
  double get averageYieldPercentage {
    final processed = _cottonHarvests.where((h) => h.isProcessed && h.yieldPercentage > 0);
    if (processed.isEmpty) return 0;
    return processed.fold(0.0, (s, h) => s + h.yieldPercentage) / processed.length;
  }

  /// Get total units sold
  int get totalCottonUnitsSold => _cottonSales.where((s) => s.units != null).fold(0, (s, sale) => s + sale.units!);
  
  /// Get total weight sold (kg)
  double get totalCottonWeightSold => _cottonSales.where((s) => s.weight != null).fold(0.0, (s, sale) => s + sale.weight!);

  /// Cotton Processing Calculator - does not save data
  /// Returns calculated values for UI display
  Map<String, dynamic> calculateCottonProcessing({
    double? lintWeight,
    double? ulukWeight,
    double? valaknoWeight,
    double? processedWeight,
  }) {
    // Calculate total input weight
    double totalInput = 0.0;
    if (lintWeight != null) totalInput += lintWeight;
    if (ulukWeight != null) totalInput += ulukWeight;
    if (valaknoWeight != null) totalInput += valaknoWeight;

    // Calculate recommended Valakno if Lint and Uluk are approximately equal
    double? recommendedValakno = CottonHarvest.calculateRecommendedValakno(lintWeight, ulukWeight);

    // Calculate yield percentage
    double yieldPercentage = 0.0;
    if (processedWeight != null && totalInput > 0) {
      yieldPercentage = (processedWeight / totalInput) * 100;
    }

    // Validation messages
    List<String> validationErrors = [];
    final hasLint = lintWeight != null && lintWeight > 0;
    final hasUluk = ulukWeight != null && ulukWeight > 0;
    final hasValakno = valaknoWeight != null && valaknoWeight > 0;
    
    if (hasValakno && !hasLint && !hasUluk) {
      validationErrors.add('Valakno cannot be processed alone');
    }

    return {
      'totalInputWeight': totalInput,
      'recommendedValakno': recommendedValakno,
      'yieldPercentage': yieldPercentage,
      'isValid': validationErrors.isEmpty,
      'validationErrors': validationErrors,
    };
  }

  /// Cotton Sales Calculator - calculates weight from units
  /// Returns calculated values for UI display
  Map<String, dynamic> calculateCottonSaleByUnits({
    required int units,
    required double weightPerUnit,
    double? pricePerKg,
  }) {
    if (units <= 0 || weightPerUnit <= 0) {
      return {
        'isValid': false,
        'error': 'Units and weight per unit must be greater than zero',
      };
    }

    final totalWeight = CottonSale.calculateTotalWeight(units, weightPerUnit);
    final totalAmount = pricePerKg != null ? totalWeight * pricePerKg : 0.0;

    return {
      'isValid': true,
      'totalWeight': totalWeight,
      'totalAmount': totalAmount,
      'units': units,
      'weightPerUnit': weightPerUnit,
    };
  }

  // ===== CATTLE MANAGEMENT =====
  
  /// Adds a new cattle with validation.
  /// 
  /// Validates:
  /// - Ear tag is unique and not empty
  /// - Purchase price > 0
  /// - Initial weight > 0
  /// 
  /// Throws [ArgumentError] if validation fails.
  Future<int> addCattle(Cattle cattle) async {
    // Validation
    final validationError = Cattle.validate(
      earTag: cattle.earTag,
      purchasePrice: cattle.purchasePrice,
      initialWeight: cattle.initialWeight,
    );
    
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    
    // Check ear tag uniqueness
    final existing = _cattleList.where((c) => c.earTag.toLowerCase() == cattle.earTag.toLowerCase());
    if (existing.isNotEmpty) {
      throw ArgumentError('Ear tag "${cattle.earTag}" already exists');
    }
    
    final id = await _db.insertCattle(cattle);
    
    // Create history entry for cattle purchase
    await _historyProvider.addCattlePurchaseHistory(cattle.copyWith(id: id));
    
    await loadAllData();
    return id;
  }
  
  Future<void> updateCattle(Cattle cattle) async {
    // Validation
    final validationError = Cattle.validate(
      earTag: cattle.earTag,
      purchasePrice: cattle.purchasePrice,
      initialWeight: cattle.initialWeight,
    );
    
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    
    await _db.updateCattle(cattle);
    await loadAllData();
  }
  
  Future<void> deleteCattle(int id) async { await _db.deleteCattle(id); await loadAllData(); }
  Cattle? getCattleById(int id) { try { return _cattleList.firstWhere((c) => c.id == id); } catch (e) { return null; } }

  /// Adds a cattle record (feeding, medication, weighing) with validation.
  /// 
  /// Auto-updates cattle current weight for weighing records.
  /// 
  /// Throws [ArgumentError] if validation fails.
  Future<void> addCattleRecord(CattleRecord record) async {
    // Validation
    final validationError = CattleRecord.validate(
      type: record.type,
      quantity: record.quantity,
      weight: record.weight,
      feedType: record.feedType,
      medicineName: record.medicineName,
    );
    
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    
    // Verify cattle exists
    final cattle = getCattleById(record.cattleId);
    if (cattle == null) {
      throw ArgumentError('Cattle with ID ${record.cattleId} not found');
    }
    
    final id = await _db.insertCattleRecord(record);
    await _historyProvider.addCattleRecordHistory(record.copyWith(id: id));
    
    // Auto-update current weight for weighing records
    if (record.type == RecordType.weighing && record.weight != null) {
      await _db.updateCattle(cattle.copyWith(currentWeight: record.weight));
    }
    
    await loadAllData();
  }
  
  List<CattleRecord> getRecordsForCattle(int cattleId) => _cattleRecords.where((r) => r.cattleId == cattleId).toList();
  
  /// Get feeding records for cattle
  List<CattleRecord> getFeedingRecordsForCattle(int cattleId) {
    return _cattleRecords.where((r) => r.cattleId == cattleId && r.type == RecordType.feeding).toList();
  }
  
  /// Get medication records for cattle
  List<CattleRecord> getMedicationRecordsForCattle(int cattleId) {
    return _cattleRecords.where((r) => r.cattleId == cattleId && 
        (r.type == RecordType.medication || r.type == RecordType.vaccination)).toList();
  }

  /// Adds a cattle sale with validation.
  /// 
  /// Validates:
  /// - Weight > 0
  /// - Price per kg > 0
  /// - Slaughter date required for slaughtered sales
  /// - Cattle cannot be sold twice
  /// 
  /// Throws [ArgumentError] or [StateError] if validation fails.
  Future<void> addCattleSale(CattleSale sale) async {
    // Validation
    final validationError = CattleSale.validate(
      saleType: sale.saleType,
      weight: sale.weight,
      slaughterDate: sale.slaughterDate,
      liveWeight: sale.liveWeight,
      pricePerKg: sale.pricePerKg,
    );
    
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    
    // Verify cattle exists and is not already sold
    final cattle = getCattleById(sale.cattleId);
    if (cattle == null) {
      throw ArgumentError('Cattle with ID ${sale.cattleId} not found');
    }
    
    if (cattle.status == CattleStatus.sold) {
      throw StateError('Cattle with ear tag "${cattle.earTag}" is already sold');
    }
    
    final id = await _db.insertCattleSale(sale);
    await _historyProvider.addCattleSaleHistory(sale.copyWith(id: id));
    await _db.updateCattle(cattle.copyWith(status: CattleStatus.sold));
    await loadAllData();
  }
  
  Future<void> updateCattleSale(CattleSale sale) async { await _db.updateCattleSale(sale); await loadAllData(); }
  CattleSale? getSaleForCattle(int cattleId) { try { return _cattleSales.firstWhere((s) => s.cattleId == cattleId); } catch (e) { return null; } }

  /// Calculate total cost for a cattle including purchase price, freight, feeding, and medication
  double getTotalCattleCost(int cattleId) {
    final cattle = getCattleById(cattleId);
    if (cattle == null) return 0;
    
    final records = getRecordsForCattle(cattleId);
    final recordsCost = records.fold(0.0, (s, r) => s + r.cost);
    
    return cattle.totalPurchaseCost + recordsCost;  // Includes purchase + freight + records
  }
  
  /// Calculate profit/loss for a sold cattle
  double getCattleProfit(int cattleId) {
    final sale = getSaleForCattle(cattleId);
    if (sale == null) return 0;
    
    final totalCost = getTotalCattleCost(cattleId);
    return sale.totalAmount - totalCost - sale.transportationCost;
  }

  double get totalCattleSalesAmount => _cattleSales.fold(0.0, (s, sale) => s + sale.totalAmount);
  
  /// Get total feeding cost for a cattle
  double getFeedingCostForCattle(int cattleId) {
    return getFeedingRecordsForCattle(cattleId).fold(0.0, (s, r) => s + r.cost);
  }
  
  /// Get total medication cost for a cattle
  double getMedicationCostForCattle(int cattleId) {
    return getMedicationRecordsForCattle(cattleId).fold(0.0, (s, r) => s + r.cost);
  }
  
  /// Get cattle by age category
  List<Cattle> getCattleByAgeCategory(AgeCategory category) {
    return _cattleList.where((c) => c.ageCategory == category && c.status == CattleStatus.active).toList();
  }
  
  /// Get cattle by gender
  List<Cattle> getCattleByGender(CattleGender gender) {
    return _cattleList.where((c) => c.gender == gender && c.status == CattleStatus.active).toList();
  }
  
  /// Calculate average weight gain across all active cattle
  double get averageCattleWeightGain {
    if (activeCattle.isEmpty) return 0;
    return activeCattle.fold(0.0, (s, c) => s + c.weightGain) / activeCattle.length;
  }
  
  /// Get cattle with highest weight gain
  Cattle? get topPerformingCattle {
    if (activeCattle.isEmpty) return null;
    return activeCattle.reduce((a, b) => a.weightGain > b.weightGain ? a : b);
  }

  // ===== STATISTICS =====
  Future<Map<String, double>> getStatistics() async {
    final totalCottonSales = await _db.getTotalCottonSales();
    final totalCattleSales = await _db.getTotalCattleSales();
    final totalFieldCosts = await _db.getTotalFieldActivityCosts();
    final totalCattleRecordCosts = await _db.getTotalCattleRecordCosts();
    final totalCattlePurchases = await _db.getTotalCattlePurchaseCosts();
    final totalIncome = totalCottonSales + totalCattleSales;
    final totalCosts = totalFieldCosts + totalCattleRecordCosts + totalCattlePurchases;
    return {
      'totalCottonSales': totalCottonSales, 'totalCattleSales': totalCattleSales,
      'totalFieldCosts': totalFieldCosts, 'totalCattleRecordCosts': totalCattleRecordCosts,
      'totalCattlePurchases': totalCattlePurchases, 'totalIncome': totalIncome,
      'totalCosts': totalCosts, 'profit': totalIncome - totalCosts,
    };
  }
}

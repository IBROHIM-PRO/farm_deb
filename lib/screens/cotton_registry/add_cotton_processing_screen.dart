import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cotton_registry_provider.dart';
import '../../models/cotton_purchase_registry.dart';
import '../../models/cotton_purchase_item.dart';
import '../../models/cotton_processing_registry.dart';
import '../../models/cotton_processing_input.dart';
import '../../models/cotton_processing_output.dart';
import '../../models/cotton_processing_calculator.dart';

/// Add Cotton Processing Screen - Process cotton from purchases
/// Implements the complex processing formulas and automatic calculations
class AddCottonProcessingScreen extends StatefulWidget {
  const AddCottonProcessingScreen({super.key});

  @override
  State<AddCottonProcessingScreen> createState() => _AddCottonProcessingScreenState();
}

class _AddCottonProcessingScreenState extends State<AddCottonProcessingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for input weights
  final _lintWeightController = TextEditingController();
  final _ulukWeightController = TextEditingController();
  final _valaknoWeightController = TextEditingController();
  final _extraValaknoController = TextEditingController();
  final _notesController = TextEditingController();

  // Selected purchase and date
  CottonPurchaseRegistry? selectedPurchase;
  DateTime processingDate = DateTime.now();
  
  // Processing calculations
  double calculatedValakno = 0;
  bool isValaknoManualOverride = false;
  ProcessingType processingType = ProcessingType.singleCottonType;
  
  // Available stock from selected purchase
  Map<CottonType, double> availableStock = {};
  Map<CottonType, int> availableUnits = {};
  
  // Output batches
  List<CottonProcessingOutput> outputBatches = [];
  
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  @override
  void dispose() {
    _lintWeightController.dispose();
    _ulukWeightController.dispose();
    _valaknoWeightController.dispose();
    _extraValaknoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _setupListeners() {
    _lintWeightController.addListener(_calculateProcessing);
    _ulukWeightController.addListener(_calculateProcessing);
    _valaknoWeightController.addListener(_onValaknoManualChange);
  }

  void _calculateProcessing() {
    final lintKg = double.tryParse(_lintWeightController.text) ?? 0;
    final ulukKg = double.tryParse(_ulukWeightController.text) ?? 0;
    final valaknoKg = double.tryParse(_valaknoWeightController.text) ?? 0;
    
    setState(() {
      processingType = CottonProcessingCalculator.determineProcessingType(
        hasLint: lintKg > 0,
        hasUluk: ulukKg > 0,
        hasValakno: valaknoKg > 0,
      );
      
      // Auto-calculate Valakno for three cotton types processing
      if (processingType == ProcessingType.threeCottonTypes && !isValaknoManualOverride) {
        calculatedValakno = CottonProcessingCalculator.calculateAutoValakno(
          lintKg: lintKg,
          ulukKg: ulukKg,
        );
        _valaknoWeightController.text = calculatedValakno.toStringAsFixed(1);
      }
    });
  }

  void _onValaknoManualChange() {
    // If user manually changes Valakno, mark as override
    if (_valaknoWeightController.text.isNotEmpty) {
      final manualValue = double.tryParse(_valaknoWeightController.text) ?? 0;
      if ((manualValue - calculatedValakno).abs() > 0.1) {
        setState(() => isValaknoManualOverride = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Коркарди пахта'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Purchase Selection
              _buildSectionTitle('Интихоби харидан'),
              _buildPurchaseSelection(),
              const SizedBox(height: 24),
              
              // Processing Inputs
              _buildSectionTitle('Пахтаи дохилӣ'),
              _buildProcessingInputs(),
              const SizedBox(height: 24),
              
              // Processing Type Display
              _buildProcessingTypeCard(),
              const SizedBox(height: 24),
              
              // Output Batches
              _buildSectionTitle('Натиҷаи коркард'),
              _buildOutputBatches(),
              const SizedBox(height: 24),
              
              // Processing Date and Notes
              _buildDateAndNotes(),
              const SizedBox(height: 32),
              
              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPurchaseSelection() {
    return Consumer<CottonRegistryProvider>(
      builder: (context, provider, _) {
        final availablePurchases = provider.purchaseRegistry
            .where((p) => _hasPurchaseAvailableStock(provider, p.id!))
            .toList();
            
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<CottonPurchaseRegistry>(
                  value: selectedPurchase,
                  decoration: const InputDecoration(
                    labelText: 'Харидани интихобшуда',
                    border: OutlineInputBorder(),
                  ),
                  items: availablePurchases.map((purchase) {
                    final summary = provider.getPurchaseSummary(purchase.id!);
                    return DropdownMenuItem(
                      value: purchase,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(purchase.supplierName),
                          Text(
                            DateFormat('dd/MM/yyyy', 'en_US').format(purchase.purchaseDate),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _onPurchaseSelected,
                  validator: (value) => value == null ? 'Харидан интихоб кунед' : null,
                ),
                
                // Available Stock Display
                if (selectedPurchase != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Пахтаи мавҷуд:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: availableStock.entries.map((entry) {
                      return Chip(
                        label: Text(
                          '${_getCottonTypeName(entry.key)}: ${entry.value.toStringAsFixed(1)} кг',
                        ),
                        backgroundColor: _getCottonTypeColor(entry.key).withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProcessingInputs() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Lint Input
            TextFormField(
              controller: _lintWeightController,
              decoration: InputDecoration(
                labelText: 'Линт (кг)',
                suffixText: 'кг',
                border: const OutlineInputBorder(),
                enabled: availableStock[CottonType.lint] != null,
              ),
              keyboardType: TextInputType.number,
              validator: (value) => _validateInput(
                value, 
                CottonType.lint, 
                availableStock[CottonType.lint] ?? 0,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Uluk Input
            TextFormField(
              controller: _ulukWeightController,
              decoration: InputDecoration(
                labelText: 'Улук (кг)',
                suffixText: 'кг',
                border: const OutlineInputBorder(),
                enabled: availableStock[CottonType.uluk] != null,
              ),
              keyboardType: TextInputType.number,
              validator: (value) => _validateInput(
                value, 
                CottonType.uluk, 
                availableStock[CottonType.uluk] ?? 0,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Valakno Input
            TextFormField(
              controller: _valaknoWeightController,
              decoration: InputDecoration(
                labelText: processingType == ProcessingType.threeCottonTypes
                    ? 'Валакно (автоматӣ)'
                    : 'Валакно (кг)',
                suffixText: 'кг',
                border: const OutlineInputBorder(),
                enabled: availableStock[CottonType.valakno] != null,
                helperText: processingType == ProcessingType.threeCottonTypes
                    ? 'Ба таври автоматӣ ҳисоб карда мешавад'
                    : null,
              ),
              keyboardType: TextInputType.number,
              validator: (value) => _validateInput(
                value, 
                CottonType.valakno, 
                availableStock[CottonType.valakno] ?? 0,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Extra Valakno Input
            TextFormField(
              controller: _extraValaknoController,
              decoration: const InputDecoration(
                labelText: 'Валакнои иловагӣ (кг)',
                suffixText: 'кг',
                border: OutlineInputBorder(),
                helperText: 'Барои ҳисобдорӣ, формулаҳоро таъсир намекунад',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingTypeCard() {
    return Card(
      color: Colors.purple.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Навъи коркард: ${processingType.display}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Formula Display
            _buildFormulaDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulaDisplay() {
    final lintKg = double.tryParse(_lintWeightController.text) ?? 0;
    final ulukKg = double.tryParse(_ulukWeightController.text) ?? 0;
    final valaknoKg = double.tryParse(_valaknoWeightController.text) ?? 0;
    
    switch (processingType) {
      case ProcessingType.threeCottonTypes:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Формула: (Линт + Улук) ≈ 2, Валакно ≈ 0.5'),
            const SizedBox(height: 8),
            Text('Ҳисоб: (${lintKg.toStringAsFixed(1)} + ${ulukKg.toStringAsFixed(1)}) ÷ 4 = ${calculatedValakno.toStringAsFixed(1)} кг'),
            if (isValaknoManualOverride)
              const Text(
                'Дастӣ тағйир дода шуд',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
          ],
        );
      case ProcessingType.twoCottonTypes:
        final primaryKg = lintKg > 0 ? lintKg : ulukKg;
        final expectedOutput = CottonProcessingCalculator.calculateTwoCottonOutput(
          primaryCottonKg: primaryKg,
          valaknoKg: valaknoKg,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Формула: Асосӣ ≈ 2, Валакно ≈ 1'),
            Text('Натиҷаи интизор: ${expectedOutput.toStringAsFixed(1)} кг'),
          ],
        );
      case ProcessingType.singleCottonType:
        final cottonKg = lintKg > 0 ? lintKg : ulukKg;
        final expectedOutput = CottonProcessingCalculator.calculateSingleCottonOutput(
          cottonKg: cottonKg,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Формула: 1 → 0.5'),
            Text('Натиҷаи интизор: ${expectedOutput.toStringAsFixed(1)} кг'),
          ],
        );
    }
  }

  Widget _buildOutputBatches() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Дастаҳои натиҷа:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addOutputBatch,
                  icon: const Icon(Icons.add),
                  label: const Text('Дастаи нав'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (outputBatches.isEmpty)
              const Text(
                'Дастаҳои натиҷа илова кунед',
                style: TextStyle(color: Colors.grey),
              )
            else
              Column(
                children: outputBatches.asMap().entries.map((entry) {
                  final index = entry.key;
                  final batch = entry.value;
                  return _buildOutputBatchCard(batch, index);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputBatchCard(CottonProcessingOutput batch, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getCottonTypeColor(batch.cottonType),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCottonTypeName(batch.cottonType),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${batch.numberOfUnits} дона × ${batch.batchWeightPerUnit.toStringAsFixed(1)} кг = ${batch.totalWeight.toStringAsFixed(1)} кг',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeOutputBatch(index),
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateAndNotes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Санаи коркард'),
              subtitle: Text(DateFormat('dd/MM/yyyy', 'en_US').format(processingDate)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _selectProcessingDate,
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Қайдҳо (ихтиёрӣ)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _resetForm,
            child: const Text('Пок кардан'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : _saveProcessing,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Сабт кардан'),
          ),
        ),
      ],
    );
  }

  // Helper method to check if purchase has available stock for processing
  bool _hasPurchaseAvailableStock(CottonRegistryProvider provider, int purchaseId) {
    // Get purchase items for this purchase
    final purchaseItems = provider.purchaseItems
        .where((item) => item.purchaseId == purchaseId)
        .toList();
    
    if (purchaseItems.isEmpty) return false;
    
    // Check if any items have remaining stock
    // For now, assume items are available unless fully processed
    // This would normally check against processing inputs to calculate remaining stock
    return true; // Simplified for now
  }
  
  // Helper method to get available stock for a purchase
  Map<CottonType, double> _getAvailableStockForPurchase(CottonRegistryProvider provider, int purchaseId) {
    final purchaseItems = provider.purchaseItems
        .where((item) => item.purchaseId == purchaseId)
        .toList();
    
    final stock = <CottonType, double>{};
    
    for (final item in purchaseItems) {
      // Calculate available weight (total weight minus used in processing)
      double usedWeight = provider.processingInputs
          .where((input) => input.sourcePurchaseItemId == item.id)
          .fold(0.0, (sum, input) => sum + input.weightUsed);
      
      double availableWeight = item.weight - usedWeight;
      if (availableWeight > 0) {
        stock[item.cottonType] = (stock[item.cottonType] ?? 0) + availableWeight;
      }
    }
    
    return stock;
  }

  void _onPurchaseSelected(CottonPurchaseRegistry? purchase) {
    setState(() {
      selectedPurchase = purchase;
      if (purchase != null) {
        final provider = context.read<CottonRegistryProvider>();
        availableStock = _getAvailableStockForPurchase(provider, purchase.id!);
      }
    });
  }

  String? _validateInput(String? value, CottonType type, double available) {
    if (value == null || value.isEmpty) return null;
    
    final input = double.tryParse(value);
    if (input == null || input < 0) return 'Нодуруст';
    if (input > available) return 'Аз мавҷуд зиёд';
    
    return null;
  }

  void _addOutputBatch() {
    showDialog(
      context: context,
      builder: (ctx) => _buildAddBatchDialog(),
    );
  }

  Widget _buildAddBatchDialog() {
    final typeController = ValueNotifier<CottonType?>(null);
    final batchSizeController = TextEditingController();
    final unitsController = TextEditingController();
    
    return AlertDialog(
      title: const Text('Дастаи натиҷа'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<CottonType?>(
            valueListenable: typeController,
            builder: (context, type, _) {
              return DropdownButtonFormField<CottonType>(
                value: type,
                decoration: const InputDecoration(
                  labelText: 'Навъи пахта',
                ),
                items: CottonType.values.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(_getCottonTypeName(t)),
                  );
                }).toList(),
                onChanged: (value) => typeController.value = value,
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: batchSizeController,
            decoration: const InputDecoration(
              labelText: 'Вазни як дона (кг)',
              suffixText: 'кг',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: unitsController,
            decoration: const InputDecoration(
              labelText: 'Шумораи донаҳо',
              suffixText: 'дона',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Бекор'),
        ),
        ElevatedButton(
          onPressed: () {
            if (typeController.value != null &&
                batchSizeController.text.isNotEmpty &&
                unitsController.text.isNotEmpty) {
              final batchSize = double.parse(batchSizeController.text);
              final units = int.parse(unitsController.text);
              final totalWeight = batchSize * units;
              
              final newBatch = CottonProcessingOutput(
                processingId: 0, // Will be set when saving
                cottonType: typeController.value!,
                batchWeightPerUnit: batchSize,
                numberOfUnits: units,
                totalWeight: totalWeight,
              );
              
              setState(() => outputBatches.add(newBatch));
              Navigator.pop(context);
            }
          },
          child: const Text('Илова'),
        ),
      ],
    );
  }

  void _removeOutputBatch(int index) {
    setState(() => outputBatches.removeAt(index));
  }

  Future<void> _selectProcessingDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: processingDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date != null) {
      setState(() => processingDate = date);
    }
  }

  void _resetForm() {
    _lintWeightController.clear();
    _ulukWeightController.clear();
    _valaknoWeightController.clear();
    _extraValaknoController.clear();
    _notesController.clear();
    
    setState(() {
      selectedPurchase = null;
      processingDate = DateTime.now();
      calculatedValakno = 0;
      isValaknoManualOverride = false;
      availableStock.clear();
      outputBatches.clear();
    });
  }

  Future<void> _saveProcessing() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedPurchase == null) return;
    if (outputBatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Дастаҳои натиҷа илова кунед')),
      );
      return;
    }

    setState(() => isLoading = true);
    
    try {
      final provider = context.read<CottonRegistryProvider>();
      
      // Create processing registry
      final processing = CottonProcessingRegistry(
        linkedPurchaseId: selectedPurchase!.id!,
        processingDate: processingDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      
      // Create input records
      final inputs = <CottonProcessingInput>[];
      
      if (_lintWeightController.text.isNotEmpty) {
        inputs.add(CottonProcessingInput(
          processingId: 0, // Will be set by provider
          cottonType: CottonType.lint,
          unitsUsed: 0, // TODO: Calculate from weight
          weightUsed: double.parse(_lintWeightController.text),
          sourcePurchaseItemId: 0, // Will be resolved by provider
        ));
      }
      
      if (_ulukWeightController.text.isNotEmpty) {
        inputs.add(CottonProcessingInput(
          processingId: 0,
          cottonType: CottonType.uluk,
          unitsUsed: 0,
          weightUsed: double.parse(_ulukWeightController.text),
          sourcePurchaseItemId: 0,
        ));
      }
      
      if (_valaknoWeightController.text.isNotEmpty) {
        inputs.add(CottonProcessingInput(
          processingId: 0,
          cottonType: CottonType.valakno,
          unitsUsed: 0,
          weightUsed: double.parse(_valaknoWeightController.text),
          sourcePurchaseItemId: 0,
        ));
      }
      
      // Save processing with inputs and outputs
      await provider.addCottonProcessing(
        registry: processing,
        inputs: inputs,
        outputs: outputBatches,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Коркард бо муваффақият сабт шуд'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хато: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _getCottonTypeName(CottonType type) {
    switch (type) {
      case CottonType.lint: return 'Линт';
      case CottonType.uluk: return 'Улук';
      case CottonType.valakno: return 'Валакно';
    }
  }

  Color _getCottonTypeColor(CottonType type) {
    switch (type) {
      case CottonType.lint: return Colors.green;
      case CottonType.uluk: return Colors.blue;
      case CottonType.valakno: return Colors.orange;
    }
  }
}

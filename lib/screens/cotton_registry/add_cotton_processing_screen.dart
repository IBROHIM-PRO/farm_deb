import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/cotton_purchase_registry.dart';
import '../../models/cotton_processing_registry.dart';
import '../../providers/cotton_registry_provider.dart';
import '../../providers/cotton_warehouse_provider.dart';
import '../../models/cotton_processing_input.dart';
import '../../models/cotton_processing_output.dart';
import '../../models/cotton_purchase_item.dart';
import '../../models/raw_cotton_warehouse.dart';
import '../../models/processed_cotton_warehouse.dart';

/// Add Cotton Processing Screen - Process cotton from purchases
/// Implements the complex processing formulas and automatic calculations
class AddCottonProcessingScreen extends StatefulWidget {
  const AddCottonProcessingScreen({super.key});

  @override
  State<AddCottonProcessingScreen> createState() => _AddCottonProcessingScreenState();
}

class _AddCottonProcessingScreenState extends State<AddCottonProcessingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  // Auto-selected purchase and current date
  CottonPurchaseRegistry? selectedPurchase;
  DateTime processingDate = DateTime.now();
  
  // Raw cotton processing inputs
  final _lintWeightController = TextEditingController();
  final _ulukWeightController = TextEditingController();
  final _valaknoWeightController = TextEditingController();
  final _lintPiecesController = TextEditingController();
  final _ulukPiecesController = TextEditingController();
  final _valaknoPiecesController = TextEditingController();
  bool isValaknoManualOverride = false;
  
  // Simple batch output for processed cotton (modal)
  final _weightController = TextEditingController();
  final _piecesController = TextEditingController();
  final _modalFormKey = GlobalKey<FormState>();
  
  // Output batches (processed cotton only)
  List<CottonProcessingOutput> outputBatches = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _autoSelectPurchase();
    _setupListeners();
  }

  @override
  void dispose() {
    _lintWeightController.dispose();
    _ulukWeightController.dispose();
    _valaknoWeightController.dispose();
    _lintPiecesController.dispose();
    _ulukPiecesController.dispose();
    _valaknoPiecesController.dispose();
    _weightController.dispose();
    _piecesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _autoSelectPurchase() {
    // Auto-select the first available purchase
    final provider = context.read<CottonRegistryProvider>();
    final availablePurchases = provider.purchaseRegistry.where((p) => p.id != null).toList();
    
    if (availablePurchases.isNotEmpty) {
      setState(() {
        selectedPurchase = availablePurchases.first;
        processingDate = DateTime.now(); // Set to current date
      });
    }
  }

  void _setupListeners() {
    _lintWeightController.addListener(_calculateValakno);
    _ulukWeightController.addListener(_calculateValakno);
    _valaknoWeightController.addListener(_onValaknoManualChange);
  }

  void _calculateValakno() {
    if (isValaknoManualOverride) return;
    
    final lintKg = double.tryParse(_lintWeightController.text) ?? 0;
    final ulukKg = double.tryParse(_ulukWeightController.text) ?? 0;
    
    double calculatedValakno = 0;
    
    if (lintKg > 0 && ulukKg > 0) {
      // Both types: (lint + uluk) × 0.25
      calculatedValakno = (lintKg + ulukKg) * 0.25;
    } else if (lintKg > 0) {
      // Only lint: lint × 0.5
      calculatedValakno = lintKg * 0.5;
    } else if (ulukKg > 0) {
      // Only uluk: uluk × 0.5
      calculatedValakno = ulukKg * 0.5;
    }
    
    if (calculatedValakno > 0) {
      setState(() {
        _valaknoWeightController.text = calculatedValakno.toStringAsFixed(2);
      });
    }
  }

  void _onValaknoManualChange() {
    // Mark as manual override if user changes the calculated value
    setState(() {
      isValaknoManualOverride = true;
    });
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
              // Raw cotton processing inputs
              _buildSectionTitle('Пахтаи хом барои коркард'),
              _buildRawCottonInputs(),
              const SizedBox(height: 24),
              
              // Processing summary and percentage
              _buildProcessingSummary(),
              const SizedBox(height: 24),
              
              // Output batches list with inline add button
              _buildOutputBatches(),
              const SizedBox(height: 24),
              
              // Notes only (date is automatic)
              _buildNotesSection(),
              const SizedBox(height: 32),
              
              // Action buttons
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

  Widget _buildRawCottonInputs() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Lint Input Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _lintWeightController,
                    decoration: const InputDecoration(
                      labelText: 'Линт (кг)',
                      border: OutlineInputBorder(),
                      suffixText: 'кг',
                      hintText: 'Вазн',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isNotEmpty == true) {
                        final v = double.tryParse(value!);
                        if (v == null || v <= 0) return 'Вазни дуруст ворид кунед';
                        
                        // Cross-validate: if weight is entered, pieces must also be entered
                        if (_lintPiecesController.text.trim().isEmpty) {
                          return 'Агар вазн ворид шавад, адад низ зарур аст';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _lintPiecesController,
                    decoration: const InputDecoration(
                      labelText: 'Адад',
                      border: OutlineInputBorder(),
                      suffixText: 'дона',
                      hintText: 'Шумора',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isNotEmpty == true) {
                        final v = int.tryParse(value!);
                        if (v == null || v <= 0) return 'Адади дуруст ворид кунед';
                        
                        // Cross-validate: if pieces are entered, weight must also be entered
                        if (_lintWeightController.text.trim().isEmpty) {
                          return 'Агар адад ворид шавад, вазн низ зарур аст';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Uluk Input Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _ulukWeightController,
                    decoration: const InputDecoration(
                      labelText: 'Улук (кг)',
                      border: OutlineInputBorder(),
                      suffixText: 'кг',
                      hintText: 'Вазн',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isNotEmpty == true) {
                        final v = double.tryParse(value!);
                        if (v == null || v <= 0) return 'Вазни дуруст ворид кунед';
                        
                        // Cross-validate: if weight is entered, pieces must also be entered
                        if (_ulukPiecesController.text.trim().isEmpty) {
                          return 'Агар вазн ворид шавад, адад низ зарур аст';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _ulukPiecesController,
                    decoration: const InputDecoration(
                      labelText: 'Адад',
                      border: OutlineInputBorder(),
                      suffixText: 'дона',
                      hintText: 'Шумора',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isNotEmpty == true) {
                        final v = int.tryParse(value!);
                        if (v == null || v <= 0) return 'Адади дуруст ворид кунед';
                        
                        // Cross-validate: if pieces are entered, weight must also be entered
                        if (_ulukWeightController.text.trim().isEmpty) {
                          return 'Агар адад ворид шавад, вазн низ зарур аст';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Valakno Input Row (with auto-calculation)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _valaknoWeightController,
                    decoration: InputDecoration(
                      labelText: 'Валакно (кг)',
                      border: const OutlineInputBorder(),
                      suffixText: 'кг',
                      hintText: 'Автоматӣ',
                      helperText: isValaknoManualOverride ? 
                        'Дастӣ тағйир дода шуд' : 
                        'Автоматӣ: ${_getValaknoFormula()}',
                      helperStyle: TextStyle(
                        color: isValaknoManualOverride ? Colors.orange : Colors.blue,
                        fontSize: 11,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isNotEmpty == true) {
                        final v = double.tryParse(value!);
                        if (v == null || v <= 0) return 'Вазни дуруст ворид кунед';
                        
                        // Cross-validate: if weight is entered, pieces must also be entered
                        if (_valaknoPiecesController.text.trim().isEmpty) {
                          return 'Агар вазн ворид шавад, адад низ зарур аст';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _valaknoPiecesController,
                    decoration: const InputDecoration(
                      labelText: 'Адад',
                      border: OutlineInputBorder(),
                      suffixText: 'дона',
                      hintText: 'Шумора',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isNotEmpty == true) {
                        final v = int.tryParse(value!);
                        if (v == null || v <= 0) return 'Адади дуруст ворид кунед';
                        
                        // Cross-validate: if pieces are entered, weight must also be entered
                        if (_valaknoWeightController.text.trim().isEmpty) {
                          return 'Агар адад ворид шавад, вазн низ зарур аст';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            if (isValaknoManualOverride) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    isValaknoManualOverride = false;
                    _calculateValakno();
                  });
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Ба ҳисоби автоматӣ баргардонед'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getValaknoFormula() {
    final lintKg = double.tryParse(_lintWeightController.text) ?? 0;
    final ulukKg = double.tryParse(_ulukWeightController.text) ?? 0;
    
    if (lintKg > 0 && ulukKg > 0) {
      return '(${lintKg.toStringAsFixed(1)} + ${ulukKg.toStringAsFixed(1)}) × 0.25';
    } else if (lintKg > 0) {
      return '${lintKg.toStringAsFixed(1)} × 0.5';
    } else if (ulukKg > 0) {
      return '${ulukKg.toStringAsFixed(1)} × 0.5';
    }
    return 'Линт ё улук ворид кунед';
  }

  double get _totalRawCottonWeight {
    final lintKg = double.tryParse(_lintWeightController.text) ?? 0;
    final ulukKg = double.tryParse(_ulukWeightController.text) ?? 0;
    final valaknoKg = double.tryParse(_valaknoWeightController.text) ?? 0;
    return lintKg + ulukKg + valaknoKg;
  }

  double get _totalProcessedCottonWeight {
    return outputBatches.fold(0.0, (sum, batch) => sum + batch.totalWeight);
  }

  double get _processingPercentage {
    final totalRaw = _totalRawCottonWeight;
    if (totalRaw == 0) return 0;
    return (_totalProcessedCottonWeight / totalRaw) * 100;
  }

  Widget _buildProcessingSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ҷамъбасти коркард',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ҳамагӣ пахтаи хом:'),
                Text(
                  '${_totalRawCottonWeight.toStringAsFixed(2)} кг (100%)',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Пахтаи коркардшуда:'),
                Text(
                  '${_totalProcessedCottonWeight.toStringAsFixed(2)} кг (${_processingPercentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _processingPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              'Фоизи коркард: ${_processingPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }


  void _showAddProcessedCottonModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Дастаи пахтаи коркардшуда'),
        content: Form(
          key: _modalFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Вазни як дона (кг)',
                border: OutlineInputBorder(),
                suffixText: 'кг',
                hintText: '10, 15, 20, 25, 30, 35, 40, 45, 50 кг',
                errorMaxLines: 2,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Лутфан вазнро ворид кунед';
                }
                
                final v = double.tryParse(value.trim());
                if (v == null || v <= 0) {
                  return 'Рақами дуруст ворид кунед';
                }
                
                // Check if weight is one of the allowed values (10, 15, 20, 25, 30, 35, 40, 45, 50)
                final allowedWeights = [10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 50.0];
                if (!allowedWeights.contains(v)) {
                  return 'Вазн бояд аз 10, 15, 20, 25, 30, 35, 40, 45, 50 кг бошад';
                }
                
                // Only validate against raw cotton if raw cotton is entered
                final pieces = int.tryParse(_piecesController.text.trim()) ?? 0;
                if (pieces > 0) {
                  final batchTotalWeight = v * pieces;
                  final currentProcessedWeight = _totalProcessedCottonWeight;
                  final newTotalProcessedWeight = currentProcessedWeight + batchTotalWeight;
                  final rawCottonWeight = _totalRawCottonWeight;
                  
                  // Only check if raw cotton has been entered (> 0)
                  if (rawCottonWeight > 0 && newTotalProcessedWeight > rawCottonWeight) {
                    return 'Ҳамагӣ коркардшуда аз пахтаи хом зиёд нашавад';
                  }
                }
                
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _piecesController,
              decoration: const InputDecoration(
                labelText: 'Шумораи донаҳо',
                border: OutlineInputBorder(),
                suffixText: 'дона',
                hintText: 'Шумораи донаҳои коркардшуда',
                errorMaxLines: 2,
              ),
              keyboardType: TextInputType.number,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Лутфан шумораро ворид кунед';
                }
                
                final v = int.tryParse(value.trim());
                if (v == null || v <= 0) {
                  return 'Рақами дуруст ворид кунед';
                }
                
                // Only validate against raw cotton if raw cotton is entered and weight is valid
                final weightText = _weightController.text.trim();
                if (weightText.isNotEmpty) {
                  final weight = double.tryParse(weightText);
                  if (weight != null && weight > 0) {
                    // Check if weight is allowed first
                    final allowedWeights = [10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 50.0];
                    if (allowedWeights.contains(weight)) {
                      final batchTotalWeight = weight * v;
                      final currentProcessedWeight = _totalProcessedCottonWeight;
                      final newTotalProcessedWeight = currentProcessedWeight + batchTotalWeight;
                      final rawCottonWeight = _totalRawCottonWeight;
                      
                      // Only check if raw cotton has been entered (> 0)
                      if (rawCottonWeight > 0 && newTotalProcessedWeight > rawCottonWeight) {
                        return 'Ҳамагӣ коркардшуда аз пахтаи хом зиёд нашавад';
                      }
                    }
                  }
                }
                
                return null;
              },
            ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Бекор'),
          ),
          ElevatedButton(
            onPressed: () {
              // Use form validation instead of manual checks
              if (_modalFormKey.currentState?.validate() ?? false) {
                _addSimpleBatch();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Илова кардан'),
          ),
        ],
      ),
    );
  }


  void _addSimpleBatch() {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.parse(_weightController.text);
    final pieces = int.parse(_piecesController.text);
    final totalWeight = weight * pieces;

    setState(() {
      outputBatches.add(CottonProcessingOutput(
        processingId: 0,
        cottonType: CottonType.lint, // Fixed type - processed cotton
        batchWeightPerUnit: weight,
        numberOfUnits: pieces,
        totalWeight: totalWeight,
      ));
      _weightController.clear();
      _piecesController.clear();
    });
  }

  Widget _buildOutputBatches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with title and add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Дастаҳои илованамуда:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            ElevatedButton(
              onPressed: _showAddProcessedCottonModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Icon(Icons.add, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Show empty state or batch list
        if (outputBatches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Ҳеҷ баста илова нашудааст',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          )
        else
        ...outputBatches.asMap().entries.map((entry) {
          final index = entry.key;
          final batch = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.inventory, color: Colors.white),
              ),
              title: Text('Пахтаи коркардшуда'),
              subtitle: Text(
                '${batch.numberOfUnits} дона × ${batch.batchWeightPerUnit.toStringAsFixed(1)} кг = ${batch.totalWeight.toStringAsFixed(1)} кг'
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() => outputBatches.removeAt(index)),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Санаи коркард: ${DateFormat('dd/MM/yyyy', 'en_US').format(processingDate)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Қайдҳо (ихтиёрӣ)',
                border: OutlineInputBorder(),
                hintText: 'Қайдҳои иловагӣ дар бораи коркард...',
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


  void _resetForm() {
    _lintWeightController.clear();
    _ulukWeightController.clear();
    _valaknoWeightController.clear();
    _lintPiecesController.clear();
    _ulukPiecesController.clear();
    _valaknoPiecesController.clear();
    _weightController.clear();
    _piecesController.clear();
    _notesController.clear();
    
    setState(() {
      processingDate = DateTime.now();
      isValaknoManualOverride = false;
      outputBatches.clear();
    });
  }

  Future<String?> _validateWarehouseAvailability() async {
    final warehouseProvider = context.read<CottonWarehouseProvider>();
    
    // Ensure warehouse data is loaded
    await warehouseProvider.loadAllData();
    
    final lintKg = double.tryParse(_lintWeightController.text) ?? 0;
    final lintPieces = int.tryParse(_lintPiecesController.text) ?? 0;
    final ulukKg = double.tryParse(_ulukWeightController.text) ?? 0;
    final ulukPieces = int.tryParse(_ulukPiecesController.text) ?? 0;
    final valaknoKg = double.tryParse(_valaknoWeightController.text) ?? 0;
    final valaknoPieces = int.tryParse(_valaknoPiecesController.text) ?? 0;

    // Check if any raw cotton is specified for processing
    if (lintKg == 0 && ulukKg == 0 && valaknoKg == 0) {
      return 'Пахтаи хом барои коркард ворид кунед';
    }

    // Get current warehouse inventory
    final inventory = warehouseProvider.rawCottonInventory;
    
    // Check lint availability
    if (lintKg > 0 || lintPieces > 0) {
      final lintInventory = inventory.firstWhere(
        (item) => item.cottonType == RawCottonType.lint,
        orElse: () => RawCottonWarehouse(
          cottonType: RawCottonType.lint,
          pieces: 0,
          totalWeight: 0,
          lastUpdated: DateTime.now(),
        ),
      );
      
      if (lintKg > lintInventory.totalWeight) {
        return 'Линт кофӣ нест. Мавҷуд: ${lintInventory.totalWeight.toStringAsFixed(1)} кг, дархост: ${lintKg.toStringAsFixed(1)} кг';
      }
      
      if (lintPieces > lintInventory.pieces) {
        return 'Линт кофӣ нест. Мавҷуд: ${lintInventory.pieces} дона, дархост: $lintPieces дона';
      }
    }

    // Check uluk availability
    if (ulukKg > 0 || ulukPieces > 0) {
      final ulukInventory = inventory.firstWhere(
        (item) => item.cottonType == RawCottonType.sliver,
        orElse: () => RawCottonWarehouse(
          cottonType: RawCottonType.sliver,
          pieces: 0,
          totalWeight: 0,
          lastUpdated: DateTime.now(),
        ),
      );
      
      if (ulukKg > ulukInventory.totalWeight) {
        return 'Улук кофӣ нест. Мавҷуд: ${ulukInventory.totalWeight.toStringAsFixed(1)} кг, дархост: ${ulukKg.toStringAsFixed(1)} кг';
      }
      
      if (ulukPieces > ulukInventory.pieces) {
        return 'Улук кофӣ нест. Мавҷуд: ${ulukInventory.pieces} дона, дархост: $ulukPieces дона';
      }
    }

    // Check valakno availability
    if (valaknoKg > 0 || valaknoPieces > 0) {
      final valaknoInventory = inventory.firstWhere(
        (item) => item.cottonType == RawCottonType.other,
        orElse: () => RawCottonWarehouse(
          cottonType: RawCottonType.other,
          pieces: 0,
          totalWeight: 0,
          lastUpdated: DateTime.now(),
        ),
      );
      
      if (valaknoKg > valaknoInventory.totalWeight) {
        return 'Валакно кофӣ нест. Мавҷуд: ${valaknoInventory.totalWeight.toStringAsFixed(1)} кг, дархост: ${valaknoKg.toStringAsFixed(1)} кг';
      }
      
      if (valaknoPieces > valaknoInventory.pieces) {
        return 'Валакно кофӣ нест. Мавҷуд: ${valaknoInventory.pieces} дона, дархост: $valaknoPieces дона';
      }
    }

    // Check if processed cotton exceeds total raw cotton being used
    final totalRawCottonWeight = lintKg + ulukKg + valaknoKg;
    final totalProcessedWeight = _totalProcessedCottonWeight;
    
    if (totalProcessedWeight > totalRawCottonWeight) {
      return 'Пахтаи коркардшуда аз пахтаи хом зиёд аст. Хом: ${totalRawCottonWeight.toStringAsFixed(1)} кг, Коркардшуда: ${totalProcessedWeight.toStringAsFixed(1)} кг';
    }

    return null; // No validation errors
  }

  Future<void> _saveProcessing() async {
    if (!_formKey.currentState!.validate()) return;
    if (outputBatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ягон баста илова накардаед')),
      );
      return;
    }

    // Validate warehouse availability before processing
    final validationResult = await _validateWarehouseAvailability();
    if (validationResult != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $validationResult'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    
    try {
      final provider = context.read<CottonRegistryProvider>();
      final warehouseProvider = context.read<CottonWarehouseProvider>();
      
      // Use auto-selected purchase or create a simple record
      int purchaseId = selectedPurchase?.id ?? 1;
      
      // Create processing registry with raw cotton inputs
      final processing = CottonProcessingRegistry(
        linkedPurchaseId: purchaseId,
        processingDate: processingDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      
      // Create input records for raw cotton used
      final inputs = <CottonProcessingInput>[];
      
      // Add lint input if specified
      final lintKg = double.tryParse(_lintWeightController.text) ?? 0;
      final lintPieces = int.tryParse(_lintPiecesController.text) ?? 0;
      if (lintKg > 0 && lintPieces > 0) {
        inputs.add(CottonProcessingInput(
          processingId: 0,
          cottonType: CottonType.lint,
          unitsUsed: lintPieces,
          weightUsed: lintKg,
          sourcePurchaseItemId: 0,
        ));
      }
      
      // Add uluk input if specified
      final ulukKg = double.tryParse(_ulukWeightController.text) ?? 0;
      final ulukPieces = int.tryParse(_ulukPiecesController.text) ?? 0;
      if (ulukKg > 0 && ulukPieces > 0) {
        inputs.add(CottonProcessingInput(
          processingId: 0,
          cottonType: CottonType.uluk,
          unitsUsed: ulukPieces,
          weightUsed: ulukKg,
          sourcePurchaseItemId: 0,
        ));
      }
      
      // Add valakno input if specified
      final valaknoKg = double.tryParse(_valaknoWeightController.text) ?? 0;
      final valaknoPieces = int.tryParse(_valaknoPiecesController.text) ?? 0;
      if (valaknoKg > 0 && valaknoPieces > 0) {
        inputs.add(CottonProcessingInput(
          processingId: 0,
          cottonType: CottonType.valakno,
          unitsUsed: valaknoPieces,
          weightUsed: valaknoKg,
          sourcePurchaseItemId: 0,
        ));
      }
      
      // Deduct raw cotton from warehouse
      if (lintKg > 0 && lintPieces > 0) {
        await warehouseProvider.deductFromRawWarehouse(
          cottonType: RawCottonType.lint,
          pieces: lintPieces,
          totalWeight: lintKg,
        );
      }
      
      if (ulukKg > 0 && ulukPieces > 0) {
        await warehouseProvider.deductFromRawWarehouse(
          cottonType: RawCottonType.sliver,
          pieces: ulukPieces,
          totalWeight: ulukKg,
        );
      }
      
      if (valaknoKg > 0 && valaknoPieces > 0) {
        await warehouseProvider.deductFromRawWarehouse(
          cottonType: RawCottonType.other,
          pieces: valaknoPieces,
          totalWeight: valaknoKg,
        );
      }
      
      // Add processed cotton to processed warehouse
      for (final batch in outputBatches) {
        await warehouseProvider.addToProcessedWarehouse(
          pieces: batch.numberOfUnits,
          totalWeight: batch.totalWeight,
          weightPerPiece: batch.batchWeightPerUnit,
          notes: 'Натиҷаи коркарди пахта',
        );
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
            content: Text('✅ Коркард сабт шуд ва аз анбор кам карда шуд'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Хато: $e'), backgroundColor: Colors.red),
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

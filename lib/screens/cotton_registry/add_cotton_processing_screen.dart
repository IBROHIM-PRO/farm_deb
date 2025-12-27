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
  final _notesController = TextEditingController();

  // Auto-selected purchase and current date
  CottonPurchaseRegistry? selectedPurchase;
  DateTime processingDate = DateTime.now();
  
  // Raw cotton processing inputs
  final _lintWeightController = TextEditingController();
  final _ulukWeightController = TextEditingController();
  final _valaknoWeightController = TextEditingController();
  bool isValaknoManualOverride = false;
  
  // Simple batch output for processed cotton
  final _weightController = TextEditingController();
  final _piecesController = TextEditingController();
  
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
              
              // Simple batch input for processed cotton output
              _buildSectionTitle('Натиҷаи коркард - Дастаи пахтаи коркардшуда'),
              _buildSimpleBatchInput(),
              const SizedBox(height: 24),
              
              // Output batches list
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
            // Lint Input
            TextFormField(
              controller: _lintWeightController,
              decoration: const InputDecoration(
                labelText: 'Линт (кг)',
                border: OutlineInputBorder(),
                suffixText: 'кг',
                hintText: 'Вазни пахтаи линт',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value?.isNotEmpty == true) {
                  final v = double.tryParse(value!);
                  if (v == null || v <= 0) return 'Вазни дуруст ворид кунед';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Uluk Input
            TextFormField(
              controller: _ulukWeightController,
              decoration: const InputDecoration(
                labelText: 'Улук (кг)',
                border: OutlineInputBorder(),
                suffixText: 'кг',
                hintText: 'Вазни пахтаи улук',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value?.isNotEmpty == true) {
                  final v = double.tryParse(value!);
                  if (v == null || v <= 0) return 'Вазни дуруст ворид кунед';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Valakno Input (with auto-calculation)
            TextFormField(
              controller: _valaknoWeightController,
              decoration: InputDecoration(
                labelText: 'Валакно (кг)',
                border: const OutlineInputBorder(),
                suffixText: 'кг',
                hintText: 'Ба таври автоматӣ ҳисоб мешавад',
                helperText: isValaknoManualOverride ? 
                  'Дастӣ тағйир дода шуд' : 
                  'Автоматӣ: ${_getValaknoFormula()}',
                helperStyle: TextStyle(
                  color: isValaknoManualOverride ? Colors.orange : Colors.blue,
                  fontSize: 12,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value?.isNotEmpty == true) {
                  final v = double.tryParse(value!);
                  if (v == null || v <= 0) return 'Вазни дуруст ворид кунед';
                }
                return null;
              },
            ),
            
            if (isValaknoManualOverride) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    isValaknoManualOverride = false;
                    _calculateValakno();
                  });
                },
                icon: const Icon(Icons.refresh),
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

  Widget _buildSimpleBatchInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Вазни як дона (кг)',
                border: OutlineInputBorder(),
                suffixText: 'кг',
                hintText: 'Вазни як донаи коркардшуда',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final v = double.tryParse(value ?? '');
                if (v == null || v <= 0) return 'Лутфан вазнро ворид кунед';
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
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final v = int.tryParse(value ?? '');
                if (v == null || v <= 0) return 'Лутфан шумораро ворид кунед';
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addSimpleBatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Илова кардани баста'),
            ),
          ],
        ),
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
    if (outputBatches.isEmpty) {
      return const Text(
        'Ҳеҷ баста илова нашудааст',
        style: TextStyle(color: Colors.grey, fontSize: 16),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Дастаҳои илованамуда:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
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
    _weightController.clear();
    _piecesController.clear();
    _notesController.clear();
    
    setState(() {
      processingDate = DateTime.now();
      isValaknoManualOverride = false;
      outputBatches.clear();
    });
  }

  Future<void> _saveProcessing() async {
    if (!_formKey.currentState!.validate()) return;
    if (outputBatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ягон баста илова накардаед')),
      );
      return;
    }

    setState(() => isLoading = true);
    
    try {
      final provider = context.read<CottonRegistryProvider>();
      
      // Use auto-selected purchase or create a simple record
      int purchaseId = selectedPurchase?.id ?? 1;
      
      // Create simple processing registry
      final processing = CottonProcessingRegistry(
        linkedPurchaseId: purchaseId,
        processingDate: processingDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      
      // Create simple input record (just mark as processed)
      final inputs = <CottonProcessingInput>[
        CottonProcessingInput(
          processingId: 0,
          cottonType: CottonType.lint, // Default input type
          unitsUsed: outputBatches.fold(0, (sum, batch) => sum + batch.numberOfUnits),
          weightUsed: outputBatches.fold(0.0, (sum, batch) => sum + batch.totalWeight),
          sourcePurchaseItemId: 0,
        ),
      ];
      
      // Save processing with simplified inputs and outputs
      await provider.addCottonProcessing(
        registry: processing,
        inputs: inputs,
        outputs: outputBatches,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Коркард бо муваффақият сабт шуд'),
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

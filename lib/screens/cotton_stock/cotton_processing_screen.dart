import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/cotton_processing.dart';

class CottonProcessingScreen extends StatefulWidget {
  const CottonProcessingScreen({super.key});

  @override
  State<CottonProcessingScreen> createState() => _CottonProcessingScreenState();
}

class _CottonProcessingScreenState extends State<CottonProcessingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Calculator form controllers
  final _formKey = GlobalKey<FormState>();
  final _lintWeightController = TextEditingController();
  final _ulukWeightController = TextEditingController();
  final _valaknoWeightController = TextEditingController();
  final _extraValaknoWeightController = TextEditingController();
  final _lintUnitsController = TextEditingController();
  final _ulukUnitsController = TextEditingController();
  final _valaknoUnitsController = TextEditingController();
  final _extraValaknoUnitsController = TextEditingController();
  final _processedOutputWeightController = TextEditingController();
  final _processedUnitsController = TextEditingController();
  
  // UI State
  bool lintSelected = false;
  bool ulukSelected = false;
  bool valaknoSelected = false;
  DateTime selectedDate = DateTime.now();
  
  // Calculated values
  double totalInputWeight = 0;
  double autoCalculatedValakno = 0;
  double yieldPercentage = 0;
  List<String> validationErrors = [];
  
  // Data
  List<CottonProcessing> processingHistory = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProcessingHistory();
    _setupListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _lintWeightController.dispose();
    _ulukWeightController.dispose();
    _valaknoWeightController.dispose();
    _extraValaknoWeightController.dispose();
    _lintUnitsController.dispose();
    _ulukUnitsController.dispose();
    _valaknoUnitsController.dispose();
    _extraValaknoUnitsController.dispose();
    _processedOutputWeightController.dispose();
    _processedUnitsController.dispose();
  }

  void _setupListeners() {
    _lintWeightController.addListener(_calculateValues);
    _ulukWeightController.addListener(_calculateValues);
    _valaknoWeightController.addListener(_calculateValues);
    _extraValaknoWeightController.addListener(_calculateValues);
    _processedOutputWeightController.addListener(_calculateValues);
  }

  void _calculateValues() {
    setState(() {
      _validateAndCalculate();
    });
  }

  void _validateAndCalculate() {
    validationErrors.clear();
    
    // Get input values
    final lintWeight = double.tryParse(_lintWeightController.text) ?? 0;
    final ulukWeight = double.tryParse(_ulukWeightController.text) ?? 0;
    final valaknoWeight = double.tryParse(_valaknoWeightController.text) ?? 0;
    final extraValaknoWeight = double.tryParse(_extraValaknoWeightController.text) ?? 0;
    final processedWeight = double.tryParse(_processedOutputWeightController.text) ?? 0;
    
    // Validation: Valakno cannot be processed alone
    if (!lintSelected && !ulukSelected && valaknoSelected) {
      validationErrors.add('Valakno cannot be processed alone');
    }
    
    // Auto-calculate Valakno for Lint + Uluk processing
    if (lintSelected && ulukSelected && lintWeight > 0 && ulukWeight > 0) {
      // If weights are approximately equal (within 10% difference)
      final avgWeight = (lintWeight + ulukWeight) / 2;
      final weightDiff = (lintWeight - ulukWeight).abs();
      if (weightDiff / avgWeight <= 0.1) {
        // Auto-calculate Valakno as half of the average
        autoCalculatedValakno = avgWeight / 2;
      }
    } else {
      autoCalculatedValakno = 0;
    }
    
    // Calculate total input weight
    double inputWeight = 0;
    if (lintSelected) inputWeight += lintWeight;
    if (ulukSelected) inputWeight += ulukWeight;
    if (valaknoSelected) inputWeight += valaknoWeight;
    // Extra Valakno is not included in processing calculations
    
    totalInputWeight = inputWeight;
    
    // Calculate yield percentage
    if (totalInputWeight > 0 && processedWeight > 0) {
      yieldPercentage = (processedWeight / totalInputWeight) * 100;
    } else {
      yieldPercentage = 0;
    }
  }

  Future<void> _loadProcessingHistory() async {
    setState(() => isLoading = true);
    
    try {
      final history = await DatabaseHelper.instance.getAllCottonProcessing();
      setState(() {
        processingHistory = history;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotton Processing'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calculate), text: 'Calculator'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProcessingHistory,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalculatorTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildCalculatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Cotton Type Selection'),
            _buildCottonTypeSelection(),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Weight Input (kg)'),
            _buildWeightInputs(),
            const SizedBox(height: 16),
            
            if (autoCalculatedValakno > 0) ...[
              _buildAutoCalculatedValakno(),
              const SizedBox(height: 16),
            ],
            
            _buildSectionTitle('Units Input (pieces)'),
            _buildUnitsInputs(),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Processing Result'),
            _buildProcessingResult(),
            const SizedBox(height: 16),
            
            _buildCalculationSummary(),
            const SizedBox(height: 16),
            
            if (validationErrors.isNotEmpty)
              _buildValidationErrors(),
            
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadProcessingHistory,
            child: processingHistory.isEmpty
                ? _buildEmptyHistoryState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: processingHistory.length,
                    itemBuilder: (context, index) {
                      final processing = processingHistory[index];
                      return _buildHistoryCard(processing);
                    },
                  ),
          );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCottonTypeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CheckboxListTile(
              title: const Text('Lint'),
              subtitle: const Text('Standard processing weight: 500 kg'),
              value: lintSelected,
              onChanged: (value) {
                setState(() {
                  lintSelected = value ?? false;
                  if (!lintSelected) _lintWeightController.clear();
                  _calculateValues();
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Uluk'),
              subtitle: const Text('Standard processing weight: 500 kg'),
              value: ulukSelected,
              onChanged: (value) {
                setState(() {
                  ulukSelected = value ?? false;
                  if (!ulukSelected) _ulukWeightController.clear();
                  _calculateValues();
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Valakno'),
              subtitle: const Text('Standard processing weight: 250 kg'),
              value: valaknoSelected,
              onChanged: (value) {
                setState(() {
                  valaknoSelected = value ?? false;
                  if (!valaknoSelected) _valaknoWeightController.clear();
                  _calculateValues();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightInputs() {
    return Column(
      children: [
        if (lintSelected)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: _lintWeightController,
              decoration: const InputDecoration(
                labelText: 'Lint Weight',
                suffixText: 'kg',
                hintText: 'Recommended: 500 kg',
              ),
              keyboardType: TextInputType.number,
              validator: lintSelected ? (value) {
                if (value?.trim().isEmpty == true) return 'Required for selected cotton type';
                final weight = double.tryParse(value!);
                if (weight == null || weight <= 0) return 'Invalid weight';
                return null;
              } : null,
            ),
          ),
        
        if (ulukSelected)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: _ulukWeightController,
              decoration: const InputDecoration(
                labelText: 'Uluk Weight',
                suffixText: 'kg',
                hintText: 'Recommended: 500 kg',
              ),
              keyboardType: TextInputType.number,
              validator: ulukSelected ? (value) {
                if (value?.trim().isEmpty == true) return 'Required for selected cotton type';
                final weight = double.tryParse(value!);
                if (weight == null || weight <= 0) return 'Invalid weight';
                return null;
              } : null,
            ),
          ),
        
        if (valaknoSelected)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: _valaknoWeightController,
              decoration: const InputDecoration(
                labelText: 'Valakno Weight',
                suffixText: 'kg',
                hintText: 'Recommended: 250 kg',
              ),
              keyboardType: TextInputType.number,
              validator: valaknoSelected ? (value) {
                if (value?.trim().isEmpty == true) return 'Required for selected cotton type';
                final weight = double.tryParse(value!);
                if (weight == null || weight <= 0) return 'Invalid weight';
                return null;
              } : null,
            ),
          ),
        
        TextFormField(
          controller: _extraValaknoWeightController,
          decoration: const InputDecoration(
            labelText: 'Extra Valakno Weight (Optional)',
            suffixText: 'kg',
            hintText: 'Additional Valakno not affecting processing',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildAutoCalculatedValakno() {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-calculated Valakno',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Recommended: ${autoCalculatedValakno.toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitsInputs() {
    return Column(
      children: [
        if (lintSelected)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: _lintUnitsController,
              decoration: const InputDecoration(
                labelText: 'Lint Units',
                suffixText: 'pieces',
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        
        if (ulukSelected)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: _ulukUnitsController,
              decoration: const InputDecoration(
                labelText: 'Uluk Units',
                suffixText: 'pieces',
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        
        if (valaknoSelected)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: _valaknoUnitsController,
              decoration: const InputDecoration(
                labelText: 'Valakno Units',
                suffixText: 'pieces',
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        
        TextFormField(
          controller: _extraValaknoUnitsController,
          decoration: const InputDecoration(
            labelText: 'Extra Valakno Units (Optional)',
            suffixText: 'pieces',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildProcessingResult() {
    return Column(
      children: [
        TextFormField(
          controller: _processedOutputWeightController,
          decoration: const InputDecoration(
            labelText: 'Processed Output Weight',
            suffixText: 'kg',
            hintText: 'Weight of clean cotton after processing',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.trim().isEmpty == true) return 'Required for yield calculation';
            final weight = double.tryParse(value!);
            if (weight == null || weight <= 0) return 'Invalid weight';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _processedUnitsController,
          decoration: const InputDecoration(
            labelText: 'Processed Units',
            suffixText: 'pieces',
            hintText: 'Number of processed cotton packages',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.trim().isEmpty == true) return 'Required for processing record';
            final units = int.tryParse(value!);
            if (units == null || units <= 0) return 'Invalid units';
            return null;
          },
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Processing Date'),
            subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _selectDate,
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationSummary() {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calculation Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Total Input Weight', '${totalInputWeight.toStringAsFixed(1)} kg'),
            const SizedBox(height: 8),
            _buildSummaryRow('Processed Output', '${(double.tryParse(_processedOutputWeightController.text) ?? 0).toStringAsFixed(1)} kg'),
            const SizedBox(height: 8),
            _buildSummaryRow('Yield Percentage', '${yieldPercentage.toStringAsFixed(1)}%', 
              color: yieldPercentage >= 80 ? Colors.green : yieldPercentage >= 70 ? Colors.orange : Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildValidationErrors() {
    return Card(
      color: Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Validation Errors',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...validationErrors.map((error) => Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 4),
              child: Text(
                '• $error',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red[600],
                ),
              ),
            )),
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
            onPressed: _resetCalculator,
            child: const Text('Clear'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: validationErrors.isEmpty ? _saveProcessing : null,
            child: const Text('Save Processing'),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(CottonProcessing processing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(processing.processingDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getYieldColor(processing.yieldPercentage).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${processing.yieldPercentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getYieldColor(processing.yieldPercentage),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Types: ${processing.cottonTypes.join(', ')}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip('Input', '${processing.totalInputWeight.toStringAsFixed(1)} kg'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip('Output', '${processing.processedOutputWeight.toStringAsFixed(1)} kg'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip('Units', '${processing.processedUnits}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Processing History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Processing records will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getYieldColor(double yield) {
    if (yield >= 80) return Colors.green;
    if (yield >= 70) return Colors.orange;
    return Colors.red;
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  void _resetCalculator() {
    _lintWeightController.clear();
    _ulukWeightController.clear();
    _valaknoWeightController.clear();
    _extraValaknoWeightController.clear();
    _lintUnitsController.clear();
    _ulukUnitsController.clear();
    _valaknoUnitsController.clear();
    _extraValaknoUnitsController.clear();
    _processedOutputWeightController.clear();
    _processedUnitsController.clear();
    
    setState(() {
      lintSelected = false;
      ulukSelected = false;
      valaknoSelected = false;
      selectedDate = DateTime.now();
      totalInputWeight = 0;
      autoCalculatedValakno = 0;
      yieldPercentage = 0;
      validationErrors.clear();
    });
  }

  Future<void> _saveProcessing() async {
    if (!_formKey.currentState!.validate() || validationErrors.isNotEmpty) return;

    try {
      final processing = CottonProcessing(
        processingDate: selectedDate,
        lintWeight: lintSelected ? double.tryParse(_lintWeightController.text) : null,
        ulukWeight: ulukSelected ? double.tryParse(_ulukWeightController.text) : null,
        valaknoWeight: valaknoSelected ? double.tryParse(_valaknoWeightController.text) : null,
        extraValaknoWeight: double.tryParse(_extraValaknoWeightController.text),
        lintUnits: lintSelected ? int.tryParse(_lintUnitsController.text) : null,
        ulukUnits: ulukSelected ? int.tryParse(_ulukUnitsController.text) : null,
        valaknoUnits: valaknoSelected ? int.tryParse(_valaknoUnitsController.text) : null,
        extraValaknoUnits: int.tryParse(_extraValaknoUnitsController.text),
        totalInputWeight: totalInputWeight,
        processedOutputWeight: double.parse(_processedOutputWeightController.text),
        processedUnits: int.parse(_processedUnitsController.text),
        yieldPercentage: yieldPercentage,
      );

      await DatabaseHelper.instance.insertCottonProcessing(processing);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Processing record saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        _resetCalculator();
        _loadProcessingHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving processing: $e')),
        );
      }
    }
  }
}

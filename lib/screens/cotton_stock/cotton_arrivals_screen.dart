import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/cotton_type.dart';
import '../../models/cotton_batch.dart';
import '../../providers/history_provider.dart';

class CottonArrivalsScreen extends StatefulWidget {
  const CottonArrivalsScreen({super.key});

  @override
  State<CottonArrivalsScreen> createState() => _CottonArrivalsScreenState();
}

class _CottonArrivalsScreenState extends State<CottonArrivalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _unitsController = TextEditingController();
  final _sourceController = TextEditingController();
  final _priceController = TextEditingController();
  final _freightController = TextEditingController();
  
  List<CottonType> cottonTypes = [];
  CottonType? selectedCottonType;
  DateTime selectedDate = DateTime.now();
  double totalCost = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCottonTypes();
    _weightController.addListener(_calculateTotalCost);
    _priceController.addListener(_calculateTotalCost);
    _freightController.addListener(_calculateTotalCost);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _unitsController.dispose();
    _sourceController.dispose();
    _priceController.dispose();
    _freightController.dispose();
    super.dispose();
  }

  Future<void> _loadCottonTypes() async {
    try {
      final types = await DatabaseHelper.instance.getAllCottonTypes();
      setState(() {
        cottonTypes = types;
        if (types.isNotEmpty && selectedCottonType == null) {
          selectedCottonType = types.first;
          _priceController.text = selectedCottonType!.pricePerKg.toString();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cotton types: $e')),
        );
      }
    }
  }

  void _calculateTotalCost() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final pricePerKg = double.tryParse(_priceController.text) ?? 0;
    final freight = double.tryParse(_freightController.text) ?? 0;
    
    setState(() {
      totalCost = (weight * pricePerKg) + freight;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Cotton Arrival'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Cotton Type'),
                      _buildCottonTypeDropdown(),
                      const SizedBox(height: 24),
                      
                      _buildSectionTitle('Batch Details'),
                      _buildWeightAndUnitsInputs(),
                      const SizedBox(height: 16),
                      _buildSourceInput(),
                      const SizedBox(height: 16),
                      _buildDateSelector(),
                      const SizedBox(height: 24),
                      
                      _buildSectionTitle('Pricing Information'),
                      _buildPriceAndFreightInputs(),
                      const SizedBox(height: 16),
                      _buildTotalCostDisplay(),
                      const SizedBox(height: 32),
                      
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
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

  Widget _buildCottonTypeDropdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonFormField<CottonType>(
          value: selectedCottonType,
          decoration: const InputDecoration(
            labelText: 'Cotton Type',
            border: InputBorder.none,
          ),
          items: cottonTypes.map((type) => DropdownMenuItem(
            value: type,
            child: Row(
              children: [
                Icon(
                  Icons.category,
                  color: _getTypeColor(type.name),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(type.name),
                const Spacer(),
                Text(
                  '${type.pricePerKg.toStringAsFixed(0)} TJS/kg',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )).toList(),
          onChanged: (type) {
            setState(() {
              selectedCottonType = type;
              if (type != null) {
                _priceController.text = type.pricePerKg.toString();
              }
            });
          },
          validator: (value) => value == null ? 'Please select a cotton type' : null,
        ),
      ),
    );
  }

  Widget _buildWeightAndUnitsInputs() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              suffixText: 'kg',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              final weight = double.tryParse(value);
              if (weight == null || weight <= 0) return 'Invalid weight';
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _unitsController,
            decoration: const InputDecoration(
              labelText: 'Units (pieces)',
              suffixText: 'pcs',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              final units = int.tryParse(value);
              if (units == null || units <= 0) return 'Invalid units';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSourceInput() {
    return TextFormField(
      controller: _sourceController,
      decoration: const InputDecoration(
        labelText: 'Supplier/Source',
        hintText: 'Enter supplier name or source',
        prefixIcon: Icon(Icons.business),
      ),
      validator: (value) => value?.trim().isEmpty == true ? 'Required' : null,
    );
  }

  Widget _buildDateSelector() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: const Text('Arrival Date'),
        subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: _selectDate,
      ),
    );
  }

  Widget _buildPriceAndFreightInputs() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Price per kg',
              suffixText: 'TJS',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              final price = double.tryParse(value);
              if (price == null || price <= 0) return 'Invalid price';
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _freightController,
            decoration: const InputDecoration(
              labelText: 'Freight Cost',
              suffixText: 'TJS',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isNotEmpty == true) {
                final freight = double.tryParse(value!);
                if (freight == null || freight < 0) return 'Invalid amount';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCostDisplay() {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.calculate,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Cost',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  '${totalCost.toStringAsFixed(2)} TJS',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
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
            child: const Text('Clear'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveBatch,
            child: const Text('Save Batch'),
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(String typeName) {
    switch (typeName) {
      case 'Lint':
        return Colors.green;
      case 'Uluk':
        return Colors.blue;
      case 'Valakno':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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

  void _resetForm() {
    _weightController.clear();
    _unitsController.clear();
    _sourceController.clear();
    _priceController.text = selectedCottonType?.pricePerKg.toString() ?? '';
    _freightController.clear();
    setState(() {
      selectedDate = DateTime.now();
      totalCost = 0;
    });
  }

  Future<void> _saveBatch() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCottonType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a cotton type')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final batch = CottonBatch(
        cottonTypeId: selectedCottonType!.id!,
        weightKg: double.parse(_weightController.text),
        units: int.parse(_unitsController.text),
        arrivalDate: selectedDate,
        source: _sourceController.text.trim(),
        pricePerKg: double.parse(_priceController.text),
        freightCost: double.tryParse(_freightController.text) ?? 0,
        totalCost: totalCost,
      );

      final batchId = await DatabaseHelper.instance.insertCottonBatch(batch);
      await HistoryProvider().addCottonBatchHistory(batch.copyWith(id: batchId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cotton batch recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving batch: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }
}

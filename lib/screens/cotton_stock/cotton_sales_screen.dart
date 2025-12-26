import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/buyer.dart';
import '../../models/cotton_stock_sale.dart';

class CottonSalesScreen extends StatefulWidget {
  const CottonSalesScreen({super.key});

  @override
  State<CottonSalesScreen> createState() => _CottonSalesScreenState();
}

class _CottonSalesScreenState extends State<CottonSalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _unitsController = TextEditingController();
  final _pricePerKgController = TextEditingController();
  final _pricePerUnitController = TextEditingController();
  
  // UI State
  List<Buyer> buyers = [];
  List<CottonStockSale> salesHistory = [];
  Buyer? selectedBuyer;
  double selectedUnitWeight = 20.0; // Default 20kg per unit
  DateTime selectedDate = DateTime.now();
  
  // Calculated values
  double totalWeight = 0;
  double totalAmount = 0;
  bool isLoading = false;

  // Unit weight options
  final List<double> unitWeightOptions = [20.0, 30.0, 25.0, 40.0, 50.0];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _setupListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _unitsController.dispose();
    _pricePerKgController.dispose();
    _pricePerUnitController.dispose();
    super.dispose();
  }

  void _setupListeners() {
    _unitsController.addListener(_calculateValues);
    _pricePerKgController.addListener(_calculateValues);
    _pricePerUnitController.addListener(_calculateValues);
  }

  void _calculateValues() {
    setState(() {
      final units = int.tryParse(_unitsController.text) ?? 0;
      totalWeight = units * selectedUnitWeight;
      
      // Calculate total amount based on available pricing
      final pricePerKg = double.tryParse(_pricePerKgController.text);
      final pricePerUnit = double.tryParse(_pricePerUnitController.text);
      
      if (pricePerKg != null && pricePerKg > 0) {
        totalAmount = totalWeight * pricePerKg;
      } else if (pricePerUnit != null && pricePerUnit > 0) {
        totalAmount = units * pricePerUnit;
      } else {
        totalAmount = 0;
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      final [buyersData, salesData] = await Future.wait([
        DatabaseHelper.instance.getAllBuyers(),
        DatabaseHelper.instance.getAllCottonStockSales(),
      ]);
      
      setState(() {
        buyers = buyersData as List<Buyer>;
        salesHistory = salesData as List<CottonStockSale>;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotton Sales'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_shopping_cart), text: 'New Sale'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Sales History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNewSaleTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildNewSaleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Buyer Information'),
            _buildBuyerSelection(),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Sale Details'),
            _buildUnitWeightSelection(),
            const SizedBox(height: 16),
            _buildUnitsInput(),
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Pricing (Optional)'),
            _buildPricingInputs(),
            const SizedBox(height: 16),
            
            _buildCalculationSummary(),
            const SizedBox(height: 32),
            
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: salesHistory.isEmpty
          ? _buildEmptyHistoryState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: salesHistory.length,
              itemBuilder: (context, index) {
                final sale = salesHistory[index];
                final buyer = buyers.firstWhere(
                  (b) => b.id == sale.buyerId,
                  orElse: () => Buyer(name: 'Unknown Buyer'),
                );
                return _buildSaleHistoryCard(sale, buyer);
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

  Widget _buildBuyerSelection() {
    return Card(
      child: Column(
        children: [
          if (buyers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<Buyer>(
                value: selectedBuyer,
                decoration: const InputDecoration(
                  labelText: 'Select Buyer',
                  border: InputBorder.none,
                ),
                items: buyers.map((buyer) => DropdownMenuItem(
                  value: buyer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(buyer.name),
                      if (buyer.phone?.isNotEmpty == true)
                        Text(
                          buyer.phone!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                )).toList(),
                onChanged: (buyer) => setState(() => selectedBuyer = buyer),
                validator: (value) => value == null ? 'Please select a buyer' : null,
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton.icon(
              onPressed: _showAddBuyerDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add New Buyer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitWeightSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weight per Unit',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...unitWeightOptions.map((weight) => ChoiceChip(
                  label: Text('${weight.toStringAsFixed(0)} kg'),
                  selected: selectedUnitWeight == weight,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedUnitWeight = weight;
                        _calculateValues();
                      });
                    }
                  },
                )),
                ChoiceChip(
                  label: const Text('Custom'),
                  selected: !unitWeightOptions.contains(selectedUnitWeight),
                  onSelected: (selected) {
                    if (selected) _showCustomWeightDialog();
                  },
                ),
              ],
            ),
            if (!unitWeightOptions.contains(selectedUnitWeight))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Custom weight: ${selectedUnitWeight.toStringAsFixed(1)} kg per unit',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitsInput() {
    return TextFormField(
      controller: _unitsController,
      decoration: const InputDecoration(
        labelText: 'Number of Units to Sell',
        suffixText: 'units',
        hintText: 'Enter quantity',
        prefixIcon: Icon(Icons.inventory),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value?.trim().isEmpty == true) return 'Required';
        final units = int.tryParse(value!);
        if (units == null || units <= 0) return 'Invalid quantity';
        return null;
      },
    );
  }

  Widget _buildDateSelector() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: const Text('Sale Date'),
        subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: _selectDate,
      ),
    );
  }

  Widget _buildPricingInputs() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose pricing method (optional):',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pricePerKgController,
              decoration: const InputDecoration(
                labelText: 'Price per Kilogram',
                suffixText: 'TJS/kg',
                hintText: 'Optional',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isNotEmpty == true) {
                  final price = double.tryParse(value!);
                  if (price == null || price < 0) return 'Invalid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Text(
              'OR',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pricePerUnitController,
              decoration: const InputDecoration(
                labelText: 'Price per Unit',
                suffixText: 'TJS/unit',
                hintText: 'Optional',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isNotEmpty == true) {
                  final price = double.tryParse(value!);
                  if (price == null || price < 0) return 'Invalid price';
                }
                return null;
              },
            ),
          ],
        ),
      ),
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
              'Sale Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Units', '${int.tryParse(_unitsController.text) ?? 0}'),
            const SizedBox(height: 8),
            _buildSummaryRow('Weight per Unit', '${selectedUnitWeight.toStringAsFixed(1)} kg'),
            const SizedBox(height: 8),
            _buildSummaryRow('Total Weight', '${totalWeight.toStringAsFixed(1)} kg'),
            if (totalAmount > 0) ...[
              const SizedBox(height: 8),
              _buildSummaryRow('Total Amount', '${totalAmount.toStringAsFixed(2)} TJS', 
                color: Colors.green),
            ],
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
            onPressed: _saveSale,
            child: const Text('Record Sale'),
          ),
        ),
      ],
    );
  }

  Widget _buildSaleHistoryCard(CottonStockSale sale, Buyer buyer) {
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
                  buyer.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(sale.saleDate),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip('Units', '${sale.units}'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip('Weight', '${sale.totalWeight.toStringAsFixed(1)} kg'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip('Unit Size', '${sale.unitWeight.toStringAsFixed(1)} kg'),
                ),
              ],
            ),
            if (sale.totalAmount != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.attach_money, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Total: ${sale.totalAmount!.toStringAsFixed(2)} TJS',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Sales History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sales records will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddBuyerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Buyer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Buyer Name',
                  hintText: 'Enter buyer name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (Optional)',
                  hintText: 'Enter phone number',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Additional information',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveBuyer(nameController.text, phoneController.text, notesController.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showCustomWeightDialog() {
    final weightController = TextEditingController(text: selectedUnitWeight.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Unit Weight'),
        content: TextField(
          controller: weightController,
          decoration: const InputDecoration(
            labelText: 'Weight per Unit (kg)',
            suffixText: 'kg',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text);
              if (weight != null && weight > 0) {
                setState(() {
                  selectedUnitWeight = weight;
                  _calculateValues();
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid weight')),
                );
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
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

  Future<void> _saveBuyer(String name, String phone, String notes) async {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter buyer name')),
      );
      return;
    }

    try {
      final buyer = Buyer(
        name: name.trim(),
        phone: phone.trim().isNotEmpty ? phone.trim() : null,
        notes: notes.trim().isNotEmpty ? notes.trim() : null,
      );

      final id = await DatabaseHelper.instance.insertBuyer(buyer);
      final newBuyer = buyer.copyWith(id: id);
      
      setState(() {
        buyers.add(newBuyer);
        selectedBuyer = newBuyer;
      });

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buyer added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding buyer: $e')),
      );
    }
  }

  void _resetForm() {
    _unitsController.clear();
    _pricePerKgController.clear();
    _pricePerUnitController.clear();
    setState(() {
      selectedBuyer = null;
      selectedUnitWeight = 20.0;
      selectedDate = DateTime.now();
      totalWeight = 0;
      totalAmount = 0;
    });
  }

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedBuyer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a buyer')),
      );
      return;
    }

    try {
      final sale = CottonStockSale(
        buyerId: selectedBuyer!.id!,
        saleDate: selectedDate,
        unitWeight: selectedUnitWeight,
        units: int.parse(_unitsController.text),
        totalWeight: totalWeight,
        pricePerKg: double.tryParse(_pricePerKgController.text),
        pricePerUnit: double.tryParse(_pricePerUnitController.text),
        totalAmount: totalAmount > 0 ? totalAmount : null,
      );

      await DatabaseHelper.instance.insertCottonStockSale(sale);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sale recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        _resetForm();
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving sale: $e')),
        );
      }
    }
  }
}

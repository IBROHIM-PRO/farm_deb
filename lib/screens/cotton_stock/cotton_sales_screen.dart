import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
import '../../models/buyer.dart';
import '../../models/cotton_stock_sale.dart';
import '../../providers/cotton_warehouse_provider.dart';

class SaleItem {
  double weight;
  int pieces;
  TextEditingController weightController;
  TextEditingController piecesController;
  
  SaleItem({
    this.weight = 10.0,
    this.pieces = 1,
  }) : weightController = TextEditingController(text: '10.0'),
       piecesController = TextEditingController(text: '1');
  
  void dispose() {
    weightController.dispose();
    piecesController.dispose();
  }
  
  double get totalWeight => weight * pieces;
}

class CottonSalesScreen extends StatefulWidget {
  const CottonSalesScreen({super.key});

  @override
  State<CottonSalesScreen> createState() => _CottonSalesScreenState();
}

class _CottonSalesScreenState extends State<CottonSalesScreen> {
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _buyerNameController = TextEditingController();
  final _pricePerKgController = TextEditingController(text: '0');
  
  // UI State
  List<Buyer> buyers = [];
  List<CottonStockSale> salesHistory = [];
  String? selectedBuyerName;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  bool showSaleForm = false;
  double pricePerKg = 0.0;
  
  // Dynamic sale items
  List<SaleItem> saleItems = [];
  
  // Available weight options for processed cotton (10-50kg in 5kg increments)
  final List<double> allowedWeights = [10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 50.0];

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupListeners();
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _pricePerKgController.dispose();
    for (final item in saleItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _setupListeners() {
    // Setup listeners for dynamic sale items will be done per item
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
        title: const Text('Фуруши пахтаи коркардшуда'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          if (!showSaleForm)
            IconButton(
              onPressed: () => setState(() => showSaleForm = true),
              icon: const Icon(Icons.add),
              tooltip: 'Илова кардани фуруш',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : showSaleForm 
              ? _buildSaleForm()
              : _buildSalesHistory(),
    );
  }

  Widget _buildSaleForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Маълумоти харидор'),
            _buildBuyerNameInput(),
            const SizedBox(height: 16),
            _buildPricePerKgInput(),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Дастаҳои фуруш'),
            _buildSaleItemsList(),
            const SizedBox(height: 16),
            _buildAddItemButton(),
            const SizedBox(height: 24),
            
            _buildSaleSummary(),
            const SizedBox(height: 32),
            
            _buildFormActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesHistory() {
    // Group sales by buyer name
    final Map<String, List<CottonStockSale>> groupedSales = {};
    for (final sale in salesHistory) {
      final buyer = buyers.firstWhere(
        (b) => b.id == sale.buyerId,
        orElse: () => Buyer(name: 'Номаълум'),
      );
      final buyerName = buyer.name;
      groupedSales.putIfAbsent(buyerName, () => []).add(sale);
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: groupedSales.isEmpty
          ? _buildEmptyHistoryState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedSales.length,
              itemBuilder: (context, index) {
                final buyerName = groupedSales.keys.elementAt(index);
                final buyerSales = groupedSales[buyerName]!;
                return _buildBuyerSalesCard(buyerName, buyerSales);
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

  Widget _buildBuyerNameInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Autocomplete<String>(
          initialValue: TextEditingValue(text: _buyerNameController.text),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            try {
              // Get all buyer names from existing buyers
              final allBuyerNames = buyers.map((b) => b.name).toList();
              
              // If input is empty, return all buyers
              if (textEditingValue.text.isEmpty) {
                return allBuyerNames;
              }
              
              // Filter buyers based on input
              final query = textEditingValue.text.toLowerCase();
              return allBuyerNames.where((buyer) => 
                buyer.toLowerCase().contains(query)).toList();
            } catch (e) {
              return <String>[];
            }
          },
          onSelected: (String selection) {
            _buyerNameController.text = selection;
            selectedBuyerName = selection;
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
          ) {
            // Sync with our main controller
            fieldTextEditingController.addListener(() {
              _buyerNameController.text = fieldTextEditingController.text;
              selectedBuyerName = fieldTextEditingController.text;
            });
            
            return TextFormField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              decoration: const InputDecoration(
                labelText: 'Номи харидор',
                prefixIcon: Icon(Icons.person),
                suffixIcon: Icon(Icons.arrow_drop_down),
                hintText: 'Номи харидорро ворид кунед',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Номи харидор зарур аст';
                }
                return null;
              },
              onFieldSubmitted: (value) => onFieldSubmitted(),
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<String> onSelected,
            Iterable<String> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person, 
                                color: Colors.blue, 
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPricePerKgInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _pricePerKgController,
          decoration: const InputDecoration(
            labelText: 'Нархи 1 кг пахта',
            prefixIcon: Icon(Icons.attach_money),
            suffixText: 'сомонӣ',
            hintText: 'Нархи як килограмро ворид кунед',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Нархи як килограм зарур аст';
            }
            final price = double.tryParse(value);
            if (price == null || price < 0) {
              return 'Нархи дуруст ворид кунед';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              pricePerKg = double.tryParse(value) ?? 0.0;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSaleItemsList() {
    if (saleItems.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.inventory_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Ҳеҷ дастаи фуруш илова нашудааст',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Барои илова кардани дастаи нав тугмаи "+" -ро пахш кунед',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: saleItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildSaleItemCard(item, index);
      }).toList(),
    );
  }

  Widget _buildSaleItemCard(SaleItem item, int index) {
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
                  'Дастаи ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  onPressed: () => _removeSaleItem(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Хориҷ кардан',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: item.weightController,
                    decoration: const InputDecoration(
                      labelText: 'Вазни як дона (кг)',
                      suffixText: 'кг',
                      hintText: '10, 15, 20...',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) => _validateWeight(value),
                    onChanged: (value) => _updateSaleItem(index),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: item.piecesController,
                    decoration: const InputDecoration(
                      labelText: 'Адад',
                      suffixText: 'дона',
                      hintText: 'Шумора',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => _validatePieces(value),
                    onChanged: (value) => _updateSaleItem(index),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildItemSummary(item),
            _buildWarehouseValidation(item),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseValidation(SaleItem item) {
    return Consumer<CottonWarehouseProvider>(
      builder: (context, warehouseProvider, _) {
        final inventory = warehouseProvider.processedCottonInventory;
        
        // Find matching inventory for this weight
        final matchingBatches = inventory.where((batch) => 
          (batch.weightPerPiece - item.weight).abs() <= 0.1).toList();
        
        if (matchingBatches.isEmpty) {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Дар анбор вазни ${item.weight.toStringAsFixed(1)} кг мавҷуд нест',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
        final availablePieces = matchingBatches.fold<int>(0, (sum, batch) => sum + batch.pieces);
        
        if (item.pieces > availablePieces) {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Дар анбор кофӣ нест!',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Мавҷуд: $availablePieces дона, дархост: ${item.pieces} дона',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }
        
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Дар анбор мавҷуд: $availablePieces дона',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddItemButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _addSaleItem,
        icon: const Icon(Icons.add),
        label: const Text('Илова кардани дастаи нав'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: const Text('Санаи фуруш'),
        subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: _selectDate,
      ),
    );
  }

  Widget _buildSaleSummary() {
    final totalPieces = saleItems.fold<int>(0, (sum, item) => sum + item.pieces);
    final totalWeight = saleItems.fold<double>(0, (sum, item) => sum + item.totalWeight);
    final totalAmount = totalWeight * pricePerKg;
    
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ҷамъбасти фуруш',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Ҷамъи донаҳо', '$totalPieces дона'),
            const SizedBox(height: 8),
            _buildSummaryRow('Ҷамъи вазн', '${totalWeight.toStringAsFixed(1)} кг'),
            const SizedBox(height: 8),
            _buildSummaryRow('Нархи 1 кг', '${pricePerKg.toStringAsFixed(2)} сомонӣ'),
            const Divider(height: 24),
            _buildSummaryRow(
              'Ҷамъи маблағ',
              '${totalAmount.toStringAsFixed(2)} сомонӣ',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 18 : 14,
            color: isTotal ? Colors.green[700] : null,
          ),
        ),
      ],
    );
  }

  Widget _buildFormActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelSaleForm,
            child: const Text('Бекор кардан'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: saleItems.isNotEmpty ? _saveSale : null,
            child: const Text('Сабт кардан'),
          ),
        ),
      ],
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


  void _addSaleItem() {
    setState(() {
      saleItems.add(SaleItem());
    });
  }

  void _removeSaleItem(int index) {
    setState(() {
      if (index >= 0 && index < saleItems.length) {
        saleItems[index].dispose();
        saleItems.removeAt(index);
      }
    });
  }

  void _updateSaleItem(int index) {
    if (index >= 0 && index < saleItems.length) {
      setState(() {
        final item = saleItems[index];
        item.weight = double.tryParse(item.weightController.text) ?? 10.0;
        item.pieces = int.tryParse(item.piecesController.text) ?? 1;
      });
    }
  }

  String? _validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Вазн зарур аст';
    }
    
    final weight = double.tryParse(value.trim());
    if (weight == null || weight <= 0) {
      return 'Рақами дуруст ворид кунед';
    }
    
    // Check if weight is one of the allowed values (10-50kg)
    if (!allowedWeights.contains(weight)) {
      return 'Вазн бояд 10, 15, 20, 25, 30, 35, 40, 45, 50 кг бошад';
    }
    
    return null;
  }

  String? _validatePieces(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Адад зарур аст';
    }
    
    final pieces = int.tryParse(value.trim());
    if (pieces == null || pieces <= 0) {
      return 'Рақами дуруст ворид кунед';
    }
    
    return null;
  }

  void _cancelSaleForm() {
    setState(() {
      showSaleForm = false;
      _buyerNameController.clear();
      selectedBuyerName = null;
      selectedDate = DateTime.now();
      for (final item in saleItems) {
        item.dispose();
      }
      saleItems.clear();
    });
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
    _buyerNameController.clear();
    setState(() {
      selectedBuyerName = null;
      selectedDate = DateTime.now();
      for (final item in saleItems) {
        item.dispose();
      }
      saleItems.clear();
    });
  }

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedBuyerName == null || selectedBuyerName!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Номи харидор зарур аст')),
      );
      return;
    }

    if (saleItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ақаллан як дастаи фуруш илова кунед')),
      );
      return;
    }

    // Validate warehouse inventory before saving
    final warehouseProvider = context.read<CottonWarehouseProvider>();
    final inventory = warehouseProvider.processedCottonInventory;
    
    for (final item in saleItems) {
      final matchingBatches = inventory.where((batch) => 
        (batch.weightPerPiece - item.weight).abs() <= 0.1).toList();
      
      if (matchingBatches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Вазни ${item.weight.toStringAsFixed(1)} кг дар анбор мавҷуд нест')),
        );
        return;
      }
      
      final availablePieces = matchingBatches.fold<int>(0, (sum, batch) => sum + batch.pieces);
      if (item.pieces > availablePieces) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Вазни ${item.weight.toStringAsFixed(1)} кг: дар анбор ${availablePieces} дона мавҷуд, дархост ${item.pieces} дона')),
        );
        return;
      }
    }

    try {
      // Find or create buyer
      Buyer? buyer = buyers.firstWhere(
        (b) => b.name.toLowerCase() == selectedBuyerName!.toLowerCase(),
        orElse: () => Buyer(name: selectedBuyerName!),
      );
      
      if (buyer.id == null) {
        // Create new buyer
        final buyerId = await DatabaseHelper.instance.insertBuyer(buyer);
        buyer = buyer.copyWith(id: buyerId);
        buyers.add(buyer);
      }

      // Save each sale item as separate sale record
      for (final item in saleItems) {
        final sale = CottonStockSale(
          buyerId: buyer.id!,
          saleDate: selectedDate,
          unitWeight: item.weight,
          units: item.pieces,
          totalWeight: item.totalWeight,
        );

        await DatabaseHelper.instance.insertCottonStockSale(sale);
        
        // Remove sold items from warehouse inventory
        await warehouseProvider.removeFromProcessedWarehouse(
          weightPerPiece: item.weight,
          pieces: item.pieces,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Фуруш бомуваффақият сабт шуд'),
            backgroundColor: Colors.green,
          ),
        );
        
        _cancelSaleForm();
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хато ҳангоми сабт: $e')),
        );
      }
    }
  }

  Widget _buildBuyerSalesCard(String buyerName, List<CottonStockSale> sales) {
    final totalWeight = sales.fold<double>(0, (sum, sale) => sum + sale.totalWeight);
    final totalPieces = sales.fold<int>(0, (sum, sale) => sum + sale.units);
    final latestDate = sales.map((s) => s.saleDate).reduce((a, b) => a.isAfter(b) ? a : b);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.person, color: Colors.blue, size: 20),
        ),
        title: Text(
          buyerName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Охирин харид: ${DateFormat('dd/MM/yyyy').format(latestDate)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${sales.length} фуруш',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.green,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '$totalPieces',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            'дона',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      Column(
                        children: [
                          Text(
                            '${totalWeight.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          Text(
                            'кг',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...sales.map((sale) => _buildIndividualSaleItem(sale)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualSaleItem(CottonStockSale sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(sale.saleDate),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${sale.units} × ${sale.unitWeight.toStringAsFixed(1)}кг',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Text(
            '${sale.totalWeight.toStringAsFixed(1)} кг',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

}

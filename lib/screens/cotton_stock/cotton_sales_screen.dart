import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
import '../../models/buyer.dart';
import '../../models/cotton_stock_sale.dart';
import '../../providers/cotton_warehouse_provider.dart';
import '../../providers/cotton_registry_provider.dart';
import 'cotton_sale_detail_screen.dart';
import 'buyer_cotton_sales_detail_screen.dart';

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
  final _freightCostController = TextEditingController(text: '0');
  
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
    _freightCostController.dispose();
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
        title: const Text('Фуруши пахта'),
        actions: [
          IconButton(
            onPressed: () => setState(() => showSaleForm = !showSaleForm),
            icon: Icon(showSaleForm ? Icons.remove : Icons.add),
            tooltip: showSaleForm ? 'Пӯшонидани форма' : 'Илова кардани фуруш',
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
            const SizedBox(height: 16),
            _buildFreightCostInput(),
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
    
    // Calculate overall totals
    final totalWeightAll = salesHistory.fold<double>(0, (sum, sale) => sum + sale.totalWeight);
    final totalPiecesAll = salesHistory.fold<int>(0, (sum, sale) => sum + sale.units);
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: groupedSales.isEmpty
          ? _buildEmptyHistoryState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [                                
                // List of buyers
                ..._buildBuyersList(groupedSales),
              ],
            ),
    );
  }  

  List<Widget> _buildBuyersList(Map<String, List<CottonStockSale>> groupedSales) {
    return groupedSales.entries.map((entry) {
      return _buildBuyerCard(entry.key, entry.value);
    }).toList();
  }

  Widget _buildBuyerCard(String buyerName, List<CottonStockSale> sales) {
    final totalWeight = sales.fold<double>(0, (sum, sale) => sum + sale.totalWeight);
    final totalPieces = sales.fold<int>(0, (sum, sale) => sum + sale.units);
    final latestDate = sales.map((s) => s.saleDate).reduce((a, b) => a.isAfter(b) ? a : b);
    final buyerId = sales.first.buyerId;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BuyerCottonSalesDetailScreen(
              buyerName: buyerName,
              buyerId: buyerId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with buyer name and status indicator
              Row(
                children: [
                  // Status indicator (like the colored circle in the image)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(sales),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      buyerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Date and sales count
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd.MM.yyyy').format(latestDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.shopping_cart, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          '${sales.length} фурӯш',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),                                      
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(List<CottonStockSale> sales) {
    // Determine status color based on sales
    if (sales.isEmpty) return Colors.grey;
    
    final now = DateTime.now();
    final latestSaleDate = sales.map((s) => s.saleDate).reduce((a, b) => a.isAfter(b) ? a : b);
    final daysSinceLastSale = now.difference(latestSaleDate).inDays;
    
    if (daysSinceLastSale <= 7) {
      return Colors.green; // Recent sales
    } else if (daysSinceLastSale <= 30) {
      return Colors.orange; // Somewhat recent
    } else {
      return Colors.grey; // Old sales
    }
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

  Widget _buildFreightCostInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _freightCostController,
          decoration: const InputDecoration(
            labelText: 'Хароҷоти грузчик',
            prefixIcon: Icon(Icons.inventory_2),
            suffixText: 'с',            
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              final cost = double.tryParse(value);
              if (cost == null || cost < 0) {
                return 'Хароҷоти дуруст ворид кунед';
              }
            }
            return null;
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
            suffixText: 'с',
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
                      suffixText: 'шт',                      
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => _validatePieces(value),
                    onChanged: (value) => _updateSaleItem(index),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),           
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
    final cottonAmount = totalWeight * pricePerKg;
    final freightCost = double.tryParse(_freightCostController.text) ?? 0;
    final totalAmount = cottonAmount + freightCost;
    
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
            const SizedBox(height: 8),
            _buildSummaryRow('Нархи пахта', '${cottonAmount.toStringAsFixed(2)} сомонӣ'),
            if (freightCost > 0) ...[
              const SizedBox(height: 8),
              _buildSummaryRow('Хароҷоти грузчик', '${freightCost.toStringAsFixed(2)} сомонӣ'),
            ],
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
            'Ҳеҷ сабти фуруш',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Сабтҳои фуруш дар инҷо намоиш дода мешаванд',
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

      // Calculate total amount if price is set
      double? salePricePerKg;
      if (pricePerKg > 0) {
        salePricePerKg = pricePerKg;
      }

      // Get freight cost and distribute it proportionally across items
      final totalFreightCost = double.tryParse(_freightCostController.text) ?? 0;
      final totalWeight = saleItems.fold<double>(0, (sum, item) => sum + item.totalWeight);

      // Save each sale item as separate sale record
      final List<int> savedSaleIds = [];
      for (final item in saleItems) {
        // Calculate proportional freight cost for this item
        final itemFreightCost = totalWeight > 0 ? (item.totalWeight / totalWeight) * totalFreightCost : 0.0;
        
        final sale = CottonStockSale(
          buyerId: buyer.id!,
          saleDate: selectedDate,
          unitWeight: item.weight,
          units: item.pieces,
          totalWeight: item.totalWeight,
          pricePerKg: salePricePerKg,
          totalAmount: salePricePerKg != null ? item.totalWeight * salePricePerKg : null,
          freightCost: itemFreightCost.toDouble(),
        );

        final saleId = await DatabaseHelper.instance.insertCottonStockSale(sale);
        savedSaleIds.add(saleId);
        
        // Remove sold items from warehouse inventory
        await warehouseProvider.removeFromProcessedWarehouse(
          weightPerPiece: item.weight,
          pieces: item.pieces,
        );
      }
      
      // Refresh all cotton-related providers
      await Future.wait([
        context.read<CottonRegistryProvider>().loadAllData(),
        warehouseProvider.loadAllData(),
      ]);
      
      // Refresh sales history
      final updatedSalesData = await DatabaseHelper.instance.getAllCottonStockSales();
      
      if (mounted) {
        setState(() {
          salesHistory = updatedSalesData as List<CottonStockSale>;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${savedSaleIds.length} фурӯш бомуваффақият сабт шуд',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        
        // Reset form and show success message
        _cancelSaleForm();                
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Хато ҳангоми сабт: ${e.toString()}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      
      // Log error for debugging
      debugPrint('Error saving sale: $e');
    }
  }  

  Widget _buildDialogSummaryRow(String label, String value, IconData icon, Color color, {bool isTotal = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? color : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildIndividualSaleItem(CottonStockSale sale) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CottonSaleDetailScreen(sales: [sale]),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(sale.saleDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${sale.totalWeight.toStringAsFixed(1)} кг',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${sale.units} дона × ${sale.unitWeight.toStringAsFixed(1)} кг',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          if (sale.pricePerKg != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Нархи 1 кг:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                Text(
                  '${sale.pricePerKg!.toStringAsFixed(2)} сомонӣ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
          if (sale.totalAmount != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    const Text(
                      'Ҷамъи маблағ:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${sale.totalAmount!.toStringAsFixed(2)} сомонӣ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
        ],
        ),
      ),
    );
  }
}
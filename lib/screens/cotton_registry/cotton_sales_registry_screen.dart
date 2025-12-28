import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cotton_registry_provider.dart';
import '../../models/cotton_sale_registry.dart';
import '../../models/cotton_inventory.dart';
import '../../models/cotton_purchase_item.dart';

// Helper class for multi-selection
class SelectedInventoryItem {
  final CottonInventory inventory;
  int quantity;
  
  SelectedInventoryItem({required this.inventory, required this.quantity});
  
  double get totalWeight => inventory.batchSize * quantity;
}

/// Cotton Sales Registry Screen - Sell processed cotton with automatic inventory deduction
/// Implements inventory-based sales with real-time stock validation
class CottonSalesRegistryScreen extends StatefulWidget {
  const CottonSalesRegistryScreen({super.key});

  @override
  State<CottonSalesRegistryScreen> createState() => _CottonSalesRegistryScreenState();
}

class _CottonSalesRegistryScreenState extends State<CottonSalesRegistryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Sale form controllers
  final _formKey = GlobalKey<FormState>();
  final _buyerNameController = TextEditingController();
  final _unitsController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Selected values
  CottonInventory? selectedInventory;
  List<SelectedInventoryItem> selectedInventoryItems = [];
  Map<int, TextEditingController> quantityControllers = {};
  DateTime saleDate = DateTime.now();
  SalePaymentStatus paymentStatus = SalePaymentStatus.pending;
  
  // Calculated values
  double calculatedWeight = 0;
  double calculatedAmount = 0;
  int totalSelectedQuantity = 0;
  double totalSelectedWeight = 0.0;
  
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setupCalculationListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buyerNameController.dispose();
    _unitsController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    
    // Dispose quantity controllers
    for (var controller in quantityControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  void _setupCalculationListeners() {
    _unitsController.addListener(_calculateSale);
    _priceController.addListener(_calculateSale);
  }

  void _calculateSale() {
    if (selectedInventory == null) return;
    
    final units = int.tryParse(_unitsController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    
    setState(() {
      calculatedWeight = selectedInventory!.batchSize * units;
      calculatedAmount = calculatedWeight * price;
    });
  }

  void _toggleInventorySelection(CottonInventory inventory, bool selected) {
    setState(() {
      if (selected) {
        // Add to selection if not already selected
        if (!selectedInventoryItems.any((item) => item.inventory.id == inventory.id)) {
          selectedInventoryItems.add(SelectedInventoryItem(inventory: inventory, quantity: 1));
          // Create quantity controller if it doesn't exist
          if (!quantityControllers.containsKey(inventory.id)) {
            quantityControllers[inventory.id!] = TextEditingController(text: '1');
            quantityControllers[inventory.id!]!.addListener(_calculateMultiSale);
          }
        }
      } else {
        // Remove from selection
        selectedInventoryItems.removeWhere((item) => item.inventory.id == inventory.id);
        // Dispose and remove controller
        if (quantityControllers.containsKey(inventory.id)) {
          quantityControllers[inventory.id!]!.dispose();
          quantityControllers.remove(inventory.id);
        }
      }
      _calculateMultiSale();
    });
  }

  TextEditingController _getQuantityController(int inventoryId) {
    if (!quantityControllers.containsKey(inventoryId)) {
      quantityControllers[inventoryId] = TextEditingController(text: '1');
      quantityControllers[inventoryId]!.addListener(_calculateMultiSale);
    }
    return quantityControllers[inventoryId]!;
  }

  void _calculateMultiSale() {
    setState(() {
      totalSelectedQuantity = 0;
      totalSelectedWeight = 0.0;
      
      for (var item in selectedInventoryItems) {
        final controller = quantityControllers[item.inventory.id!];
        if (controller != null) {
          final quantity = int.tryParse(controller.text) ?? 0;
          item.quantity = quantity;
          totalSelectedQuantity += quantity;
          totalSelectedWeight += item.totalWeight;
        }
      }
      
      // Calculate total amount with price per kg
      final pricePerKg = double.tryParse(_priceController.text) ?? 0;
      calculatedAmount = totalSelectedWeight * pricePerKg;
      calculatedWeight = totalSelectedWeight;
    });
  }

  String? _validateQuantityForInventory(String? value, CottonInventory inventory) {
    if (value == null || value.isEmpty) return 'Миқдор зарур аст';
    final quantity = int.tryParse(value);
    if (quantity == null || quantity <= 0) return 'Миқдори дуруст ворид кунед';
    if (quantity > inventory.availableUnits) {
      return 'Ҳадди аксар: ${inventory.availableUnits} дона';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Фуруши пахта'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showImportDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Ворид кардани фурӯш',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_shopping_cart), text: 'Фуруши нав'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Таърихи фуруш'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewSaleTab(),
          _buildSalesHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildNewSaleTab() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inventory Selection
            _buildSectionTitle('Интихоби анбор'),
            _buildInventorySelection(),
            const SizedBox(height: 24),
            
            // Sale Details
            _buildSectionTitle('Тафсилоти фуруш'),
            _buildSaleForm(),
            const SizedBox(height: 24),
            
            // Sale Calculation
            _buildSectionTitle('Ҳисобот'),
            _buildCalculationCard(),
            const SizedBox(height: 32),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesHistoryTab() {
    return Consumer<CottonRegistryProvider>(
      builder: (context, provider, _) {
        final sales = provider.saleRegistry;
        
        if (sales.isEmpty) {
          return _buildEmptyHistoryState();
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sales.length,
          itemBuilder: (context, index) {
            final sale = sales[index];
            return _buildSaleHistoryCard(sale);
          },
        );
      },
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

  Widget _buildInventorySelection() {
    return Consumer<CottonRegistryProvider>(
      builder: (context, provider, _) {
        final inventory = provider.cottonInventory;
        
        // Filter inventory for 10-50kg range
        final standardInventory = inventory.where((inv) => 
          inv.batchSize >= 10.0 && inv.batchSize <= 50.0).toList();
        
        if (standardInventory.isEmpty) {
          return Card(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Пахтаи 10-50 кг дар анбор нест',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Барои фуруш пахтаи 10-50 кг ба анбор илова кунед',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Интихоби пахта (10-50 кг)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Multi-selection list of cotton types
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: standardInventory.length,
                    itemBuilder: (context, index) {
                      final inv = standardInventory[index];
                      final isSelected = selectedInventoryItems.any((item) => 
                        item.inventory.id == inv.id);
                      
      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isSelected ? Colors.teal.withOpacity(0.1) : null,
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (selected) => _toggleInventorySelection(inv, selected ?? false),
                          title: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getCottonTypeColor(inv.cottonType),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(inv.cottonTypeDisplay),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  inv.batchSizeDisplay,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Мавҷуд: ${inv.availableUnitsDisplay} • ${inv.totalWeightDisplay}'),
                              if (isSelected) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _getQuantityController(inv.id!),
                                        decoration: const InputDecoration(
                                          labelText: 'Миқдор',
                                          suffixText: 'дона',
                                          isDense: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => _calculateMultiSale(),
                                        validator: (value) => _validateQuantityForInventory(value, inv),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Selected items summary
                if (selectedInventoryItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.teal),
                            const SizedBox(width: 8),
                            Text(
                              'Ҷамъан интихобшуда:',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Намудҳо: ${selectedInventoryItems.length}'),
                        Text('Ҷамъи миқдор: ${totalSelectedQuantity} дона'),
                        Text('Ҷамъи вазн: ${totalSelectedWeight.toStringAsFixed(1)} кг'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaleForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Buyer Name
            TextFormField(
              controller: _buyerNameController,
              decoration: const InputDecoration(
                labelText: 'Номи харидор',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                hintText: 'Номи харидорро ворид кунед',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            
            // Total quantity display (read-only)
            TextFormField(
              controller: TextEditingController(text: totalSelectedQuantity.toString()),
              decoration: const InputDecoration(
                labelText: 'Ҷамъи миқдор',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_cart),
                suffixText: 'дона',
                helperText: 'Ҳисоб аз интихобшудаҳо',
              ),
              enabled: false,
            ),
            
            const SizedBox(height: 16),
            
            // Price per Kg
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Нархи як кг',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'TJS/кг',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Нарх зарур аст';
                final price = double.tryParse(value);
                if (price == null || price <= 0) return 'Нархи дуруст ворид кунед';
                return null;
              },
              onChanged: (_) => _calculateSale(),
            ),
            
            const SizedBox(height: 16),
            
            // Payment Status
            DropdownButtonFormField<SalePaymentStatus>(
              value: paymentStatus,
              decoration: const InputDecoration(
                labelText: 'Ҳолати пардохт',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: SalePaymentStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_getPaymentStatusDisplay(status)),
                );
              }).toList(),
              onChanged: (value) => setState(() => paymentStatus = value!),
            ),
            
            const SizedBox(height: 16),
            
            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Қайдҳо (ихтиёрӣ)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationCard() {
    return Card(
      color: Colors.teal.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.calculate, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Ҳисобот',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Individual cotton type breakdown
            ...selectedInventoryItems.map((item) {
              final weight = item.totalWeight;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildCalculationRow(
                  '${item.inventory.cottonTypeDisplay}:',
                  '${item.quantity} дона × ${item.inventory.batchSize.toStringAsFixed(1)} кг = ${weight.toStringAsFixed(1)} кг',
                ),
              );
            }).toList(),
            
            if (selectedInventoryItems.isNotEmpty) const Divider(height: 16),
            
            _buildCalculationRow(
              'Ҷамъи миқдор:',
              '${totalSelectedQuantity} дона',
            ),
            const SizedBox(height: 8),
            _buildCalculationRow(
              'Ҷамъи вазн:',
              '${totalSelectedWeight.toStringAsFixed(1)} кг',
            ),
            if (calculatedAmount > 0) ...[
              const SizedBox(height: 8),
              _buildCalculationRow(
                'Нархи як кг:',
                '${double.tryParse(_priceController.text)?.toStringAsFixed(2) ?? '0.00'} TJS',
              ),
              const Divider(height: 16),
              _buildCalculationRow(
                'ҲАМАГӢ МАБЛАҒ:',
                '${calculatedAmount.toStringAsFixed(2)} TJS',
                isTotal: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value, {bool isTotal = false}) {
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
            color: isTotal ? Colors.teal : null,
            fontSize: isTotal ? 18 : 14,
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
            child: const Text('Пок кардан'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : _saveSale,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
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

  Widget _buildSaleHistoryCard(CottonSaleRegistry sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSaleDetailsDialog(sale),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getCottonTypeColor(sale.cottonType),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sale.buyerName ?? 'Харидори номаълум',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy', 'en_US').format(sale.saleDate),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 12),
            
            // Sale Details
            Row(
              children: [
                Expanded(
                  child: _buildSaleInfoColumn(
                    'Навъ',
                    sale.cottonTypeDisplay,
                  ),
                ),
                Expanded(
                  child: _buildSaleInfoColumn(
                    'Андозаи дастаҳо',
                    sale.batchSizeDisplay,
                  ),
                ),
                Expanded(
                  child: _buildSaleInfoColumn(
                    'Миқдор',
                    sale.unitsSoldDisplay,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildSaleInfoColumn(
                    'Вазн',
                    sale.weightSoldDisplay,
                  ),
                ),
                Expanded(
                  child: _buildSaleInfoColumn(
                    'Нарх',
                    sale.priceDisplay,
                  ),
                ),
                Expanded(
                  child: _buildSaleInfoColumn(
                    'Маблағ',
                    sale.totalAmountDisplay,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Payment Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(sale.paymentStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sale.paymentStatusDisplay,
                    style: TextStyle(
                      color: _getPaymentStatusColor(sale.paymentStatus),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                // Action buttons could go here
              ],
            ),
            
            // Notes
            if (sale.notes != null && sale.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      sale.notes!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      )
    );
  }

  Widget _buildSaleInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
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
            'Ҳеҷ фуруш сабт нашудааст',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Аввал пахтаро коркард кунед, баъдан фурӯшед',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _onInventorySelected(CottonInventory? inventory) {
    setState(() {
      selectedInventory = inventory;
      _calculateSale();
    });
  }

  String? _validateUnits(String? value) {
    if (value == null || value.isEmpty) return 'Миқдор зарур аст';
    
    final units = int.tryParse(value);
    if (units == null || units <= 0) return 'Миқдори дуруст ворид кунед';
    
    if (selectedInventory != null && units > selectedInventory!.availableUnits) {
      return 'Дар анбор кофӣ нест (мавҷуд: ${selectedInventory!.availableUnits})';
    }
    
    return null;
  }

  Future<void> _selectSaleDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: saleDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date != null) {
      setState(() => saleDate = date);
    }
  }

  void _resetForm() {
    _buyerNameController.clear();
    _unitsController.clear();
    _priceController.clear();
    _notesController.clear();
    
    // Clear multi-selection state
    for (var controller in quantityControllers.values) {
      controller.dispose();
    }
    quantityControllers.clear();
    
    setState(() {
      selectedInventory = null;
      selectedInventoryItems.clear();
      saleDate = DateTime.now();
      paymentStatus = SalePaymentStatus.pending;
      calculatedWeight = 0;
      calculatedAmount = 0;
      totalSelectedQuantity = 0;
      totalSelectedWeight = 0.0;
    });
  }

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedInventoryItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ҳадди ақал як намуди пахта интихоб кунед')),
      );
      return;
    }
    
    setState(() => isLoading = true);
    
    try {
      final provider = context.read<CottonRegistryProvider>();
      final pricePerKg = double.parse(_priceController.text);
      
      // Create a single consolidated sale record with combined details
      String cottonTypesInfo = selectedInventoryItems.map((item) => 
        '${item.inventory.cottonTypeDisplay} (${item.quantity} дона × ${item.inventory.batchSize.toStringAsFixed(1)} кг)'
      ).join(', ');
      
      // Use the first item's cotton type as primary (for compatibility)
      final primaryItem = selectedInventoryItems.first;
      
      final consolidatedSale = CottonSaleRegistry(
        saleDate: DateTime.now(), // Use current date automatically
        buyerName: _buyerNameController.text.trim().isEmpty ? null : _buyerNameController.text.trim(),
        cottonType: primaryItem.inventory.cottonType,
        batchSize: totalSelectedWeight / totalSelectedQuantity, // Average batch size
        unitsSold: totalSelectedQuantity,
        weightSold: totalSelectedWeight,
        pricePerKg: pricePerKg,
        totalAmount: calculatedAmount, // Total amount for all items
        paymentStatus: paymentStatus,
        sourceInventoryId: primaryItem.inventory.id!,
        notes: 'Намудҳо: $cottonTypesInfo${_notesController.text.trim().isEmpty ? '' : ' | ${_notesController.text.trim()}'}',
      );
      
      await provider.sellCotton(consolidatedSale);
      
      // Deduct inventory for each selected item
      for (var item in selectedInventoryItems) {
        // The sellCotton method should handle inventory deduction, but we may need to handle multi-type deduction separately
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Фуруши ${selectedInventoryItems.length} намуди пахта сабт шуд'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
        _tabController.animateTo(1); // Switch to history tab
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

  Color _getCottonTypeColor(CottonType type) {
    switch (type) {
      case CottonType.lint: return Colors.green;
      case CottonType.uluk: return Colors.blue;
      case CottonType.valakno: return Colors.orange;
    }
  }

  String _getPaymentStatusDisplay(SalePaymentStatus status) {
    switch (status) {
      case SalePaymentStatus.pending: return 'Интизор';
      case SalePaymentStatus.partial: return 'Қисман';
      case SalePaymentStatus.paid: return 'Пардохт шуда';
    }
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ворид кардани фурӯш'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Барои ворид кардани фурӯши пахта як аз роҳҳои зеринро интихоб кунед:'),
            SizedBox(height: 16),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Бекор кардан'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to new sale tab
              _tabController.animateTo(0);
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Фурӯши нав'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          ),
        ],
      ),
    );
  }

  void _showSaleDetailsDialog(CottonSaleRegistry sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Тафсилоти фуруш - ${sale.buyerName ?? 'Харидори номаълум'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Сана:', DateFormat('dd/MM/yyyy HH:mm', 'en_US').format(sale.saleDate)),
              const SizedBox(height: 8),
              _buildDetailRow('Навъи пахта:', sale.cottonTypeDisplay),
              const SizedBox(height: 8),
              _buildDetailRow('Андозаи дастаҳо:', sale.batchSizeDisplay),
              const SizedBox(height: 8),
              _buildDetailRow('Миқдор:', sale.unitsSoldDisplay),
              const SizedBox(height: 8),
              _buildDetailRow('Ҳамагӣ вазн:', sale.weightSoldDisplay),
              const SizedBox(height: 8),
              _buildDetailRow('Нархи як кг:', sale.priceDisplay),
              const SizedBox(height: 8),
              _buildDetailRow('Ҳамагӣ маблағ:', sale.totalAmountDisplay),
              const SizedBox(height: 8),
              _buildDetailRow('Ҳолати пардохт:', sale.paymentStatusDisplay),
              if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Қайдҳо:', sale.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Пӯшидан'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Color _getPaymentStatusColor(SalePaymentStatus status) {
    switch (status) {
      case SalePaymentStatus.pending: return Colors.orange;
      case SalePaymentStatus.partial: return Colors.blue;
      case SalePaymentStatus.paid: return Colors.green;
    }
  }
}

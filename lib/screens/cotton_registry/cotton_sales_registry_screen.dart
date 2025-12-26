import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cotton_registry_provider.dart';
import '../../models/cotton_sale_registry.dart';
import '../../models/cotton_inventory.dart';
import '../../models/cotton_purchase_item.dart';

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
  DateTime saleDate = DateTime.now();
  SalePaymentStatus paymentStatus = SalePaymentStatus.pending;
  
  // Calculated values
  double calculatedWeight = 0;
  double calculatedAmount = 0;
  
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Реестри фуруши пахта'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
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
        final availableInventory = provider.cottonInventory
            .where((inv) => !inv.isEmpty)
            .toList();
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<CottonInventory>(
                  value: selectedInventory,
                  decoration: const InputDecoration(
                    labelText: 'Дастаи пахта',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  items: availableInventory.map((inventory) {
                    return DropdownMenuItem(
                      value: inventory,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getCottonTypeColor(inventory.cottonType),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(inventory.cottonTypeDisplay),
                              const Spacer(),
                              Text(
                                inventory.batchSizeDisplay,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Text(
                            '${inventory.availableUnitsDisplay} • ${inventory.totalWeightDisplay}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _onInventorySelected,
                  validator: (value) => value == null ? 'Дастаи пахта интихоб кунед' : null,
                ),
                
                // Available Stock Info
                if (selectedInventory != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.teal),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Мавҷуд: ${selectedInventory!.availableUnitsDisplay}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Ҳамагӣ вазн: ${selectedInventory!.totalWeightDisplay}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Статус: ${selectedInventory!.statusDisplay}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
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
            
            // Units to Sell
            TextFormField(
              controller: _unitsController,
              decoration: InputDecoration(
                labelText: 'Миқдори фуруш',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.shopping_cart),
                suffixText: 'дона',
                helperText: selectedInventory != null
                    ? 'Ҳадди аксар: ${selectedInventory!.availableUnits} дона'
                    : null,
              ),
              keyboardType: TextInputType.number,
              validator: _validateUnits,
              onChanged: (_) => _calculateSale(),
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
            
            // Sale Date
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Санаи фуруш'),
              subtitle: Text(DateFormat('dd/MM/yyyy', 'en_US').format(saleDate)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _selectSaleDate,
            ),
            
            const Divider(),
            
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
                const Icon(Icons.calculator, color: Colors.teal),
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
            
            _buildCalculationRow(
              'Миқдор:',
              '${int.tryParse(_unitsController.text) ?? 0} дона',
            ),
            const SizedBox(height: 8),
            _buildCalculationRow(
              'Андозаи дастаҳо:',
              selectedInventory?.batchSizeDisplay ?? '0 кг/дона',
            ),
            const SizedBox(height: 8),
            _buildCalculationRow(
              'Ҳамагӣ вазн:',
              '${calculatedWeight.toStringAsFixed(1)} кг',
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
    
    setState(() {
      selectedInventory = null;
      saleDate = DateTime.now();
      paymentStatus = SalePaymentStatus.pending;
      calculatedWeight = 0;
      calculatedAmount = 0;
    });
  }

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedInventory == null) return;
    
    setState(() => isLoading = true);
    
    try {
      final provider = context.read<CottonRegistryProvider>();
      
      final sale = CottonSaleRegistry(
        saleDate: saleDate,
        buyerName: _buyerNameController.text.trim().isEmpty ? null : _buyerNameController.text.trim(),
        cottonType: selectedInventory!.cottonType,
        batchSize: selectedInventory!.batchSize,
        unitsSold: int.parse(_unitsController.text),
        weightSold: calculatedWeight,
        pricePerKg: double.parse(_priceController.text),
        totalAmount: calculatedAmount,
        paymentStatus: paymentStatus,
        sourceInventoryId: selectedInventory!.id!,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      
      await provider.sellCotton(sale);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Фуруш бо муваффақият сабт шуд'),
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

  Color _getPaymentStatusColor(SalePaymentStatus status) {
    switch (status) {
      case SalePaymentStatus.pending: return Colors.orange;
      case SalePaymentStatus.partial: return Colors.blue;
      case SalePaymentStatus.paid: return Colors.green;
    }
  }
}

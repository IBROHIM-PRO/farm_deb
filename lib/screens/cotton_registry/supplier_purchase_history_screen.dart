import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cotton_registry_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/cotton_purchase_registry.dart';
import '../../models/cotton_purchase_item.dart';
import 'add_cotton_purchase_screen.dart';

/// Supplier Purchase History Screen
/// Shows all cotton purchases for a specific supplier
class SupplierPurchaseHistoryScreen extends StatefulWidget {
  final String supplierName;

  const SupplierPurchaseHistoryScreen({
    super.key,
    required this.supplierName,
  });

  @override
  State<SupplierPurchaseHistoryScreen> createState() => _SupplierPurchaseHistoryScreenState();
}

class _SupplierPurchaseHistoryScreenState extends State<SupplierPurchaseHistoryScreen> {
  List<CottonPurchaseRegistry> _purchases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSupplierPurchases();
  }

  Future<void> _loadSupplierPurchases() async {
    setState(() => _isLoading = true);
    
    try {
      final provider = context.read<CottonRegistryProvider>();
      final purchases = await provider.getPurchasesBySupplier(widget.supplierName);
      setState(() {
        _purchases = purchases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Хатогӣ дар боркунии маълумот: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.supplierName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (!_isLoading)
              Text(
                '${_purchases.length} харид',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _purchases.isEmpty
              ? _buildEmptyState()
              : _buildPurchasesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Ҳеҷ харид ёфт нашуд',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Барои ин таъминкунанда ягон харид сабт нашудааст',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasesList() {
    // Calculate overall totals
    final totalWeight = _calculateTotalWeight();
    final totalAmount = _calculateTotalAmount();
    
    return Column(
      children: [        
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ҳамаи харидҳо',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Purchases List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSupplierPurchases,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 8),
                ..._buildGroupedPurchases(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGroupedPurchases() {
    // Group purchases by date
    final Map<String, List<CottonPurchaseRegistry>> groupedPurchases = {};
    for (var purchase in _purchases) {
      final dateKey = DateFormat('dd/MM/yyyy').format(purchase.purchaseDate);
      if (!groupedPurchases.containsKey(dateKey)) {
        groupedPurchases[dateKey] = [];
      }
      groupedPurchases[dateKey]!.add(purchase);
    }
    
    // Sort dates in descending order (newest first)
    final sortedDates = groupedPurchases.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    final List<Widget> widgets = [];
    
    for (var dateKey in sortedDates) {
      final purchases = groupedPurchases[dateKey]!;
      // Sort purchases within each date (newest first)
      purchases.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      
      widgets.add(_buildDateGroup(dateKey, purchases));
      widgets.add(const SizedBox(height: 12));
    }
    
    return widgets;
  }

  Widget _buildDateGroup(String dateKey, List<CottonPurchaseRegistry> purchases) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            dateKey,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        
        // Purchases list
        ...purchases.map((purchase) => _buildPurchaseCard(purchase)),
      ],
    );
  }

  Widget _buildPurchaseCard(CottonPurchaseRegistry purchase) {
    final provider = context.read<CottonRegistryProvider>();
    final items = provider.getItemsForPurchase(purchase.id!);
    
    final totalWeight = items.fold(0.0, (sum, item) => sum + item.weight);
    final totalUnits = items.fold(0, (sum, item) => sum + item.units);
    final itemsTotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final totalAmount = itemsTotal + purchase.transportationCost;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Edit/Delete buttons at the top
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, _) {
              if (!settingsProvider.editDeleteEnabled) {
                return const SizedBox.shrink();
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                      onPressed: () => _navigateToEditPurchase(context, purchase, items),
                      tooltip: 'Таҳрир',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 18,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () => _confirmDeletePurchase(context, purchase),
                      tooltip: 'Нест кардан',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 18,
                    ),
                  ],
                ),
              );
            },
          ),
          // Card content
          GestureDetector(
            onTap: () => _showPurchaseDetailsModal(purchase, items, totalWeight, totalUnits, totalAmount),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Харид №${purchase.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.length} навъ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Details
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weight
                    Row(
                      children: [
                        Text(
                          'Вазн:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${totalWeight.toStringAsFixed(1)} кг',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Units
                    Row(
                      children: [
                        Text(
                          'Донаҳо:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$totalUnits шт',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Amount
                    Row(
                      children: [
                        Text(
                          'Маблағ:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${totalAmount.toStringAsFixed(2)} сомонӣ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
                  // Arrow indicator
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Confirm delete purchase
  Future<void> _confirmDeletePurchase(BuildContext context, CottonPurchaseRegistry purchase) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Тасдиқ кунед'),
        content: const Text('Шумо мутмаин ҳастед, ки мехоҳед ин харидро нест кунед? Ин амал бозгашт карда намешавад.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Бекор кардан'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Нест кардан'),
          ),
        ],
      ),
    );
    
    if (confirm == true && context.mounted) {
      try {
        final provider = context.read<CottonRegistryProvider>();
        await provider.deletePurchaseRegistry(purchase.id!);
        await _loadSupplierPurchases();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Харид бомуваффақият нест карда шуд'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Хато: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  double _calculateTotalWeight() {
    double total = 0;
    final provider = context.read<CottonRegistryProvider>();
    
    for (var purchase in _purchases) {
      final items = provider.getItemsForPurchase(purchase.id!);
      total += items.fold(0.0, (sum, item) => sum + item.weight);
    }
    
    return total;
  }

  double _calculateTotalAmount() {
    double total = 0;
    final provider = context.read<CottonRegistryProvider>();
    
    for (var purchase in _purchases) {
      final items = provider.getItemsForPurchase(purchase.id!);
      final itemsTotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
      total += itemsTotal + purchase.transportationCost;
    }
    
    return total;
  }

  void _showPurchaseDetailsModal(
    CottonPurchaseRegistry purchase,
    List<CottonPurchaseItem> items,
    double totalWeight,
    int totalUnits,
    double totalAmount,
  ) {
    final itemsTotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Харид №${purchase.id}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('dd.MM.yyyy').format(purchase.purchaseDate),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToEditPurchase(context, purchase, items);
                        },
                        icon: const Icon(Icons.edit, size: 24, color: Colors.blue),
                        tooltip: 'Таҳрир',
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 24),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Summary section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            _buildModalRow('Донаҳо:', '$totalUnits шт'),
                            const SizedBox(height: 12),
                            _buildModalRow('Вазни умуми:', '${totalWeight.toStringAsFixed(1)} кг'),
                            const SizedBox(height: 12),
                            _buildModalRow('Ҷамъи маблағ:', '${totalAmount.toStringAsFixed(2)} сомонӣ'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Items section
                      Text(
                        'Навъҳои пахта:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      ...items.map((item) {
                        return Container(
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
                              Text(
                                item.cottonTypeDisplay,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildItemRow('Вазн:', '${item.weight.toStringAsFixed(1)} кг'),
                              const SizedBox(height: 4),
                              _buildItemRow('Нархи 1 кг:', '${item.pricePerKg.toStringAsFixed(2)} сомонӣ'),
                              const SizedBox(height: 4),
                              _buildItemRow('Ҷамъи маблағ:', '${item.totalPrice.toStringAsFixed(2)} сомонӣ'),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      // Transportation cost if exists
                      if (purchase.transportationCost > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Хароҷоти нақлиёт',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildItemRow('Маблағ:', '${purchase.transportationCost.toStringAsFixed(2)} сомонӣ'),
                            ],
                          ),
                        ),
                      ],
                      
                      // Freight cost if exists
                      if (purchase.freightCost > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.local_shipping, size: 16, color: Colors.orange[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Хароҷоти грузчик',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildItemRow('Маблағ:', '${purchase.freightCost.toStringAsFixed(2)} сомонӣ'),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  // Navigate to full edit form (same as add form)
  void _navigateToEditPurchase(
    BuildContext context,
    CottonPurchaseRegistry purchase,
    List<CottonPurchaseItem> items,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCottonPurchaseScreen(
          purchase: purchase,
          purchaseItems: items,
        ),
      ),
    );
    
    // Refresh after editing
    if (mounted) {
      await _loadSupplierPurchases();
    }
  }
  
  // Inline edit form for cotton purchase basic info (kept for quick edits)
  void _showPurchaseEditForm(BuildContext context, CottonPurchaseRegistry purchase) {
    final formKey = GlobalKey<FormState>();
    final supplierController = TextEditingController(text: purchase.supplierName);
    final transportController = TextEditingController(
      text: purchase.transportationCost.toString(),
    );
    final freightController = TextEditingController(
      text: purchase.freightCost.toString(),
    );
    final notesController = TextEditingController(text: purchase.notes ?? '');
    DateTime purchaseDate = purchase.purchaseDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Таҳрири харид',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Supplier name
                    TextFormField(
                      controller: supplierController,
                      decoration: const InputDecoration(
                        labelText: 'Номи таъминкунанда',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Номи таъминкунанда зарур аст';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Purchase date
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: purchaseDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => purchaseDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Санаи харид',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(purchaseDate),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Transportation cost
                    TextFormField(
                      controller: transportController,
                      decoration: const InputDecoration(
                        labelText: 'Хароҷоти нақлиёт',
                        suffixText: 'с',
                        prefixIcon: Icon(Icons.local_shipping),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Адади дуруст ворид кунед';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Freight cost
                    TextFormField(
                      controller: freightController,
                      decoration: const InputDecoration(
                        labelText: 'Хароҷоти грузчик',
                        suffixText: 'с',
                        prefixIcon: Icon(Icons.inventory_2),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Адади дуруст ворид кунед';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Notes
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Эзоҳ (ихтиёрӣ)',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Save and Delete buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                try {
                                  final provider = context.read<CottonRegistryProvider>();
                                  
                                  final updatedPurchase = purchase.copyWith(
                                    supplierName: supplierController.text.trim(),
                                    purchaseDate: purchaseDate,
                                    transportationCost: double.tryParse(transportController.text) ?? 0,
                                    freightCost: double.tryParse(freightController.text) ?? 0,
                                    notes: notesController.text.trim().isNotEmpty 
                                      ? notesController.text.trim() 
                                      : null,
                                  );
                                  
                                  await provider.updatePurchaseRegistry(updatedPurchase);
                                  await _loadSupplierPurchases();
                                  
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Харид бомуваффақият таҳрир шуд'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Хато: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Нигоҳ доштан'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Тасдиқ кунед'),
                                  content: const Text('Шумо мутмаин ҳастед, ки мехоҳед ин харидро нест кунед? Ин амал бозгашт карда намешавад.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Бекор кардан'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Нест кардан'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirm == true && context.mounted) {
                                try {
                                  final provider = context.read<CottonRegistryProvider>();
                                  await provider.deletePurchaseRegistry(purchase.id!);
                                  await _loadSupplierPurchases();
                                  
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Харид бомуваффақият нест карда шуд'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Хато: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Нест кардан'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
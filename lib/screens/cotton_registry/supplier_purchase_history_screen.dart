import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cotton_registry_provider.dart';
import '../../models/cotton_purchase_registry.dart';
import '../../models/cotton_purchase_item.dart';

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

    return GestureDetector(
      onTap: () => _showPurchaseDetailsModal(purchase, items, totalWeight, totalUnits, totalAmount),
      child: Container(
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
    );
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
}
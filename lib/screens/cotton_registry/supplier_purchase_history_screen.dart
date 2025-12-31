import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cotton_registry_provider.dart';
import '../../models/cotton_purchase_registry.dart';
import '../../models/cotton_purchase_item.dart';
import 'cotton_purchase_detail_screen.dart';

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
      final purchases = await context.read<CottonRegistryProvider>().getPurchasesBySupplier(widget.supplierName);
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
            const Text('Таърихи харид', style: TextStyle(fontSize: 18)),            
          ],
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 2,
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
    // Calculate totals
    final totalPurchases = _purchases.length;
    final totalAmount = _purchases.fold(0.0, (sum, purchase) {
      final items = context.read<CottonRegistryProvider>().getItemsForPurchase(purchase.id!);
      final itemsTotal = items.fold(0.0, (itemSum, item) => itemSum + item.totalPrice);
      return sum + itemsTotal + purchase.transportationCost;
    });

    // Group purchases by date
    final Map<String, List<CottonPurchaseRegistry>> groupedPurchases = {};
    for (var purchase in _purchases) {
      final dateKey = DateFormat('dd/MM/yyyy').format(purchase.purchaseDate);
      if (!groupedPurchases.containsKey(dateKey)) {
        groupedPurchases[dateKey] = [];
      }
      groupedPurchases[dateKey]!.add(purchase);
    }

    return Column(
      children: [
        // Purchases List grouped by date
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: groupedPurchases.length,
            itemBuilder: (context, index) {
              final dateKey = groupedPurchases.keys.elementAt(index);
              final purchases = groupedPurchases[dateKey]!;
              return _buildDateGroup(dateKey, purchases);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }


  Widget _buildDateGroup(String dateKey, List<CottonPurchaseRegistry> purchases) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...purchases.map((purchase) => _buildPurchaseCard(purchase)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPurchaseCard(CottonPurchaseRegistry purchase) {
    final provider = context.read<CottonRegistryProvider>();
    final items = provider.getItemsForPurchase(purchase.id!);
    final summary = provider.getPurchaseSummary(purchase.id!);
    
    final totalWeight = items.fold(0.0, (sum, item) => sum + item.weight);
    final totalUnits = items.fold(0, (sum, item) => sum + item.units);
    final grandTotal = summary['grandTotal'] as double;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showPurchaseDetailModal(purchase, items, summary),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Харид №${purchase.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${totalWeight.toStringAsFixed(1)} кг • $totalUnits шт',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.green, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd/MM/yyyy').format(purchase.purchaseDate),
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
      ),
    );
  }

  Color _getCottonTypeColor(CottonType type) {
    switch (type) {
      case CottonType.lint:
        return Colors.green;
      case CottonType.uluk:
        return Colors.blue;
      case CottonType.valakno:
        return Colors.orange;
    }
  }

  void _showPurchaseDetailModal(CottonPurchaseRegistry purchase, List<CottonPurchaseItem> items, Map<String, dynamic> summary) {
    final totalWeight = items.fold(0.0, (sum, item) => sum + item.weight);
    final totalUnits = items.fold(0, (sum, item) => sum + item.units);
    final itemsTotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final grandTotal = itemsTotal + purchase.transportationCost;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt, color: Colors.white, size: 24),
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
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            DateFormat('dd.MM.yyyy').format(purchase.purchaseDate),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cotton Types Header
                      Row(
                        children: [
                          Icon(Icons.inventory_2, color: Colors.grey[700], size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Маълумоти вазн',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Summary Box
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
                                  'Донаҳо',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$totalUnits шт',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            Container(height: 30, width: 1, color: Colors.grey[300]),
                            Column(
                              children: [
                                Text(
                                  'Вазни як дона',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(totalWeight / totalUnits).toStringAsFixed(1)} кг',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            Container(height: 30, width: 1, color: Colors.grey[300]),
                            Column(
                              children: [
                                Text(
                                  'Ҳамагӣ вазн',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${totalWeight.toStringAsFixed(0)} кг',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Each Cotton Type
                      const Text(
                        'Навъҳои пахта: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      ...items.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getCottonTypeColor(item.cottonType).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getCottonTypeColor(item.cottonType).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _getCottonTypeColor(item.cottonType),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.cottonTypeDisplay,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Вазн:', style: TextStyle(color: Colors.grey[600])),
                                Text('${item.weight.toStringAsFixed(1)} кг'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Нархи 1 кг:', style: TextStyle(color: Colors.grey[600])),
                                Text('${item.pricePerKg.toStringAsFixed(0)} с'),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Ҳамагӣ:', style: TextStyle(fontWeight: FontWeight.w500)),
                                Text(
                                  '${item.totalPrice.toStringAsFixed(0)} с',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getCottonTypeColor(item.cottonType),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),

                      // Transportation Cost
                      if (purchase.transportationCost > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.local_shipping, color: Colors.orange, size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Хароҷоти нақлиёт:'),
                                ],
                              ),
                              Text(
                                '${purchase.transportationCost.toStringAsFixed(0)} с',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Grand Total
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ҳамагӣ харч:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${grandTotal.toStringAsFixed(0)} с',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Close Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Пӯшонидан'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

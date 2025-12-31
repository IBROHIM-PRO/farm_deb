import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cotton_registry_provider.dart';
import '../../models/cotton_purchase_registry.dart';
import '../../models/cotton_purchase_item.dart';
import 'add_cotton_purchase_screen.dart';
import 'supplier_purchase_history_screen.dart';

class CottonPurchaseRegistryScreen extends StatefulWidget {
  const CottonPurchaseRegistryScreen({super.key});

  @override
  State<CottonPurchaseRegistryScreen> createState() => _CottonPurchaseRegistryScreenState();
}

class _CottonPurchaseRegistryScreenState extends State<CottonPurchaseRegistryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Хариди пахта'),
        actions: [
          IconButton(
            onPressed: _showStatistics,
            icon: const Icon(Icons.analytics),
          ),          
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCottonPurchaseScreen()),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Consumer<CottonRegistryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredPurchases = _getFilteredPurchases(provider.purchaseRegistry);          
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Ҷустуҷӯи таъминкунанда...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  } 

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPurchaseList(CottonRegistryProvider provider, List<CottonPurchaseRegistry> purchases) {
    // Group purchases by supplier name
    final groupedPurchases = <String, List<CottonPurchaseRegistry>>{};
    for (final purchase in purchases) {
      groupedPurchases.putIfAbsent(purchase.supplierName, () => []).add(purchase);
    }

    final supplierNames = groupedPurchases.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: supplierNames.length,
      itemBuilder: (context, index) {
        final supplierName = supplierNames[index];
        final supplierPurchases = groupedPurchases[supplierName]!;
        return _buildSupplierCard(provider, supplierName, supplierPurchases);
      },
    );
  }

  Widget _buildSupplierCard(CottonRegistryProvider provider, String supplierName, List<CottonPurchaseRegistry> purchases) {
    // Calculate totals for this supplier
    double totalAmount = 0.0;
    double totalWeight = 0.0;
    int totalUnits = 0;
    final latestDate = purchases.map((p) => p.purchaseDate).reduce((a, b) => a.isAfter(b) ? a : b);
    
    for (final purchase in purchases) {
      final items = provider.getItemsForPurchase(purchase.id!);
      final itemsTotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
      totalAmount += itemsTotal + purchase.transportationCost;
      totalWeight += items.fold(0.0, (sum, item) => sum + item.weight);
      totalUnits += items.fold(0, (sum, item) => sum + item.units);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToSupplierHistory(supplierName),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.person, color: Colors.green, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplierName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Охирин харид: ${DateFormat('dd/MM/yyyy').format(latestDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${purchases.length} харид',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    Column(
                      children: [
                        Text(
                          '$totalUnits',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'шт',
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
                          '${totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'с',
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
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSupplierHistory(String supplierName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierPurchaseHistoryScreen(
          supplierName: supplierName,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Ҳеҷ хариданӣ сабт нашудааст', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Барои сабти харид тугмаи плюсро пахш кунед',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  List<CottonPurchaseRegistry> _getFilteredPurchases(List<CottonPurchaseRegistry> purchases) {
    return purchases.where((purchase) {
      if (_searchQuery.isNotEmpty) {
        return purchase.supplierName.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();
  }

  void _showStatistics() {
    final provider = context.read<CottonRegistryProvider>();
    final stats = provider.overallStatistics;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Омори харид'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('Ҳамагӣ хариданӣ:', '${stats['totalPurchases']}'),
              _buildStatRow('Ҳамагӣ коркард:', '${stats['totalProcessed']}'),
              _buildStatRow('Ҳамагӣ фуруш:', '${stats['totalSales']}'),
              const Divider(),
              _buildStatRow('Ҳамагӣ харидор:', '${(stats['totalPurchaseCost'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'} сомонӣ'),
              _buildStatRow('Ҳамагӣ фуруш:', '${(stats['totalSalesRevenue'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'} сомонӣ'),
              const Divider(),
              _buildStatRow(
                'Ҳамагӣ фоида:',
                '${(stats['totalProfit'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'} сомонӣ',
                color: ((stats['totalProfit'] as num?)?.toDouble() ?? 0) >= 0 ? Colors.green : Colors.red,
              ),
              _buildStatRow('Самаранокӣ:', '${(stats['processingEfficiency'] as num?)?.toDouble()?.toStringAsFixed(1) ?? '0.0'}%'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Пӯшидан')),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  /// Transfer all existing purchases to warehouse
  void _transferToWarehouse() async {
    final provider = Provider.of<CottonRegistryProvider>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Гузоштан ба анбор'),
        content: const Text('Ҳамаи харидҳои мавҷударо ба анбор гузошт? Ин амал ҳамаи пахтаи харидшударо ба инвентари анбор илова мекунад.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Бекор кардан'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text('Гузориш ба анбор...'),
                    ],
                  ),
                ),
              );
              
              try {
                await provider.transferAllExistingPurchasesToWarehouse();
                if (mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Ҳамаи харидҳо бо муваффақият ба анбор гузошта шуданд'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚠️ ${e.toString().replaceAll('Exception: ', '')}'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            child: const Text('Гузоштан'),
          ),
        ],
      ),
    );
  }
}

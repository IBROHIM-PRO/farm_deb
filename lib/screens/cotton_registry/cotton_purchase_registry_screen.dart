import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cotton_registry_provider.dart';
import '../../models/cotton_purchase_registry.dart';
import '../../models/cotton_purchase_item.dart';
import '../../theme/app_theme.dart';
import 'add_cotton_purchase_screen.dart';
import 'cotton_purchase_detail_screen.dart';

/// Cotton Purchase Registry Screen - Master purchase records
/// Shows cotton purchase transactions with multiple cotton types per purchase
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
        title: const Text('Харидани пахта'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showStatistics,
            icon: const Icon(Icons.analytics),
            tooltip: 'Омор',
          ),
        ],
      ),
      body: Consumer<CottonRegistryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredPurchases = _getFilteredPurchases(provider.purchaseRegistry);

          return filteredPurchases.isEmpty
              ? _buildEmptyState(context)
              : _buildPurchaseList(context, provider, filteredPurchases);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "cotton_purchase_fab",
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddCottonPurchaseScreen(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Харидании нав'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildSearchAndSummary(
    BuildContext context,
    CottonRegistryProvider provider,
    List<CottonPurchaseRegistry> purchases,
  ) {
    final stats = provider.overallStatistics;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Ҷустуҷӯи таъминкунанда...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Ҳамагӣ хариданӣ',
                  '${stats['totalPurchases']}',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Ҳамагӣ харч',
                  '${(stats['totalPurchaseCost'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'} сомонӣ',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseList(
    BuildContext context,
    CottonRegistryProvider provider,
    List<CottonPurchaseRegistry> purchases,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: purchases.length,
      itemBuilder: (context, index) {
        final purchase = purchases[index];
        final summary = provider.getPurchaseSummary(purchase.id!);
        return _buildPurchaseCard(context, purchase, summary);
      },
    );
  }

  Widget _buildPurchaseCard(
    BuildContext context,
    CottonPurchaseRegistry purchase,
    Map<String, dynamic> summary,
  ) {
    final items = summary['items'] as List<CottonPurchaseItem>;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CottonPurchaseDetailScreen(purchaseId: purchase.id!),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy', 'en_US').format(purchase.purchaseDate),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Cotton Types Summary
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: items.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getCottonTypeColor(item.cottonType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.cottonTypeDisplay,
                      style: TextStyle(
                        color: _getCottonTypeColor(item.cottonType),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 12),
              
              const Divider(height: 1),
              
              const SizedBox(height: 8),
              
              // Summary Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ҳамагӣ вазн:',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${(summary['totalWeight'] as num?)?.toDouble()?.toStringAsFixed(1) ?? '0.0'} кг',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ҳамагӣ донаҳо:',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${summary['totalUnits']} дона',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Ҳамагӣ нарх:',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${(summary['grandTotal'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'} сомонӣ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Transportation cost indicator
              if (purchase.transportationCost > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Интиқол: ${purchase.transportationCost.toStringAsFixed(0)} TJS',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Notes indicator
              if (purchase.notes != null && purchase.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.note, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          purchase.notes!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ҳеҷ хариданӣ сабт нашудааст',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Барои сабти харидании пахта тугмаи зеринро пахш кунед',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddCottonPurchaseScreen(),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Харидании нав'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<CottonPurchaseRegistry> _getFilteredPurchases(List<CottonPurchaseRegistry> purchases) {
    return purchases.where((purchase) {
      if (_searchQuery.isNotEmpty) {
        if (!purchase.supplierName.toLowerCase().contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();
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

  void _showStatistics() {
    final provider = context.read<CottonRegistryProvider>();
    final stats = provider.overallStatistics;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Омори харидании пахта'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Пӯшидан'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

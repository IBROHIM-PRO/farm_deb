import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cotton_registry_provider.dart';
import '../../models/cotton_purchase_registry.dart';
import '../../models/cotton_purchase_item.dart';
import 'add_cotton_purchase_screen.dart';
import 'cotton_purchase_detail_screen.dart';

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
        actions: [
          IconButton(
            onPressed: _showStatistics,
            icon: const Icon(Icons.analytics),
            tooltip: 'Омор',
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCottonPurchaseScreen()),
            ),
            icon: const Icon(Icons.add),
            tooltip: 'Харидании нав',
          ),
        ],
      ),
      body: Consumer<CottonRegistryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredPurchases = _getFilteredPurchases(provider.purchaseRegistry);

          return Column(
            children: [
              _buildSearchBar(),
              _buildSummaryCards(provider),
              const Divider(),
              Expanded(
                child: filteredPurchases.isEmpty
                    ? _buildEmptyState()
                    : _buildPurchaseList(provider, filteredPurchases),
              ),
            ],
          );
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

  Widget _buildSummaryCards(CottonRegistryProvider provider) {
    final stats = provider.overallStatistics;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Ҳамагӣ хариданӣ',
              '${stats['totalPurchases']}',
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Ҳамагӣ харч',
              '${(stats['totalPurchaseCost'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'} сомонӣ',
              Colors.green,
            ),
          ),
        ],
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: purchases.length,
      itemBuilder: (context, index) {
        final purchase = purchases[index];
        final summary = provider.getPurchaseSummary(purchase.id!);
        return _buildPurchaseCard(purchase, summary);
      },
    );
  }

  Widget _buildPurchaseCard(CottonPurchaseRegistry purchase, Map<String, dynamic> summary) {
    final items = summary['items'] as List<CottonPurchaseItem>;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CottonPurchaseDetailScreen(purchaseId: purchase.id!)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(purchase.purchaseDate),
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),

              // Cotton types as chips
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: items.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              const SizedBox(height: 8),

              // Summary row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSmallInfo('Вазн', '${(summary['totalWeight'] as num?)?.toDouble()?.toStringAsFixed(1) ?? '0.0'} кг'),
                  _buildSmallInfo('Донаҳо', '${summary['totalUnits']} дона'),
                  _buildSmallInfo('Нарх', '${(summary['grandTotal'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'} сомонӣ', color: Colors.green),
                ],
              ),

              // Transportation cost
              if (purchase.transportationCost > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('Интиқол: ${purchase.transportationCost.toStringAsFixed(0)} TJS',
                          style: const TextStyle(fontSize: 11, color: Colors.orange)),
                    ],
                  ),
                ),

              // Notes
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
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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

  Widget _buildSmallInfo(String label, String value, {Color color = Colors.grey}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
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
          Text('Барои сабти харидании пахта тугмаи плюсро пахш кунед',
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Пӯшидан')),
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
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

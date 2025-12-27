import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cotton_registry_provider.dart';
import '../../models/cotton_purchase_registry.dart';
import '../../models/cotton_purchase_item.dart';
import 'add_cotton_purchase_screen.dart';

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
          ),
          IconButton(
            onPressed: _transferToWarehouse,
            icon: const Icon(Icons.warehouse),
            tooltip: 'Гузоштан ба анбор',
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showFullPurchaseDetails(purchase, summary),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Сана: ${DateFormat('dd/MM/yyyy').format(purchase.purchaseDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Таъминикунанда: ${purchase.supplierName}'),
              const SizedBox(height: 4),
              Text('Ҳамагӣ нарх: ${(summary['grandTotal'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'} сомонӣ',
                  style: const TextStyle(color: Colors.green)),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullPurchaseDetails(CottonPurchaseRegistry purchase, Map<String, dynamic> summary) {
    final items = summary['items'] as List<CottonPurchaseItem>;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Маълумоти пурраи харид', textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Сана: ${DateFormat('dd/MM/yyyy').format(purchase.purchaseDate)}'),
              const SizedBox(height: 8),
              Text('Таъминикунанда: ${purchase.supplierName}'),
              const SizedBox(height: 8),
              Text('Нархҳо ва миқдорҳо:', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                        '${item.cottonTypeDisplay}: ${item.weight.toStringAsFixed(1)} кг, ${item.units} дона, ${item.totalPrice.toStringAsFixed(0)} сомонӣ'),
                  )),
              const SizedBox(height: 8),
              Text('Ҳамагӣ вазн: ${(summary['totalWeight'] as num?)?.toDouble()?.toStringAsFixed(1) ?? '0.0'} кг'),
              Text('Ҳамагӣ донаҳо: ${summary['totalUnits']}'),
              Text('Ҳамагӣ нарх: ${(summary['grandTotal'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'} сомонӣ'),
              if (purchase.transportationCost > 0)
                Text('Интиқол: ${purchase.transportationCost.toStringAsFixed(0)} TJS'),
              if (purchase.notes != null && purchase.notes!.isNotEmpty)
                Text('Эзоҳ: ${purchase.notes!}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Пӯшидан')),
        ],
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cotton_registry_provider.dart';
import '../../models/cotton_purchase_registry.dart';
import '../../models/cotton_purchase_item.dart';

/// Cotton Purchase Detail Screen - Shows detailed view of a purchase transaction
/// Displays all cotton types purchased in one transaction with full summary
class CottonPurchaseDetailScreen extends StatefulWidget {
  final int purchaseId;

  const CottonPurchaseDetailScreen({
    super.key,
    required this.purchaseId,
  });

  @override
  State<CottonPurchaseDetailScreen> createState() => _CottonPurchaseDetailScreenState();
}

class _CottonPurchaseDetailScreenState extends State<CottonPurchaseDetailScreen> {
  CottonPurchaseRegistry? purchase;
  List<CottonPurchaseItem> items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchaseDetails();
  }

  Future<void> _loadPurchaseDetails() async {
    final provider = context.read<CottonRegistryProvider>();
    
    // Find purchase in provider data
    final foundPurchase = provider.purchaseRegistry
        .where((p) => p.id == widget.purchaseId)
        .firstOrNull;
    
    if (foundPurchase != null) {
      final summary = provider.getPurchaseSummary(widget.purchaseId);
      setState(() {
        purchase = foundPurchase;
        items = summary['items'] as List<CottonPurchaseItem>;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тафсилоти харидан'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showPurchaseSummary,
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Ҳисобот',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : purchase == null
              ? _buildNotFoundState()
              : _buildPurchaseDetail(),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Харидан ёфт нашуд',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Бозгашт'),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseDetail() {
    final totalWeight = items.fold(0.0, (sum, item) => sum + item.weight);
    final totalUnits = items.fold(0, (sum, item) => sum + item.units);
    final totalPrice = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final grandTotal = totalPrice + purchase!.transportationCost;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Purchase Header
          _buildPurchaseHeader(),
          
          const SizedBox(height: 24),
          
          // Cotton Items
          _buildSectionTitle('Навъҳои пахта'),
          const SizedBox(height: 12),
          ...items.map((item) => _buildCottonItemCard(item)),
          
          const SizedBox(height: 24),
          
          // Summary
          _buildSectionTitle('Хулосаи умумӣ'),
          const SizedBox(height: 12),
          _buildSummaryCard(totalWeight, totalUnits, totalPrice, grandTotal),
          
          const SizedBox(height: 24),
          
          // Notes section
          if (purchase!.notes != null && purchase!.notes!.isNotEmpty) ...[
            _buildSectionTitle('Қайдҳо'),
            const SizedBox(height: 12),
            _buildNotesCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildPurchaseHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy', 'en_US').format(purchase!.purchaseDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Таъминкунанда:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        purchase!.supplierName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCottonItemCard(CottonPurchaseItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getCottonTypeColor(item.cottonType),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.cottonTypeDisplay,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  item.totalPriceDisplay,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn('Вазн', item.weightDisplay),
                ),
                Expanded(
                  child: _buildInfoColumn('Донаҳо', item.unitsDisplay),
                ),
                Expanded(
                  child: _buildInfoColumn('Нарх/кг', item.priceDisplay),
                ),
              ],
            ),
            
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.note, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(double totalWeight, int totalUnits, double totalPrice, double grandTotal) {
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildSummaryItem('Ҳамагӣ вазн', '${totalWeight.toStringAsFixed(1)} кг')),
                Expanded(child: _buildSummaryItem('Ҳамагӣ донаҳо', '$totalUnits дона')),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildSummaryItem('Нархи пахта', '${totalPrice.toStringAsFixed(2)} TJS')),
                if (purchase!.transportationCost > 0)
                  Expanded(child: _buildSummaryItem('Интиқол', '${purchase!.transportationCost.toStringAsFixed(2)} TJS')),
              ],
            ),
            
            const Divider(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ҲАМАГӢ:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${grandTotal.toStringAsFixed(2)} TJS',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.note, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                purchase!.notes!,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCottonTypeColor(CottonType type) {
    switch (type) {
      case CottonType.lint: return Colors.green;
      case CottonType.uluk: return Colors.blue;
      case CottonType.valakno: return Colors.orange;
    }
  }

  void _showPurchaseSummary() {
    final totalWeight = items.fold(0.0, (sum, item) => sum + item.weight);
    final totalUnits = items.fold(0, (sum, item) => sum + item.units);
    final totalPrice = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final grandTotal = totalPrice + purchase!.transportationCost;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ҳисоботи харидан'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Сана: ${DateFormat('dd/MM/yyyy', 'en_US').format(purchase!.purchaseDate)}'),
              Text('Таъминкунанда: ${purchase!.supplierName}'),
              const Divider(),
              Text('Навъҳои пахта: ${items.length}'),
              Text('Ҳамагӣ вазн: ${totalWeight.toStringAsFixed(1)} кг'),
              Text('Ҳамагӣ донаҳо: $totalUnits дона'),
              const Divider(),
              Text('Нархи пахта: ${totalPrice.toStringAsFixed(2)} TJS'),
              if (purchase!.transportationCost > 0)
                Text('Интиқол: ${purchase!.transportationCost.toStringAsFixed(2)} TJS'),
              const Divider(),
              Text(
                'ҲАМАГӢ: ${grandTotal.toStringAsFixed(2)} TJS',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
}

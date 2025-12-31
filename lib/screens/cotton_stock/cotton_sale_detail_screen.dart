import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cotton_stock_sale.dart';
import '../../models/buyer.dart';
import '../../database/database_helper.dart';

class CottonSaleDetailScreen extends StatefulWidget {
  final List<CottonStockSale> sales;

  const CottonSaleDetailScreen({
    super.key,
    required this.sales,
  });

  @override
  State<CottonSaleDetailScreen> createState() => _CottonSaleDetailScreenState();
}

class _CottonSaleDetailScreenState extends State<CottonSaleDetailScreen> {
  Buyer? buyer;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBuyerInfo();
  }

  Future<void> _loadBuyerInfo() async {
    try {
      if (widget.sales.isNotEmpty) {
        final buyerData = await DatabaseHelper.instance.getBuyerById(widget.sales.first.buyerId);
        setState(() {
          buyer = buyerData;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Маълумоти фурӯш'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [                                    
                  // Sale Date Card
                  _buildInfoCard(
                    'Санаи фурӯш',
                    DateFormat('dd.MM.yyyy').format(widget.sales.first.saleDate),
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  
                  // All Sales List
                  ...widget.sales.asMap().entries.map((entry) {
                    final index = entry.key;
                    final sale = entry.value;
                    return Column(
                      children: [
                        _buildSaleItemCard(sale, index + 1),
                        const SizedBox(height: 12),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }  
  
  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleItemCard(CottonStockSale sale, int itemNumber) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Дастаи фурӯш $itemNumber',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow('Донаҳо', '${sale.units} дона'),
            const SizedBox(height: 12),
            _buildDetailRow('Вазни як дона', '${sale.unitWeight.toStringAsFixed(1)} кг'),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Ҳамагӣ вазн',
              '${sale.totalWeight.toStringAsFixed(1)} кг',
              isHighlighted: true,
            ),
            if (sale.totalAmount != null) ..[
              const SizedBox(height: 12),
              _buildDetailRow(
                'Ҳамагӣ маблағ',
                '${sale.totalAmount!.toStringAsFixed(0)} с',
                isHighlighted: true,
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isHighlighted ? Colors.black87 : Colors.grey[700],
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 16 : 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            color: isHighlighted ? Colors.orange : Colors.black87,
          ),
        ),
      ],
    );
  }
}

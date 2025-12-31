import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cotton_stock_sale.dart';
import '../../models/buyer.dart';
import '../../database/database_helper.dart';
import 'cotton_sale_detail_screen.dart';

class BuyerCottonSalesDetailScreen extends StatefulWidget {
  final String buyerName;
  final int buyerId;

  const BuyerCottonSalesDetailScreen({
    super.key,
    required this.buyerName,
    required this.buyerId,
  });

  @override
  State<BuyerCottonSalesDetailScreen> createState() => _BuyerCottonSalesDetailScreenState();
}

class _BuyerCottonSalesDetailScreenState extends State<BuyerCottonSalesDetailScreen> {
  List<CottonStockSale> sales = [];
  Buyer? buyer;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      final salesData = await DatabaseHelper.instance.getCottonStockSalesByBuyer(widget.buyerId);
      final buyerData = await DatabaseHelper.instance.getBuyerById(widget.buyerId);
      
      setState(() {
        sales = salesData;
        buyer = buyerData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хатогӣ: $e')),
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
            const Text('Фурӯши пахта', style: TextStyle(fontSize: 18)),
            Text(
              widget.buyerName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sales.isEmpty
              ? _buildEmptyState()
              : _buildSalesList(),
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
            'Ҳеҷ фурӯш ёфт нашуд',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesList() {
    final totalWeight = sales.fold<double>(0, (sum, sale) => sum + sale.totalWeight);
    final totalPieces = sales.fold<int>(0, (sum, sale) => sum + sale.units);
    final totalAmount = sales.fold<double>(0, (sum, sale) => sum + (sale.totalAmount ?? 0));

    return Column(
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person, color: Colors.blue, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.buyerName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (buyer?.phone != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    buyer!.phone!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Ҳамагӣ фурӯш',
                          '${sales.length}',
                          Icons.shopping_cart,
                          Colors.blue,
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Донаҳо',
                          '$totalPieces шт',
                          Icons.inventory_2,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Вазн',
                          '${totalWeight.toStringAsFixed(1)} кг',
                          Icons.scale,
                          Colors.purple,
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Маблағ',
                          '${totalAmount.toStringAsFixed(0)} с',
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Sales List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _buildGroupedSales(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGroupedSales() {
    // Group sales by date
    final Map<String, List<CottonStockSale>> groupedSales = {};
    
    for (var sale in sales) {
      final dateKey = DateFormat('dd.MM.yyyy').format(sale.saleDate);
      if (!groupedSales.containsKey(dateKey)) {
        groupedSales[dateKey] = [];
      }
      groupedSales[dateKey]!.add(sale);
    }
    
    // Build widgets for each date group
    final List<Widget> widgets = [];
    groupedSales.forEach((dateKey, salesList) {
      widgets.add(_buildDateGroup(dateKey, salesList));
      widgets.add(const SizedBox(height: 16));
    });
    
    return widgets;
  }

  Widget _buildDateGroup(String dateKey, List<CottonStockSale> salesList) {
    final totalWeight = salesList.fold<double>(0, (sum, sale) => sum + sale.totalWeight);
    final totalPieces = salesList.fold<int>(0, (sum, sale) => sum + sale.units);
    final totalAmount = salesList.fold<double>(0, (sum, sale) => sum + (sale.totalAmount ?? 0));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[500]!],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateKey,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${salesList.length} фурӯш',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$totalPieces дона',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${totalWeight.toStringAsFixed(1)} кг',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Sales in this date group
        ...salesList.map((sale) => _buildSaleCard(sale)),
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
            fontSize: 16,
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

  Widget _buildSaleCard(CottonStockSale sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CottonSaleDetailScreen(sale: sale),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sale.units} дона × ${sale.unitWeight.toStringAsFixed(1)} кг',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sale.totalWeight.toStringAsFixed(1)} кг',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (sale.totalAmount != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${sale.totalAmount!.toStringAsFixed(0)} с',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cotton_stock_sale.dart';
import '../../models/buyer.dart';
import '../../database/database_helper.dart';

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

  void _showSalesDetailsModal(List<CottonStockSale> salesList) {
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
                              DateFormat('dd.MM.yyyy').format(salesList.first.saleDate),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Тафсилоти фурӯш',
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
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: Colors.grey[300], height: 1),
                ),
                
                // Summary card
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildModalSummaryCard(salesList),
                ),
                
                // Title for details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.list, color: Colors.blue, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Тафсилоти дастаҳо (${salesList.first.pricePerKg != null ? salesList.first.pricePerKg!.toStringAsFixed(2) : "0"} с/кг)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Sales details list
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      ...salesList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final sale = entry.value;
                        
                        return _buildModalSaleItem(sale, index);
                      }).toList(),
                      
                      const SizedBox(height: 30), // Bottom padding
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

  Widget _buildModalSummaryCard(List<CottonStockSale> salesList) {
    final totalWeight = salesList.fold<double>(0, (sum, sale) => sum + sale.totalWeight);
    final totalPieces = salesList.fold<int>(0, (sum, sale) => sum + sale.units);
    final totalFreightCost = salesList.fold<double>(0, (sum, sale) => sum + sale.freightCost);
    final cottonAmount = salesList.fold<double>(0, (sum, sale) => sum + (sale.totalAmount ?? 0));
    final totalAmount = cottonAmount;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Summary title          
          
          const SizedBox(height: 16),
          
          // Summary stats in row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryStat('Донаҳо', '$totalPieces', Icons.format_list_numbered, Colors.blue),
              _buildSummaryStat('Вазн', '${totalWeight.toStringAsFixed(1)} кг', Icons.scale, Colors.green),
              if (totalAmount > 0)
                _buildSummaryStat('Маблағ', '${totalAmount.toStringAsFixed(2)} с', Icons.attach_money, Colors.orange),
            ],
          ),
          
          // Show freight cost if exists
          if (totalFreightCost > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_shipping, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Хароҷоти грузчик',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${totalFreightCost.toStringAsFixed(2)} с',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [        
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildModalSaleItem(CottonStockSale sale, int index) {
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
            '${sale.unitWeight.toStringAsFixed(1)} кг',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),                    
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Донаҳо:',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${sale.units} дона',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Вазни умумӣ:',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${sale.totalWeight.toStringAsFixed(1)} кг',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (sale.totalAmount != null && sale.totalAmount! > 0) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Маблағ:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${sale.totalAmount!.toStringAsFixed(2)} с',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],          
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.buyerName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (!isLoading)
              Text(
                '${sales.length} фурӯш',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
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
    // Calculate overall totals
    final totalWeight = sales.fold<double>(0, (sum, sale) => sum + sale.totalWeight);
    final totalPieces = sales.fold<int>(0, (sum, sale) => sum + sale.units);

    return Column(
      children: [              
        // Sales List by Date - Like second image design
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
    
    // Sort dates in descending order (newest first)
    final sortedDates = groupedSales.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    for (var dateKey in sortedDates) {
      final salesList = groupedSales[dateKey]!;
      widgets.add(_buildDateGroup(dateKey, salesList));
      widgets.add(const SizedBox(height: 12));
    }
    
    return widgets;
  }

  Widget _buildDateGroup(String dateKey, List<CottonStockSale> salesList) {
    final totalWeight = salesList.fold<double>(0, (sum, sale) => sum + sale.totalWeight);
    final totalPieces = salesList.fold<int>(0, (sum, sale) => sum + sale.units);
    
    return GestureDetector(
      onTap: () => _showSalesDetailsModal(salesList),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and status indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Status indicator like in second image
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        dateKey,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${salesList.length} фурӯш',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Details row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side - Pieces
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.format_list_numbered, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            '$totalPieces дона',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Донаҳо',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  // Right side - Weight
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.scale, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            '${totalWeight.toStringAsFixed(1)} кг',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Вазн',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Arrow indicator at bottom
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
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
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/cotton_sale.dart';

/// Buyer Cotton History Screen
/// Shows all cotton sales for a specific buyer with full purchase information
class BuyerCottonHistoryScreen extends StatefulWidget {
  final String buyerName;

  const BuyerCottonHistoryScreen({
    super.key,
    required this.buyerName,
  });

  @override
  State<BuyerCottonHistoryScreen> createState() => _BuyerCottonHistoryScreenState();
}

class _BuyerCottonHistoryScreenState extends State<BuyerCottonHistoryScreen> {
  List<CottonSale> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBuyerSales();
  }

  Future<void> _loadBuyerSales() async {
    setState(() => _isLoading = true);
    
    try {
      final sales = await context.read<AppProvider>().getCottonSalesByBuyer(widget.buyerName);
      setState(() {
        _sales = sales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Хатогии боркунии маълумот: $e'),
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
            const Text('Таърихи фурӯши пахта', style: TextStyle(fontSize: 18)),
            Text(
              widget.buyerName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sales.isEmpty
              ? _buildEmptyState()
              : _buildSalesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.point_of_sale_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Фурӯш ёфт нашуд',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Барои ин харидор фурӯши пахта сабт нашудааст',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSalesList() {
    // Calculate totals
    final totalSales = _sales.length;
    final totalAmount = _sales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
    final totalPaid = _sales.fold(0.0, (sum, sale) => sum + sale.paidAmount);
    final totalRemaining = totalAmount - totalPaid;
    final totalWeight = _sales.fold(0.0, (sum, sale) => sum + (sale.weight ?? 0.0));
    final totalUnits = _sales.fold(0, (sum, sale) => sum + (sale.units ?? 0));

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
                      Icon(Icons.person, color: Colors.green, size: 28),
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
                            Text(
                              'Харидори пахта',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
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
                          'Ҷамъи фурӯш',
                          '$totalSales',
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
                          'Ҳамагӣ',
                          '${totalAmount.toStringAsFixed(2)} с',
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Вазни умумӣ',
                          '${totalWeight.toStringAsFixed(1)} kg',
                          Icons.scale,
                          Colors.orange,
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Шумораи умумии воҳидҳо',
                          '$totalUnits шт',
                          Icons.inventory,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  if (totalRemaining > 0) ...[
                    const Divider(height: 32),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Пардохти пардохтнашуда',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${totalRemaining.toStringAsFixed(2)} с боқимонда',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Sales List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadBuyerSales,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _sales.length,
              itemBuilder: (context, index) {
                final sale = _sales[index];
                return _buildSaleCard(sale);
              },
            ),
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

  Widget _buildSaleCard(CottonSale sale) {
    final statusColor = sale.paymentStatus == PaymentStatus.paid 
        ? Colors.green 
        : sale.paymentStatus == PaymentStatus.partial 
            ? Colors.orange 
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sale Header
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
                      child: Icon(Icons.point_of_sale, color: Colors.green, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Фурӯш #${sale.id ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('dd.MM.yyyy').format(sale.date),
                          style: TextStyle(
                            fontSize: 14,
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sale.paymentStatus.name[0].toUpperCase() + sale.paymentStatus.name.substring(1),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Sale Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Типи фурӯш:',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        sale.saleType == SaleType.byWeight ? 'Аз рӯи вазн': 'Аз рӯи воҳидҳо',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Миқдор:',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        sale.saleType == SaleType.byWeight 
                            ? '${sale.weight?.toStringAsFixed(1)} кг'
                            : '${sale.units} в.',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Нарх барои як воҳид:',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${sale.pricePerUnit.toStringAsFixed(2)} ${sale.currency}/${sale.saleType == SaleType.byWeight ? 'кг' : 'в.'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ҳамагӣ:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${sale.totalAmount.toStringAsFixed(2)} ${sale.currency}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (sale.paymentStatus != PaymentStatus.paid) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Маблағи пардохтшуда:',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          '${sale.paidAmount.toStringAsFixed(2)} ${sale.currency}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Боқимонда:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${sale.remainingAmount.toStringAsFixed(2)} ${sale.currency}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Progress Bar (if not fully paid)
            if (sale.paymentStatus != PaymentStatus.paid && sale.totalAmount > 0) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: sale.paidAmount / sale.totalAmount,
                backgroundColor: statusColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
              const SizedBox(height: 4),
              Text(
                'Пайдашуда: ${((sale.paidAmount / sale.totalAmount) * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],

            // Notes (if any)
            if (sale.notes != null && sale.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sale.notes!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/cotton_stock_sale.dart';
import '../../models/buyer.dart';
import '../../database/database_helper.dart';
import '../../providers/cotton_warehouse_provider.dart';
import '../../providers/settings_provider.dart';

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
    // Calculate totals
    final totalPieces = widget.sales.fold<int>(0, (sum, sale) => sum + sale.units);
    final totalWeight = widget.sales.fold<double>(0, (sum, sale) => sum + sale.totalWeight);
    final totalAmount = widget.sales.fold<double>(
      0, 
      (sum, sale) => sum + (sale.totalAmount ?? 0)
    );
    final totalFreightCost = widget.sales.fold<double>(0, (sum, sale) => sum + sale.freightCost);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Маълумоти фурӯш'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Харидор карт
                  _buildBuyerCard(),
                  const SizedBox(height: 16),
                  
                  // Санаи фурӯш карт
                  _buildDateCard(),
                  const SizedBox(height: 16),
                  
                  // Ҷамъбасти умумӣ карт
                  _buildSummaryCard(totalPieces, totalWeight, totalAmount, totalFreightCost),
                  const SizedBox(height: 24),
                  
                  // Дастаҳои фурӯш (агар якчанд бошад)
                  if (widget.sales.length > 1) ...[
                    _buildSalesListCard(),
                    const SizedBox(height: 16),
                  ],
                  
                  // Ҷадвали муфассал
                  _buildDetailsTable(),
                  
                  // Edit/Delete Buttons (conditionally shown)
                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, _) {
                      if (!settingsProvider.editDeleteEnabled) {
                        return const SizedBox(height: 24);
                      }
                      return Column(
                        children: [
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Таҳрири фурӯш дар ин версия пурра дастгирӣ намешавад.'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Таҳрир'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final confirm = await _confirmDeleteSales(context);
                                    if (confirm == true && context.mounted) {
                                      try {
                                        for (final sale in widget.sales) {
                                          await DatabaseHelper.instance.deleteCottonStockSale(sale.id!);
                                        }
                                        
                                        // Refresh warehouse data after deletion
                                        if (context.mounted) {
                                          await context.read<CottonWarehouseProvider>().loadAllData();
                                          
                                          Navigator.pop(context, true); // Pass true to indicate deletion occurred
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Фурӯш бомуваффақият нест карда шуд'),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Хато: ${e.toString()}')),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Нест кардан'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
  
  Future<bool?> _confirmDeleteSales(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Тасдиқ кунед'),
        content: Text('Шумо мутмаин ҳастед, ки мехоҳед ин ${widget.sales.length} фурӯшро нест кунед? Ин амал бозгашт карда намешавад.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Бекор кардан'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Нест кардан'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBuyerCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.blue,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Номи харидор',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    buyer?.name ?? 'Номаълум',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Шумораи фурӯш: ${widget.sales.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDateCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Colors.green,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Санаи фурӯш',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd.MM.yyyy').format(widget.sales.first.saleDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE', 'tg').format(widget.sales.first.saleDate),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard(int totalPieces, double totalWeight, double totalAmount, double totalFreightCost) {
    final cottonAmount = totalAmount - totalFreightCost;
    final grandTotal = totalAmount;
    return Card(
      elevation: 2,
      color: Colors.teal.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.summarize, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Ҷамъбасти фурӯш',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Ҷадвали ҷамъбаст
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    _buildSummaryCell('Ҷамъи донаҳо:', isLabel: true),
                    _buildSummaryCell('$totalPieces дона', isValue: true),
                  ],
                ),
                TableRow(
                  children: [
                    Container(height: 12), // Spacer
                    Container(height: 12),
                  ],
                ),
                TableRow(
                  children: [
                    _buildSummaryCell('Ҷамъи вазн:', isLabel: true),
                    _buildSummaryCell('${totalWeight.toStringAsFixed(1)} кг', isValue: true),
                  ],
                ),
              ],
            ),
            
            // Маблағ агар мавҷуд бошад
            if (cottonAmount > 0) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 16),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    children: [
                      _buildSummaryCell('Нархи миёна 1 кг:', isLabel: true),
                      _buildSummaryCell(
                        '${_calculateAveragePrice().toStringAsFixed(2)} с',
                        isValue: true,
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Container(height: 8),
                      Container(height: 8),
                    ],
                  ),
                  TableRow(
                    children: [
                      _buildSummaryCell('Нархи пахта:', isLabel: true),
                      _buildSummaryCell(
                        '${cottonAmount.toStringAsFixed(2)} с',
                        isValue: true,
                      ),
                    ],
                  ),
                  if (totalFreightCost > 0) ...[
                    TableRow(
                      children: [
                        Container(height: 8),
                        Container(height: 8),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildSummaryCell('Хароҷоти грузчик:', isLabel: true),
                        _buildSummaryCell(
                          '${totalFreightCost.toStringAsFixed(2)} с',
                          isValue: true,
                        ),
                      ],
                    ),
                  ],
                  TableRow(
                    children: [
                      Container(height: 12),
                      Container(height: 12),
                    ],
                  ),
                  TableRow(
                    children: [
                      _buildSummaryCell('Ҷамъи маблағ:', isLabel: true, isBold: true),
                      _buildSummaryCell(
                        '${grandTotal.toStringAsFixed(2)} с',
                        isValue: true,
                        isBold: true,
                        isTotal: true,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryCell(String text, {
    bool isLabel = false,
    bool isValue = false,
    bool isBold = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isTotal ? 16 : 14,
          fontWeight: isBold || isTotal ? FontWeight.bold : FontWeight.normal,
          color: isTotal ? Colors.teal : 
                isValue ? Colors.black87 : Colors.grey[700],
        ),
      ),
    );
  }
  
  double _calculateAveragePrice() {
    if (widget.sales.isEmpty) return 0;
    
    final totalWeight = widget.sales.fold<double>(0, (sum, sale) => sum + sale.totalWeight);
    final totalAmount = widget.sales.fold<double>(0, (sum, sale) => sum + (sale.totalAmount ?? 0));
    
    if (totalWeight == 0) return 0;
    return totalAmount / totalWeight;
  }
  
  Widget _buildSalesListCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.list, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Дастаҳои фурӯш',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...widget.sales.asMap().entries.map((entry) {
              final index = entry.key;
              final sale = entry.value;
              final isLast = index == widget.sales.length - 1;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Дастаи ${index + 1}:',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${sale.units} дона × ${sale.unitWeight} кг',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ҳамагӣ вазн:', style: TextStyle(color: Colors.grey)),
                      Text(
                        '${sale.totalWeight.toStringAsFixed(1)} кг',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (sale.totalAmount != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Маблағ:', style: TextStyle(color: Colors.grey)),
                        Text(
                          '${sale.totalAmount!.toStringAsFixed(2)} с',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (sale.freightCost > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Хароҷоти грузчик:', style: TextStyle(color: Colors.grey)),
                        Text(
                          '${sale.freightCost.toStringAsFixed(2)} с',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!isLast) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailsTable() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.table_chart, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Ҷадвали муфассал',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Сарлавҳаи ҷадвал
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      '№',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Адад',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Вазни як дона',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Ҳамагӣ вазн',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Маълумотҳои ҷадвал
            ...widget.sales.asMap().entries.map((entry) {
              final index = entry.key;
              final sale = entry.value;
              final isEven = index % 2 == 0;
              
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isEven ? Colors.white : Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${index + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${sale.units}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${sale.unitWeight.toStringAsFixed(1)} кг',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${sale.totalWeight.toStringAsFixed(1)} кг',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
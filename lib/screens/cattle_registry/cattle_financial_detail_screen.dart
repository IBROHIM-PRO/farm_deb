import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cattle_registry_provider.dart';
import '../../providers/barn_provider.dart';
import '../../models/cattle_registry.dart';
import '../../models/cattle_purchase.dart';
import '../../models/cattle_expense.dart';
import '../../models/cattle_sale.dart';
import '../../models/cattle_weight.dart';
import '../../theme/app_theme.dart';
import 'cattle_weight_tracking_screen.dart';

class CattleFinancialDetailScreen extends StatefulWidget {
  final int cattleId;

  const CattleFinancialDetailScreen({super.key, required this.cattleId});

  @override
  State<CattleFinancialDetailScreen> createState() => _CattleFinancialDetailScreenState();
}

class _CattleFinancialDetailScreenState extends State<CattleFinancialDetailScreen> {
  bool _isLoading = true;
  CattleRegistry? cattle;
  CattlePurchase? purchase;
  List<CattleExpense> expenses = [];
  List<CattleWeight> weights = [];
  CattleSale? sale;
  double barnExpenseShare = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<CattleRegistryProvider>();
      
      await provider.loadAllData();

      setState(() {
        cattle = provider.getCattleById(widget.cattleId);
        purchase = provider.getCattlePurchases(widget.cattleId).isNotEmpty
            ? provider.getCattlePurchases(widget.cattleId).first
            : null;
        expenses = provider.getCattleExpenses(widget.cattleId);
        weights = provider.getCattleWeights(widget.cattleId);
        sale = provider.getCattleSales(widget.cattleId).isNotEmpty
            ? provider.getCattleSales(widget.cattleId).first
            : null;
        
        // Calculate barn expense share if cattle is in a barn
        if (cattle?.barnId != null) {
          _calculateBarnExpenseShare();
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хато: ${e.toString()}')),
        );
      }
    }
  }

  void _calculateBarnExpenseShare() {
    if (cattle?.barnId == null) return;
    
    final barnProvider = context.read<BarnProvider>();
    final barnSummary = barnProvider.getBarnSummary(cattle!.barnId!);
    final cattleCount = barnSummary['cattleCount'] as int;
    
    if (cattleCount > 0) {
      final totalBarnExpenses = barnSummary['totalExpenses'] as double;
      barnExpenseShare = totalBarnExpenses / cattleCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Тафсилоти молиявӣ'),
          backgroundColor: AppTheme.primaryIndigo,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (cattle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Хато')),
        body: const Center(child: Text('Чорво ёфт нашуд')),
      );
    }

    final totalCosts = _calculateTotalCosts();
    final revenue = sale?.totalAmount ?? 0;
    final profitLoss = revenue - totalCosts;

    return Scaffold(
      appBar: AppBar(
        title: Text('Тафсилот - ${cattle!.earTag}'),
        backgroundColor: AppTheme.primaryIndigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.monitor_weight),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CattleWeightTrackingScreen(
                  cattleId: widget.cattleId,
                  earTag: cattle!.earTag,
                ),
              ),
            ).then((_) => _loadData()),
            tooltip: 'Вазнкунӣ',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCattleInfoCard(),
            const SizedBox(height: 16),
            _buildFinancialSummaryCard(totalCosts, revenue, profitLoss),
            const SizedBox(height: 16),
            _buildPurchaseCard(),
            const SizedBox(height: 16),
            _buildExpensesCard(),
            const SizedBox(height: 16),
            _buildBarnExpenseCard(),
            const SizedBox(height: 16),
            _buildWeightHistoryCard(),
            if (sale != null) ...[
              const SizedBox(height: 16),
              _buildSaleCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCattleInfoCard() {
    final barn = cattle!.barnId != null
        ? context.read<BarnProvider>().getBarnById(cattle!.barnId!)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pets, color: AppTheme.primaryIndigo, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cattle!.earTag,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${cattle!.genderDisplay} • ${cattle!.ageCategoryDisplay}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cattle!.status == CattleStatus.active
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cattle!.statusDisplay,
                    style: TextStyle(
                      color: cattle!.status == CattleStatus.active ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (barn != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.home_work, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text('Ховар: ${barn.name}'),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('Бақайд: ${DateFormat('dd/MM/yyyy').format(cattle!.registrationDate)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryCard(double totalCosts, double revenue, double profitLoss) {
    final isProfitable = profitLoss >= 0;

    return Card(
      color: isProfitable ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isProfitable ? Icons.trending_up : Icons.trending_down,
                  color: isProfitable ? Colors.green : Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Хулосаи молиявӣ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFinancialRow('Ҳамагӣ хароҷот', '${totalCosts.toStringAsFixed(2)} сомонӣ', Colors.red),
            const SizedBox(height: 8),
            _buildFinancialRow('Даромад', '${revenue.toStringAsFixed(2)} сомонӣ', Colors.green),
            const Divider(height: 24),
            _buildFinancialRow(
              isProfitable ? 'Фоида' : 'Зарар',
              '${profitLoss.abs().toStringAsFixed(2)} сомонӣ',
              isProfitable ? Colors.green : Colors.red,
              isBold: true,
              isLarge: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, Color color,
      {bool isBold = false, bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseCard() {
    if (purchase == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.shopping_cart_outlined, color: Colors.grey[400]),
              const SizedBox(width: 12),
              const Text('Маълумоти харид бақайд нашудааст'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Маълумоти харид',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 16),
            _buildInfoRow('Вазн', '${purchase!.weightAtPurchase} кг'),
            if (purchase!.pricePerKg != null)
              _buildInfoRow('Нархи як кг', '${purchase!.pricePerKg!.toStringAsFixed(2)} ${purchase!.currency}'),
            if (purchase!.totalPrice != null)
              _buildInfoRow('Нархи умумӣ', '${purchase!.totalPrice!.toStringAsFixed(2)} ${purchase!.currency}'),
            if (purchase!.transportationCost > 0)
              _buildInfoRow('Хароҷоти нақлиёт', '${purchase!.transportationCost.toStringAsFixed(2)} ${purchase!.currency}'),
            _buildInfoRow('Санаи харид', DateFormat('dd/MM/yyyy').format(purchase!.purchaseDate)),
            if (purchase!.sellerName != null)
              _buildInfoRow('Фурӯшанда', purchase!.sellerName!),
            const Divider(height: 16),
            _buildInfoRow(
              'Ҷамъи хароҷот',
              '${purchase!.totalCost.toStringAsFixed(2)} ${purchase!.currency}',
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesCard() {
    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.cost);

    return Card(
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
                    Icon(Icons.receipt_long, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Хароҷоти шахсӣ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '${totalExpenses.toStringAsFixed(2)} сомонӣ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            if (expenses.isEmpty)
              const Text('Ҳеҷ хароҷот бақайд нашудааст', style: TextStyle(color: Colors.grey))
            else
              ...expenses.map((expense) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.itemName,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                expense.expenseTypeDisplay,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${expense.cost.toStringAsFixed(0)} сомонӣ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildBarnExpenseCard() {
    if (cattle?.barnId == null) return const SizedBox.shrink();

    return Card(
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
                    Icon(Icons.home_work, color: Colors.purple[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Хароҷоти ховар (ҳиссаи як сар)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              'Ин хароҷотҳо ба таври баробар байни ҳамаи чорвоҳои ховар тақсим карда шудаанд.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Хароҷоти ховар',
              '${barnExpenseShare.toStringAsFixed(2)} сомонӣ',
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightHistoryCard() {
    return Card(
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
                    Icon(Icons.monitor_weight, color: Colors.teal[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Таърихи вазн',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CattleWeightTrackingScreen(
                        cattleId: widget.cattleId,
                        earTag: cattle!.earTag,
                      ),
                    ),
                  ).then((_) => _loadData()),
                  child: const Text('Илова кардан'),
                ),
              ],
            ),
            const Divider(height: 16),
            if (weights.isEmpty)
              const Text('Ҳеҷ вазн бақайд нашудааст', style: TextStyle(color: Colors.grey))
            else
              ...weights.take(3).map((weight) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd/MM/yyyy').format(weight.measurementDate)),
                        Text(
                          '${weight.weight} кг',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),
            if (weights.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${weights.length - 3} дигар',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleCard() {
    return Card(
      color: Colors.green.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sell, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'Маълумоти фурӯш',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 16),
            _buildInfoRow('Навъи фурӯш', sale!.saleType == CattleSaleType.alive ? 'Зинда' : 'Забиҳшуда'),
            if (sale!.liveWeight != null)
              _buildInfoRow('Вазни зинда', '${sale!.liveWeight!.toStringAsFixed(1)} кг'),
            _buildInfoRow('Вазн', '${sale!.weight.toStringAsFixed(1)} кг'),
            if (sale!.pricePerKg != null)
              _buildInfoRow('Нархи як кг', '${sale!.pricePerKg!.toStringAsFixed(2)} сомонӣ'),
            _buildInfoRow('Санаи фурӯш', DateFormat('dd/MM/yyyy').format(sale!.saleDate)),
            if (sale!.buyerName != null)
              _buildInfoRow('Харидор', sale!.buyerName!),
            const Divider(height: 16),
            _buildInfoRow(
              'Нархи фурӯш',
              '${sale!.totalAmount.toStringAsFixed(2)} сомонӣ',
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalCosts() {
    double total = 0;

    // Purchase cost
    if (purchase != null) {
      total += purchase!.totalCost;
    }

    // Individual expenses
    total += expenses.fold<double>(0, (sum, e) => sum + e.cost);

    // Barn expense share
    total += barnExpenseShare;

    return total;
  }
}

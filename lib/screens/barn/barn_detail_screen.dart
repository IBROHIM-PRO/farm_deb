import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/barn_provider.dart';
import '../../providers/cattle_registry_provider.dart';
import '../../models/barn.dart';
import '../../models/barn_expense.dart';
import '../../models/cattle_registry.dart';
import '../../theme/app_theme.dart';
import 'add_barn_screen.dart';
import 'add_barn_expense_screen.dart';
import '../cattle_registry/cattle_financial_detail_screen.dart';

class BarnDetailScreen extends StatefulWidget {
  final int barnId;

  const BarnDetailScreen({super.key, required this.barnId});

  @override
  State<BarnDetailScreen> createState() => _BarnDetailScreenState();
}

class _BarnDetailScreenState extends State<BarnDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _cattleTabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cattleTabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BarnProvider>().loadBarnExpenses(widget.barnId);
      context.read<CattleRegistryProvider>().loadAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cattleTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тафсилоти ховар'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddBarnExpenseScreen(barnId: widget.barnId),
              ),
            ),
            tooltip: 'Харочот',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Маълумот', icon: Icon(Icons.info_outline)),
            Tab(text: 'Чорво', icon: Icon(Icons.pets)),
            Tab(text: 'Харочот', icon: Icon(Icons.attach_money)),
          ],
        ),
      ),
      body: Consumer<BarnProvider>(
        builder: (context, provider, _) {
          final barn = provider.getBarnById(widget.barnId);
          
          if (barn == null) {
            return const Center(child: Text('Ховар ёфт нашуд'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(barn, provider),
              _buildCattleTab(),
              _buildExpensesTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTab(Barn barn, BarnProvider provider) {
    final summary = provider.getBarnSummary(widget.barnId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.home_work, color: AppTheme.primaryIndigo, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        barn.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (barn.location != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          barn.location!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                _buildInfoRow('Таърихи сохт', DateFormat('dd/MM/yyyy').format(barn.createdDate)),
                if (barn.capacity != null)
                  _buildInfoRow('Ғунҷоиш', '${barn.capacity} сар'),
                _buildInfoRow('Шумораи чорво', '${summary['cattleCount']}'),
                if (barn.capacity != null)
                  _buildInfoRow(
                    'Фоизи пуршавӣ',
                    '${((summary['cattleCount'] / barn.capacity!) * 100).toStringAsFixed(1)}%',
                  ),
                if (barn.notes != null && barn.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Қайдҳо:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(barn.notes!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ҳисоботи молиявӣ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                  'Ҳамагӣ харочот',
                  '${summary['totalExpenses'].toStringAsFixed(0)} TJS',
                  Colors.red,
                ),
                _buildStatRow(
                  'Шумораи харочот',
                  '${summary['expenseCount']}',
                  Colors.blue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCattleTab() {
    return Column(
      children: [
        Container(
          color: Colors.grey[100],
          child: TabBar(
            controller: _cattleTabController,
            labelColor: AppTheme.primaryIndigo,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: AppTheme.primaryIndigo,
            tabs: const [
              Tab(text: 'Фаъол', icon: Icon(Icons.check_circle_outline, size: 20)),
              Tab(text: 'Фурӯхташуда', icon: Icon(Icons.sell_outlined, size: 20)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _cattleTabController,
            children: [
              _buildActiveBarnCattle(),
              _buildSoldBarnCattle(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveBarnCattle() {
    return Consumer<CattleRegistryProvider>(
      builder: (context, cattleProvider, _) {
        final activeCattle = cattleProvider.activeCattle
            .where((c) => c.barnId == widget.barnId)
            .toList();

        if (activeCattle.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Дар ин ховар чорвои фаъол нест',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Барои илова кардан чорворо бақайд кунед',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeCattle.length,
          itemBuilder: (context, index) {
            return _buildCattleCard(activeCattle[index], cattleProvider);
          },
        );
      },
    );
  }

  Widget _buildSoldBarnCattle() {
    return Consumer<CattleRegistryProvider>(
      builder: (context, cattleProvider, _) {
        final soldCattle = cattleProvider.soldCattle
            .where((c) => c.barnId == widget.barnId)
            .toList();

        if (soldCattle.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sell_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Дар ин ховар чорво фурӯхта нашудааст',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: soldCattle.length,
          itemBuilder: (context, index) {
            return _buildCattleCard(soldCattle[index], cattleProvider);
          },
        );
      },
    );
  }

  Widget _buildCattleCard(CattleRegistry cattle, CattleRegistryProvider provider) {
    final purchase = provider.getCattlePurchases(cattle.id!).isNotEmpty
        ? provider.getCattlePurchases(cattle.id!).first
        : null;
    final weights = provider.getCattleWeights(cattle.id!);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CattleFinancialDetailScreen(cattleId: cattle.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
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
                      color: cattle.gender == CattleGender.male
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.pink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      cattle.gender == CattleGender.male ? Icons.male : Icons.female,
                      color: cattle.gender == CattleGender.male ? Colors.blue : Colors.pink,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cattle.earTag,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (cattle.name != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            cattle.name!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                cattle.ageCategoryDisplay,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cattle.genderDisplay,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
              
              if (purchase != null || weights.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
              ],
              
              // Purchase Info
              if (purchase != null)
                Row(
                  children: [
                    Icon(Icons.shopping_cart, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'Харид: ${purchase.weightAtPurchase.toStringAsFixed(0)} кг',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    if (purchase.totalPrice != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        '•',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${purchase.totalPrice!.toStringAsFixed(0)} ${purchase.currency}',
                        style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              
              // Latest Weight
              if (weights.isNotEmpty) ...[
                if (purchase != null) const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.scale, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'Вазни охирин: ${weights.last.weight.toStringAsFixed(0)} кг',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${DateFormat('dd.MM.yyyy').format(weights.last.measurementDate)})',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesTab(BarnProvider provider) {
    final expenses = provider.getBarnExpenses(widget.barnId);

    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.attach_money, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Ҳеҷ харочот бақайд нашудааст',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return _buildExpenseCard(expense);
      },
    );
  }

  Widget _buildExpenseCard(BarnExpense expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getExpenseIcon(expense.expenseType),
                  color: _getExpenseColor(expense.expenseType),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.itemName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        expense.expenseTypeDisplay,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${expense.totalCost.toStringAsFixed(0)} ${expense.currency}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  expense.quantityDisplay,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(expense.expenseDate),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            if (expense.supplier != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.store, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    expense.supplier!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getExpenseIcon(BarnExpenseType type) {
    switch (type) {
      case BarnExpenseType.feed:
        return Icons.grass;
      case BarnExpenseType.medication:
        return Icons.medication;
      case BarnExpenseType.water:
        return Icons.water_drop;
      case BarnExpenseType.other:
        return Icons.more_horiz;
    }
  }

  Color _getExpenseColor(BarnExpenseType type) {
    switch (type) {
      case BarnExpenseType.feed:
        return Colors.green;
      case BarnExpenseType.medication:
        return Colors.red;
      case BarnExpenseType.water:
        return Colors.blue;
      case BarnExpenseType.other:
        return Colors.orange;
    }
  }

  void _editBarn() {
    final provider = context.read<BarnProvider>();
    final barn = provider.getBarnById(widget.barnId);
    if (barn != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddBarnScreen(barn: barn),
        ),
      );
    }
  }

  Future<void> _deleteBarn() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Тасдиқ кунед'),
        content: const Text('Шумо мутмаин ҳастед, ки мехоҳед ин ховарро нест кунед?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Бекор кардан'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Нест кардан'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<BarnProvider>().deleteBarn(widget.barnId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ховар бомуваффақият нест карда шуд')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Хато: ${e.toString()}')),
          );
        }
      }
    }
  }
}

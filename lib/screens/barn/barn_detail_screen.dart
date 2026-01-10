import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/barn_provider.dart';
import '../../providers/cattle_registry_provider.dart';
import '../../providers/settings_provider.dart';
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
        title: const Text('Тафсилоти оғул'),
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
            tooltip: 'Хароҷот',
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
            return const Center(child: Text('Оғул ёфт нашуд'));
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
                  '${summary['totalExpenses'].toStringAsFixed(2)} TJS',
                  Colors.red,
                ),
                _buildStatRow(
                  'Шумораи харочот',
                  '${summary['expenseCount']}',
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _buildActiveToggle(barn, provider),
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
                  'Дар ин оғул чорвои фаъол нест',
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
                  'Дар ин оғул чорво фурӯхта нашудааст',
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CattleFinancialDetailScreen(cattleId: cattle.id!),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with status dot and ear tag
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: cattle.status == CattleStatus.active ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    cattle.earTag,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Details section with left padding
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cattle.name != null) ...[
                      Row(
                        children: [
                          Text(
                            'Ном:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cattle.name!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Text(
                          'Ҷинс:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          cattle.gender == CattleGender.male ? Icons.male : Icons.female,
                          size: 16,
                          color: cattle.gender == CattleGender.male ? Colors.blue : Colors.pink,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cattle.genderDisplay,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            cattle.ageCategoryDisplay,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    if (purchase != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Харид:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${purchase.weightAtPurchase.toStringAsFixed(2)} кг',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          if (purchase.totalPrice != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              '${purchase.totalPrice!.toStringAsFixed(2)} ${purchase.currency}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (weights.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Вазни охирин:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${weights.last.weight.toStringAsFixed(2)} кг',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${DateFormat('dd.MM').format(weights.last.measurementDate)})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward_ios,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Edit/Delete buttons ABOVE the information
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, _) {
              if (!settingsProvider.editDeleteEnabled) {
                return const SizedBox.shrink();
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddBarnExpenseScreen(
                              barnId: expense.barnId,
                              expense: expense,
                            ),
                          ),
                        );
                        if (context.mounted) {
                          await context.read<BarnProvider>().loadBarnExpenses(expense.barnId);
                        }
                      },
                      tooltip: 'Таҳрир',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 18,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () async {
                        final confirm = await _confirmDeleteBarnExpense(context);
                        if (confirm == true && context.mounted) {
                          await context.read<BarnProvider>()
                              .deleteBarnExpense(expense.id!, expense.barnId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Харочот бомуваффақият нест карда шуд'),
                              ),
                            );
                          }
                        }
                      },
                      tooltip: 'Нест кардан',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 18,
                    ),
                  ],
                ),
              );
            },
          ),
          // Information display
          GestureDetector(
            onTap: () => _showExpenseDetailsModal(expense),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with status dot and item name
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getExpenseColor(expense.expenseType),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          expense.itemName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${expense.totalCost.toStringAsFixed(2)} ${expense.currency}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Details section with left padding
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  Row(
                    children: [
                      Text(
                        'Навъ:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        expense.expenseTypeDisplay,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Миқдор:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        expense.quantityDisplay,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Сана:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd.MM.yyyy').format(expense.expenseDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (expense.supplier != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Таъминкунанда:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          expense.supplier!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    ),
        ],
      ),
    );
  }

  void _showExpenseDetailsModal(BarnExpense expense) {
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
                        decoration: BoxDecoration(
                          color: _getExpenseColor(expense.expenseType),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.itemName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Тафсилоти харочот',
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
                
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Summary Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Маблағи умумӣ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${expense.totalCost.toStringAsFixed(2)} ${expense.currency}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _getExpenseIcon(expense.expenseType),
                              color: _getExpenseColor(expense.expenseType),
                              size: 36,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Details Section
                      _buildModalDetailRow('Навъи харочот', expense.expenseTypeDisplay),
                      if (expense.feedType != null)
                        _buildModalDetailRow('Навъи хӯрок', expense.feedTypeDisplay),
                      _buildModalDetailRow('Номи мол', expense.itemName),
                      _buildModalDetailRow('Миқдор', expense.quantityDisplay),
                      _buildModalDetailRow('Нархи як воҳид', '${expense.pricePerUnit.toStringAsFixed(2)} ${expense.currency}/${expense.quantityUnit}'),
                      _buildModalDetailRow('Сана', DateFormat('dd.MM.yyyy').format(expense.expenseDate)),
                      if (expense.supplier != null)
                        _buildModalDetailRow('Таъминкунанда', expense.supplier!),
                      if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Қайдҳо:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                expense.notes!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Edit/Delete Buttons (conditionally shown)
                      Consumer<SettingsProvider>(
                        builder: (context, settingsProvider, _) {
                          if (!settingsProvider.editDeleteEnabled) {
                            return const SizedBox(height: 30);
                          }
                          return Column(
                            children: [
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddBarnExpenseScreen(
                                              barnId: expense.barnId,
                                              expense: expense,
                                            ),
                                          ),
                                        );
                                        
                                        // Refresh data after edit
                                        if (context.mounted) {
                                          await context.read<BarnProvider>().loadBarnExpenses(expense.barnId);
                                        }
                                      },
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Таҳрир'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final confirm = await _confirmDeleteBarnExpense(context);
                                        if (confirm == true && context.mounted) {
                                          await context.read<BarnProvider>()
                                              .deleteBarnExpense(expense.id!, expense.barnId);
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Харочот бомуваффақият нест карда шуд'),
                                              ),
                                            );
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
                              const SizedBox(height: 30),
                            ],
                          );
                        },
                      ),
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
  
  Future<bool?> _confirmDeleteBarnExpense(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Тасдиқ кунед'),
        content: const Text('Шумо мутмаин ҳастед, ки мехоҳед ин харочотро нест кунед?'),
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

  Widget _buildModalDetailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

  void _editBarn() async {
    final provider = context.read<BarnProvider>();
    final barn = provider.getBarnById(widget.barnId);
    if (barn != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddBarnScreen(barn: barn),
        ),
      );
      
      // Refresh all data after returning from edit
      if (mounted) {
        await provider.loadBarns();
        await provider.loadBarnExpenses(widget.barnId);
        await context.read<CattleRegistryProvider>().loadAllData();
      }
    }
  }

  Widget _buildActiveToggle(Barn barn, BarnProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ҳолати оғул',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              barn.isActive ? 'Фаъол' : 'Ғайрифаъол',
              style: TextStyle(
                fontSize: 14,
                color: barn.isActive ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
        Switch(
          value: barn.isActive,
          onChanged: (value) async {
            await _toggleBarnStatus(barn, value, provider);
          },
          activeColor: Colors.green,
        ),
      ],
    );
  }

  Future<void> _toggleBarnStatus(Barn barn, bool newStatus, BarnProvider provider) async {
    try {
      final updatedBarn = barn.copyWith(isActive: newStatus);
      await provider.updateBarn(updatedBarn);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus 
                  ? 'Оғул фаъол карда шуд' 
                  : 'Оғул ғайрифаъол карда шуд',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Хато: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteBarn() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Тасдиқ кунед'),
        content: const Text('Шумо мутмаин ҳастед, ки мехоҳед ин оғулро нест кунед? Ин амал бозгашт карда намешавад ва ҳамаи маълумоти марбут нест карда мешаванд.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Бекор кардан'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
            const SnackBar(content: Text('Оғул бомуваффақият нест карда шуд')),
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

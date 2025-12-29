import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cattle_registry_provider.dart';
import '../../models/cattle_registry.dart';
import '../../models/cattle_purchase.dart';
import '../../models/cattle_expense.dart';
import '../../models/cattle_weight.dart';
import '../../theme/app_theme.dart';
import 'add_cattle_purchase_screen.dart';
import 'add_cattle_expense_screen.dart';
import 'add_cattle_weight_screen.dart';

/// Cattle Registry Detail Screen - Complete cattle lifecycle view
/// Shows registry identity + all linked events (purchases, expenses, weights, sales)
class CattleRegistryDetailScreen extends StatefulWidget {
  final int cattleId;

  const CattleRegistryDetailScreen({
    super.key,
    required this.cattleId,
  });

  @override
  State<CattleRegistryDetailScreen> createState() => _CattleRegistryDetailScreenState();
}

class _CattleRegistryDetailScreenState extends State<CattleRegistryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CattleRegistryProvider>(
      builder: (context, provider, _) {
        final cattle = provider.cattleRegistry
            .where((c) => c.id == widget.cattleId)
            .firstOrNull;

        if (cattle == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Чорво ёфт нашуд')),
            body: const Center(
              child: Text('Чорво дар реестр мавҷуд нест'),
            ),
          );
        }

        final summary = provider.getCattleSummary(widget.cattleId);

        return Scaffold(
          appBar: AppBar(
            title: Text('Чорво ${cattle.earTag}'),
            backgroundColor: AppTheme.primaryIndigo,
            foregroundColor: Colors.white,
            actions: [
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Таҳрир кардан'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (cattle.status == CattleStatus.active)
                    const PopupMenuItem(
                      value: 'sell',
                      child: ListTile(
                        leading: Icon(Icons.sell, color: Colors.orange),
                        title: Text('Фурӯхтан'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Нест кардан'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                onSelected: (value) => _handleMenuAction(value, cattle),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Умумӣ', icon: Icon(Icons.info, size: 16)),
                Tab(text: 'Хариданӣ', icon: Icon(Icons.shopping_cart, size: 16)),
                Tab(text: 'Харочот', icon: Icon(Icons.payment, size: 16)),
                Tab(text: 'Вазн', icon: Icon(Icons.scale, size: 16)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(cattle, summary),
              _buildPurchaseTab(cattle, summary),
              _buildExpensesTab(cattle, summary),
              _buildWeightsTab(cattle, summary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(CattleRegistry cattle, Map<String, dynamic> summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identity Card
          _buildIdentityCard(cattle),
          
          const SizedBox(height: 16),
          
          // Status Card
          _buildStatusCard(cattle, summary),
          
          const SizedBox(height: 16),
          
          // Financial Summary
          if (summary['purchase'] != null)
            _buildFinancialSummary(summary),
          
          const SizedBox(height: 16),
          
          // Quick Actions
          _buildQuickActions(cattle),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(CattleRegistry cattle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pets, color: AppTheme.primaryIndigo),
                const SizedBox(width: 8),
                const Text(
                  'Маълумоти асосӣ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildInfoRow('Рамзи гӯш:', cattle.earTag),
            _buildInfoRow('Ҷинс:', cattle.genderDisplay),
            _buildInfoRow('Синну сол:', cattle.ageCategoryDisplay),
            _buildInfoRow(
              'Санаи бақайдгирӣ:',
              DateFormat('dd/MM/yyyy').format(cattle.registrationDate),
            ),
            _buildInfoRow('Ҳолат:', cattle.statusDisplay),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(CattleRegistry cattle, Map<String, dynamic> summary) {
    final isActive = cattle.status == CattleStatus.active;
    
    return Card(
      color: isActive 
          ? Colors.green.withOpacity(0.1) 
          : Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.favorite : Icons.sell,
              color: isActive ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'Чорвои фаъол' : 'Чорвои фурӯхташуда',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green : Colors.orange,
                    ),
                  ),
                  Text(
                    isActive 
                        ? 'Дар фарм ҳастанд ва идора мешаванд'
                        : 'Фурӯхта шуда ва аз реестр баромада',
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
      ),
    );
  }

  Widget _buildFinancialSummary(Map<String, dynamic> summary) {
    final purchase = summary['purchase'] as CattlePurchase?;
    final totalExpenses = (summary['totalExpenses'] as num?)?.toDouble() ?? 0.0;
    final sale = summary['sale'];
    final profit = (summary['profit'] as num?)?.toDouble() ?? 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Хулосаи молиявӣ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (purchase != null)
              _buildFinancialRow(
                'Хариданӣ:',
                '${purchase.totalCost.toStringAsFixed(0)} TJS',
                Colors.red,
              ),
            
            if (totalExpenses > 0)
              _buildFinancialRow(
                'Харочот:',
                '${totalExpenses.toStringAsFixed(0)} TJS',
                Colors.orange,
              ),
            
            if (sale != null)
              _buildFinancialRow(
                'Фуруш:',
                '${sale.totalAmount.toStringAsFixed(0)} TJS',
                Colors.green,
              ),
            
            const Divider(),
            
            _buildFinancialRow(
              'Фоида:',
              '${profit.toStringAsFixed(0)} TJS',
              profit >= 0 ? Colors.green : Colors.red,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(CattleRegistry cattle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Амалҳои зуд',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                if (cattle.status == CattleStatus.active) ...[
                  Expanded(
                    child: _buildActionButton(
                      'Харочот',
                      Icons.payment,
                      Colors.orange,
                      () => _navigateToAddExpense(cattle),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      'Вазнкунӣ',
                      Icons.scale,
                      Colors.purple,
                      () => _navigateToAddWeight(cattle),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildPurchaseTab(CattleRegistry cattle, Map<String, dynamic> summary) {
    final purchase = summary['purchase'] as CattlePurchase?;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (purchase == null)
            _buildEmptyPurchaseState(cattle)
          else
            _buildPurchaseDetails(purchase),
        ],
      ),
    );
  }

  Widget _buildEmptyPurchaseState(CattleRegistry cattle) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Icon(
          Icons.shopping_cart_outlined,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        const Text(
          'Маълумоти хариданӣ нест',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Маълумоти хариданӣ чорворо илова кунед',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _navigateToAddPurchase(cattle),
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Хариданӣ илова кунед'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryIndigo,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseDetails(CattlePurchase purchase) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Тафсилоти хариданӣ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildInfoRow(
              'Санаи хариданӣ:',
              DateFormat('dd/MM/yyyy').format(purchase.purchaseDate),
            ),
            _buildInfoRow(
              'Вазн:',
              '${purchase.weightAtPurchase.toStringAsFixed(1)} кг',
            ),
            if (purchase.pricePerKg != null)
              _buildInfoRow(
                'Нархи як кг:',
                '${purchase.pricePerKg!.toStringAsFixed(2)} ${purchase.currency}',
              ),
            if (purchase.totalPrice != null)
              _buildInfoRow(
                'Нархи умумӣ:',
                '${purchase.totalPrice!.toStringAsFixed(0)} ${purchase.currency}',
              ),
            if (purchase.transportationCost > 0)
              _buildInfoRow(
                'Нархи интиқол:',
                '${purchase.transportationCost.toStringAsFixed(0)} ${purchase.currency}',
              ),
            if (purchase.sellerName != null)
              _buildInfoRow('Фурушанда:', purchase.sellerName!),
            
            const Divider(),
            
            _buildInfoRow(
              'Ҳамагӣ харч:',
              '${purchase.totalCost.toStringAsFixed(0)} ${purchase.currency}',
              bold: true,
            ),
            
            _buildInfoRow(
              'Ҳолати пардохт:',
              purchase.paymentStatusDisplay,
              color: _getPaymentStatusColor(purchase.paymentStatus),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesTab(CattleRegistry cattle, Map<String, dynamic> summary) {
    final provider = context.read<CattleRegistryProvider>();
    final expenses = provider.getExpensesForCattle(widget.cattleId);
    
    return Column(
      children: [
        // Summary Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ҳамагӣ харочот: ${(summary['totalExpenses'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'} сомонӣ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${expenses.length} дона',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // Expenses List
        Expanded(
          child: expenses.isEmpty
              ? _buildEmptyExpensesState(cattle)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    return _buildExpenseCard(expenses[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWeightsTab(CattleRegistry cattle, Map<String, dynamic> summary) {
    final provider = context.read<CattleRegistryProvider>();
    final weights = provider.getWeightsForCattle(widget.cattleId);
    
    return Column(
      children: [
        // Summary Header
        if (summary['purchase'] != null && summary['latestWeight'] != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Афзоиши вазн: +${(summary['weightGain'] ?? 0).toStringAsFixed(1)} кг',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${weights.length} андоза',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        
        // Weights List
        Expanded(
          child: weights.isEmpty
              ? _buildEmptyWeightsState(cattle)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: weights.length,
                  itemBuilder: (context, index) {
                    return _buildWeightCard(weights[index], index == 0);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyExpensesState(CattleRegistry cattle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Харочот сабт нашудааст',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddExpense(cattle),
            icon: const Icon(Icons.add),
            label: const Text('Харочот илова кунед'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWeightsState(CattleRegistry cattle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.scale_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Вазн андоза нашудааст',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddWeight(cattle),
            icon: const Icon(Icons.add),
            label: const Text('Вазн андоза кунед'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(CattleExpense expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getExpenseTypeColor(expense.expenseType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getExpenseTypeIcon(expense.expenseType),
                color: _getExpenseTypeColor(expense.expenseType),
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.expenseTypeDisplay,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    expense.itemName,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${expense.quantityDisplay} • ${DateFormat('dd/MM/yyyy').format(expense.expenseDate)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            
            Text(
              '${expense.cost.toStringAsFixed(0)} TJS',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightCard(CattleWeight weight, bool isLatest) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLatest 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.scale,
                color: isLatest ? Colors.green : Colors.purple,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weight.weightDisplay,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(weight.measurementDate),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (weight.notes != null)
                    Text(
                      weight.notes!,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            
            if (isLatest)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Охирин',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(PurchasePaymentStatus status) {
    switch (status) {
      case PurchasePaymentStatus.pending:
        return Colors.red;
      case PurchasePaymentStatus.partial:
        return Colors.orange;
      case PurchasePaymentStatus.paid:
        return Colors.green;
    }
  }

  Color _getExpenseTypeColor(ExpenseType type) {
    switch (type) {
      case ExpenseType.feed:
        return Colors.green;
      case ExpenseType.medication:
        return Colors.red;
      case ExpenseType.other:
        return Colors.blue;
    }
  }

  IconData _getExpenseTypeIcon(ExpenseType type) {
    switch (type) {
      case ExpenseType.feed:
        return Icons.restaurant;
      case ExpenseType.medication:
        return Icons.medical_services;
      case ExpenseType.other:
        return Icons.more_horiz;
    }
  }

  void _handleMenuAction(String action, CattleRegistry cattle) {
    switch (action) {
      case 'edit':
        // Navigate to edit screen
        break;
      case 'sell':
        // Navigate to sell screen
        break;
      case 'delete':
        _showDeleteConfirmation(cattle);
        break;
    }
  }

  void _showDeleteConfirmation(CattleRegistry cattle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Нест кардан'),
        content: Text('Чорвои ${cattle.earTag}-ро аз реестр нест кунем?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Бекор кардан'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context
                    .read<CattleRegistryProvider>()
                    .deleteCattleFromRegistry(widget.cattleId);
                if (mounted) {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Чорво нест карда шуд'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Хатогӣ: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
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

  void _navigateToAddPurchase(CattleRegistry cattle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCattlePurchaseScreen(cattleId: cattle.id!),
      ),
    );
  }

  void _navigateToAddExpense(CattleRegistry cattle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCattleExpenseScreen(cattleId: cattle.id!),
      ),
    );
  }

  void _navigateToAddWeight(CattleRegistry cattle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCattleWeightScreen(cattleId: cattle.id!),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

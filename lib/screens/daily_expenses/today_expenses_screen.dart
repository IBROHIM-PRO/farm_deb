import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/daily_expense_provider.dart';
import '../../models/daily_expense.dart';
import '../../theme/app_theme.dart';
import 'all_expenses_screen.dart';

class TodayExpensesScreen extends StatefulWidget {
  const TodayExpensesScreen({super.key});

  @override
  State<TodayExpensesScreen> createState() => _TodayExpensesScreenState();
}

class _TodayExpensesScreenState extends State<TodayExpensesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DailyExpenseProvider>(context, listen: false).loadTodayExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Харочоти имрӯза'),
        backgroundColor: AppTheme.primaryIndigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllExpensesScreen()),
              );
            },
            tooltip: 'Ҳамаи харочотҳо',
          ),
        ],
      ),
      body: Consumer<DailyExpenseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadTodayExpenses();
            },
            child: provider.todayExpenses.isEmpty
                ? _buildEmptyState()
                : _buildExpensesList(provider),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseForm(context),
        backgroundColor: AppTheme.primaryIndigo,
        icon: const Icon(Icons.add),
        label: const Text('Харочот илова кунед'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Icon(
          Icons.receipt_long,
          size: 100,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 24),
        Text(
          'Имрӯз ҳанӯз харочоте нест',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Барои илова кардани харочот тугмаро пахш кунед',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesList(DailyExpenseProvider provider) {
    final total = provider.getTotalExpensesForToday();
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ҷамъи харочот:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '${total.toStringAsFixed(2)} TJS',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.todayExpenses.length,
            itemBuilder: (context, index) {
              final expense = provider.todayExpenses[index];
              return _buildExpenseCard(expense);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(DailyExpense expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showExpenseDetails(expense),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getCategoryColor(expense.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(expense.category),
                  color: _getCategoryColor(expense.category),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.itemName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense.category,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${expense.amount.toStringAsFixed(2)} ${expense.currency}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpenseDetails(DailyExpense expense) {
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Тафсилоти харочот',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Мавод', expense.itemName),
            _buildDetailRow('Категория', expense.category),
            _buildDetailRow('Маблағ', '${expense.amount.toStringAsFixed(2)} ${expense.currency}'),
            _buildDetailRow('Сана', DateFormat('dd.MM.yyyy').format(expense.expenseDate)),
            if (expense.notes != null && expense.notes!.isNotEmpty)
              _buildDetailRow('Эзоҳ', expense.notes!),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditExpenseForm(context, expense);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Таҳрир'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await _confirmDelete(context);
                      if (confirm == true && context.mounted) {
                        await Provider.of<DailyExpenseProvider>(context, listen: false)
                            .deleteExpense(expense.id!);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Харочот нест карда шуд')),
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
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
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

  void _showAddExpenseForm(BuildContext context) {
    _showExpenseForm(context, null);
  }

  void _showEditExpenseForm(BuildContext context, DailyExpense expense) {
    _showExpenseForm(context, expense);
  }

  void _showExpenseForm(BuildContext context, DailyExpense? expense) {
    final formKey = GlobalKey<FormState>();
    final categoryController = TextEditingController(text: expense?.category ?? 'Озуқа');
    final itemNameController = TextEditingController(text: expense?.itemName ?? '');
    final amountController = TextEditingController(
      text: expense?.amount.toString() ?? '',
    );
    final currencyController = TextEditingController(text: expense?.currency ?? 'TJS');
    final notesController = TextEditingController(text: expense?.notes ?? '');

    final categories = ['Озуқа', 'Транспорт', 'Коргар', 'Тандурустӣ', 'Хона', 'Дигар'];

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
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      expense == null ? 'Харочоти нав' : 'Таҳрири харочот',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: categoryController.text,
                  decoration: const InputDecoration(
                    labelText: 'Категория',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) categoryController.text = value;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: itemNameController,
                  decoration: const InputDecoration(
                    labelText: 'Номи мавод',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Лутфан номи маводро ворид кунед';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Маблағ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Маблағро ворид кунед';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Рақами дуруст ворид кунед';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: currencyController.text,
                        decoration: const InputDecoration(
                          labelText: 'Асъор',
                          border: OutlineInputBorder(),
                        ),
                        items: ['TJS', 'USD', 'RUB'].map((curr) {
                          return DropdownMenuItem(value: curr, child: Text(curr));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) currencyController.text = value;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Эзоҳ (ихтиёрӣ)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final newExpense = DailyExpense(
                          id: expense?.id,
                          category: categoryController.text,
                          itemName: itemNameController.text,
                          amount: double.parse(amountController.text),
                          currency: currencyController.text,
                          expenseDate: expense?.expenseDate ?? DateTime.now(),
                          notes: notesController.text.isEmpty ? null : notesController.text,
                        );

                        final provider = Provider.of<DailyExpenseProvider>(context, listen: false);
                        bool success;
                        
                        if (expense == null) {
                          success = await provider.addExpense(newExpense);
                        } else {
                          success = await provider.updateExpense(newExpense);
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  expense == null
                                      ? 'Харочот илова карда шуд'
                                      : 'Харочот таҳрир карда шуд',
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(expense == null ? 'Илова кардан' : 'Нигоҳ доштан'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Озуқа':
        return Colors.orange;
      case 'Транспорт':
        return Colors.blue;
      case 'Маориф':
        return Colors.purple;
      case 'Тандурустӣ':
        return Colors.red;
      case 'Хона':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Озуқа':
        return Icons.restaurant;
      case 'Транспорт':
        return Icons.directions_car;
      case 'Маориф':
        return Icons.school;
      case 'Тандурустӣ':
        return Icons.medical_services;
      case 'Хона':
        return Icons.home;
      default:
        return Icons.receipt;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/daily_expense_provider.dart';
import '../../models/daily_expense.dart';
import '../../theme/app_theme.dart';

class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  State<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends State<AllExpensesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DailyExpenseProvider>(context, listen: false).loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ҳамаи харочотҳо'),
        backgroundColor: AppTheme.primaryIndigo,
        foregroundColor: Colors.white,
      ),
      body: Consumer<DailyExpenseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadExpenses();
            },
            child: provider.expenses.isEmpty
                ? _buildEmptyState()
                : _buildExpensesList(provider),
          );
        },
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
          'Ҳанӯз харочоте нест',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesList(DailyExpenseProvider provider) {
    final groupedExpenses = _groupExpensesByDate(provider.expenses);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedExpenses.length,
      itemBuilder: (context, index) {
        final date = groupedExpenses.keys.elementAt(index);
        final expenses = groupedExpenses[date]!;
        final total = expenses.fold<double>(0, (sum, exp) => sum + exp.amount);
        
        return _buildDateGroup(date, expenses, total);
      },
    );
  }

  Map<String, List<DailyExpense>> _groupExpensesByDate(List<DailyExpense> expenses) {
    final Map<String, List<DailyExpense>> grouped = {};
    
    for (var expense in expenses) {
      final dateKey = DateFormat('yyyy-MM-dd').format(expense.expenseDate);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(expense);
    }
    
    return grouped;
  }

  Widget _buildDateGroup(String date, List<DailyExpense> expenses, double total) {
    final dateObj = DateTime.parse(date);
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    String dateLabel;
    if (DateFormat('yyyy-MM-dd').format(dateObj) == DateFormat('yyyy-MM-dd').format(today)) {
      dateLabel = 'Имрӯз';
    } else if (DateFormat('yyyy-MM-dd').format(dateObj) == DateFormat('yyyy-MM-dd').format(yesterday)) {
      dateLabel = 'Дирӯз';
    } else {
      dateLabel = DateFormat('dd.MM.yyyy').format(dateObj);
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(2)} TJS',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          ...expenses.map((expense) => _buildExpenseItem(expense)),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(DailyExpense expense) {
    return InkWell(
      onTap: () => _showExpenseDetails(expense),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCategoryColor(expense.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(expense.category),
                color: _getCategoryColor(expense.category),
                size: 20,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expense.category,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${expense.amount.toStringAsFixed(2)} ${expense.currency}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
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

  void _showEditExpenseForm(BuildContext context, DailyExpense expense) {
    final formKey = GlobalKey<FormState>();
    final categoryController = TextEditingController(text: expense.category);
    final itemNameController = TextEditingController(text: expense.itemName);
    final amountController = TextEditingController(text: expense.amount.toString());
    final currencyController = TextEditingController(text: expense.currency);
    final notesController = TextEditingController(text: expense.notes ?? '');

    final categories = ['Озуқа', 'Транспорт', 'Маориф', 'Тандурустӣ', 'Хона', 'Дигар'];

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
                    const Text(
                      'Таҳрири харочот',
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
                        final updatedExpense = expense.copyWith(
                          category: categoryController.text,
                          itemName: itemNameController.text,
                          amount: double.parse(amountController.text),
                          currency: currencyController.text,
                          notes: notesController.text.isEmpty ? null : notesController.text,
                        );

                        final provider = Provider.of<DailyExpenseProvider>(context, listen: false);
                        final success = await provider.updateExpense(updatedExpense);

                        if (context.mounted) {
                          Navigator.pop(context);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Харочот таҳрир карда шуд')),
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
                    child: const Text('Нигоҳ доштан'),
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

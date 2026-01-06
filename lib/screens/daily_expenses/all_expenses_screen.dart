import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/daily_expense_provider.dart';
import '../../models/daily_expense.dart';
import '../../theme/app_theme.dart';

class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  State<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

enum ExpenseFilter { week, month, sixMonths, year }

class _AllExpensesScreenState extends State<AllExpensesScreen> {
  ExpenseFilter _selectedFilter = ExpenseFilter.week;

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

          return Column(
            children: [
              _buildFilterButtons(),
              _buildExpenseChart(provider),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await provider.loadExpenses();
                  },
                  child: provider.expenses.isEmpty
                      ? _buildEmptyState()
                      : _buildExpensesList(provider),
                ),
              ),
            ],
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

  Widget _buildFilterButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterButton(
              'Ҳафта',
              ExpenseFilter.week,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton(
              'Моҳ',
              ExpenseFilter.month,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton(
              '6 моҳ',
              ExpenseFilter.sixMonths,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton(
              'Сол',
              ExpenseFilter.year,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, ExpenseFilter filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryIndigo : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseChart(DailyExpenseProvider provider) {
    final filteredExpenses = _getFilteredExpenses(provider.expenses);
    if (filteredExpenses.isEmpty) return const SizedBox.shrink();
    
    final chartData = _getChartData(filteredExpenses);
    if (chartData.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Харочоти моҳона',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartData.values.isEmpty ? 100 : chartData.values.reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBorder: const BorderSide(color: Colors.transparent),
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dateTimeInfo = _getDetailedDateInfo(group.x.toInt());
                      return BarTooltipItem(
                        '${dateTimeInfo['title']}\n${dateTimeInfo['subtitle']}\n${rod.toY.toStringAsFixed(2)} TJS',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _getChartLabel(value.toInt()),
                            style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                          ),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: chartData.entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: Colors.blue,
                        width: _selectedFilter == ExpenseFilter.week ? 24 : (_selectedFilter == ExpenseFilter.month ? 8 : 12),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<int, double> _getChartData(List<DailyExpense> expenses) {
    final Map<int, double> data = {};
    
    switch (_selectedFilter) {
      case ExpenseFilter.week:
        // Last 7 days
        for (int i = 0; i < 7; i++) {
          data[i] = 0;
        }
        final now = DateTime.now();
        for (var expense in expenses) {
          final diff = now.difference(expense.expenseDate).inDays;
          if (diff >= 0 && diff < 7) {
            final index = 6 - diff;
            data[index] = (data[index] ?? 0) + expense.amount;
          }
        }
        break;
        
      case ExpenseFilter.month:
        // Last 30 days (grouped by ~4-5 day periods to fit in chart)
        for (int i = 0; i < 7; i++) {
          data[i] = 0;
        }
        final now = DateTime.now();
        for (var expense in expenses) {
          final diff = now.difference(expense.expenseDate).inDays;
          if (diff >= 0 && diff < 30) {
            final index = 6 - (diff ~/ 4);
            data[index] = (data[index] ?? 0) + expense.amount;
          }
        }
        break;
        
      case ExpenseFilter.sixMonths:
        // Last 6 months
        for (int i = 0; i < 6; i++) {
          data[i] = 0;
        }
        final now = DateTime.now();
        for (var expense in expenses) {
          final monthDiff = (now.year - expense.expenseDate.year) * 12 + (now.month - expense.expenseDate.month);
          if (monthDiff >= 0 && monthDiff < 6) {
            final index = 5 - monthDiff;
            data[index] = (data[index] ?? 0) + expense.amount;
          }
        }
        break;
        
      case ExpenseFilter.year:
        // Last 12 months
        for (int i = 0; i < 12; i++) {
          data[i] = 0;
        }
        final now = DateTime.now();
        for (var expense in expenses) {
          final monthDiff = (now.year - expense.expenseDate.year) * 12 + (now.month - expense.expenseDate.month);
          if (monthDiff >= 0 && monthDiff < 12) {
            final index = 11 - monthDiff;
            data[index] = (data[index] ?? 0) + expense.amount;
          }
        }
        break;
    }
    
    return data;
  }

  String _getChartLabel(int index) {
    switch (_selectedFilter) {
      case ExpenseFilter.week:
        final date = DateTime.now().subtract(Duration(days: 6 - index));
        return DateFormat('dd').format(date);
        
      case ExpenseFilter.month:
        final daysAgo = (6 - index) * 4;
        return '${daysAgo}-${daysAgo + 4}';
        
      case ExpenseFilter.sixMonths:
        final monthsAgo = 5 - index;
        final now = DateTime.now();
        final targetMonth = now.month - monthsAgo;
        final targetYear = now.year + (targetMonth - 1) ~/ 12;
        final normalizedMonth = ((targetMonth - 1) % 12) + 1;
        final date = DateTime(targetYear, normalizedMonth);
        return DateFormat('MMM', 'ru').format(date).substring(0, 3);
        
      case ExpenseFilter.year:
        final monthsAgo = 11 - index;
        final now = DateTime.now();
        final targetMonth = now.month - monthsAgo;
        final targetYear = now.year + (targetMonth - 1) ~/ 12;
        final normalizedMonth = ((targetMonth - 1) % 12) + 1;
        final date = DateTime(targetYear, normalizedMonth);
        const monthNames = ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'];
        return monthNames[normalizedMonth - 1];
    }
  }

  Map<String, String> _getDetailedDateInfo(int index) {
    switch (_selectedFilter) {
      case ExpenseFilter.week:
        final date = DateTime.now().subtract(Duration(days: 6 - index));
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        
        String dayLabel;
        if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(today)) {
          dayLabel = 'Имрӯз';
        } else if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(yesterday)) {
          dayLabel = 'Дирӯз';
        } else {
          const weekDays = ['Якшанбе', 'Душанбе', 'Сешанбе', 'Чоршанбе', 'Панҷшанбе', 'Ҷумъа', 'Шанбе'];
          dayLabel = weekDays[date.weekday % 7];
        }
        
        return {
          'title': dayLabel,
          'subtitle': DateFormat('dd.MM.yyyy').format(date),
        };
        
      case ExpenseFilter.month:
        final daysAgo = (6 - index) * 4;
        final endDate = DateTime.now().subtract(Duration(days: daysAgo));
        final startDate = DateTime.now().subtract(Duration(days: daysAgo + 4));
        
        return {
          'title': '${DateFormat('dd.MM').format(startDate)} - ${DateFormat('dd.MM').format(endDate)}',
          'subtitle': 'Давраи 4 рӯза',
        };
        
      case ExpenseFilter.sixMonths:
        final monthsAgo = 5 - index;
        final now = DateTime.now();
        final targetMonth = now.month - monthsAgo;
        final targetYear = now.year + (targetMonth - 1) ~/ 12;
        final normalizedMonth = ((targetMonth - 1) % 12) + 1;
        const monthNames = ['Январ', 'Феврал', 'Март', 'Апрел', 'Май', 'Июн', 'Июл', 'Август', 'Сентябр', 'Октябр', 'Ноябр', 'Декабр'];
        
        return {
          'title': monthNames[normalizedMonth - 1],
          'subtitle': targetYear.toString(),
        };
        
      case ExpenseFilter.year:
        final monthsAgo = 11 - index;
        final now = DateTime.now();
        final targetMonth = now.month - monthsAgo;
        final targetYear = now.year + (targetMonth - 1) ~/ 12;
        final normalizedMonth = ((targetMonth - 1) % 12) + 1;
        const monthNames = ['Январ', 'Феврал', 'Март', 'Апрел', 'Май', 'Июн', 'Июл', 'Август', 'Сентябр', 'Октябр', 'Ноябр', 'Декабр'];
        
        return {
          'title': monthNames[normalizedMonth - 1],
          'subtitle': '$targetYear',
        };
    }
  }

  List<DailyExpense> _getFilteredExpenses(List<DailyExpense> allExpenses) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedFilter) {
      case ExpenseFilter.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case ExpenseFilter.month:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case ExpenseFilter.sixMonths:
        startDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case ExpenseFilter.year:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
    }

    return allExpenses.where((expense) {
      return expense.expenseDate.isAfter(startDate) || 
             expense.expenseDate.isAtSameMomentAs(startDate);
    }).toList();
  }

  Widget _buildExpensesList(DailyExpenseProvider provider) {
    final filteredExpenses = _getFilteredExpenses(provider.expenses);
    final groupedExpenses = _groupExpensesByDate(filteredExpenses);
    
    if (filteredExpenses.isEmpty) {
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
            'Дар ин давра харочоте нест',
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

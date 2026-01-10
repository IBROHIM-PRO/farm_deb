// lib/screens/debt/simple_debts_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/person.dart';
import '../../models/debt.dart';
import 'debt_transaction_history_screen.dart';
import 'add_debt_screen.dart';
import 'person_debt_history_screen.dart';

class SimpleDebtsScreen extends StatelessWidget {
  const SimpleDebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Идоракунии қарзҳо'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddDebtScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final debts = provider.debts;

          if (debts.isEmpty) {
            return _buildEmptyState(context);
          }

          // Group debts by person name
          final groupedDebts = <String, List<Debt>>{};
          for (final debt in debts) {
            final personName = provider.getPersonById(debt.personId)?.fullName ?? 'Unknown';
            groupedDebts.putIfAbsent(personName, () => []).add(debt);
          }

          final personNames = groupedDebts.keys.toList()..sort();

          return Column(
            children: [
              _buildSummaryCard(provider),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: personNames.length,
                  itemBuilder: (context, index) {
                    final personName = personNames[index];
                    final personDebts = groupedDebts[personName]!;
                    return _buildPersonCard(context, personName, personDebts, provider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------- EMPTY STATE ----------------
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Ҳанӯз ҳеҷ қарз сабт нашудааст',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),          
        ],
      ),
    );
  }

  // ---------------- SUMMARY ----------------
  Widget _buildSummaryCard(AppProvider provider) {
    final totals = provider.getDebtTotalsByCurrency();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ҷамъбасти қарзҳо',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...totals.entries.map(
            (e) => _buildSummaryRow(e.key, e.value),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String currency, Map<String, double> amounts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(currency, style: const TextStyle(fontWeight: FontWeight.w600)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Додашуда: ${(amounts['given'] ?? 0.0).toStringAsFixed(2)}',
                style: TextStyle(color: Colors.green[700], fontSize: 13),
              ),
              Text(
                'Гирифташуда: ${(amounts['taken'] ?? 0.0).toStringAsFixed(2)}',
                style: TextStyle(color: Colors.red[700], fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- PERSON CARD ----------------
  Widget _buildPersonCard(BuildContext context, String personName, List<Debt> debts, AppProvider provider) {
    // Calculate totals for this person
    double totalGiven = 0.0;
    double totalTaken = 0.0;
    double remainingGiven = 0.0;
    double remainingTaken = 0.0;
    
    for (final debt in debts) {
      if (debt.type == DebtType.given) {
        totalGiven += debt.totalAmount;
        remainingGiven += debt.remainingAmount;
      } else {
        totalTaken += debt.totalAmount;
        remainingTaken += debt.remainingAmount;
      }
    }
    
    final activeCount = debts.where((d) => d.status == DebtStatus.active).length;
    final latestDate = debts.isEmpty 
        ? DateTime.now() 
        : debts.map((d) => d.date).reduce((a, b) => a.isAfter(b) ? a : b);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _navigateToPersonHistory(context, personName),
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.person, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            personName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Санаи охирин: ${DateFormat('dd/MM/yyyy').format(latestDate)}',
                            style: TextStyle(
                              fontSize: 12,
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
                      color: activeCount > 0 ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$activeCount фаъол',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: activeCount > 0 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (remainingGiven > 0) ...[
                      Column(
                        children: [
                          Text(
                            '${remainingGiven.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'Додашуда',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (remainingGiven > 0 && remainingTaken > 0) 
                      Container(height: 30, width: 1, color: Colors.grey[300]),
                    if (remainingTaken > 0) ...[
                      Column(
                        children: [
                          Text(
                            '${remainingTaken.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            'Гирифташуда',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (remainingGiven == 0 && remainingTaken == 0) ...[
                      Column(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          Text(
                            'Пардохташуда',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPersonHistory(BuildContext context, String personName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonDebtHistoryScreen(
          personName: personName,
        ),
      ),
    );
  }

  // ---------------- DEBT CARD ----------------
  Widget _buildDebtCard(
      BuildContext context, Debt debt, AppProvider provider) {
    final person = provider.getPersonById(debt.personId);
    if (person == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DebtTransactionHistoryScreen(debt: debt),
            ),
          );
        },
        onLongPress: () {
          final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
          if (settingsProvider.editDeleteEnabled) {
            _showDebtOptions(context, debt, provider);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      person.fullName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, _) {
                      if (settingsProvider.editDeleteEnabled) {
                        return PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (value) {
                            if (value == 'edit') {
                              // Debt editing - show message for now
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Барои таҳрир кардани қарз, ба тафсилоти қарз гузаред'),
                                ),
                              );
                            } else if (value == 'delete') {
                              _confirmDeleteDebt(context, debt, provider);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Таҳрир'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Нест кардан', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return _buildStatusChip(debt);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _info('Намуди қарз:', debt.typeDisplay),
              _info('Маблағи умумӣ:',
                  '${debt.totalAmount.toStringAsFixed(2)} ${debt.currency}'),
              _info('Боқӣ мондааст:',
                  '${debt.remainingAmount.toStringAsFixed(2)} ${debt.currency}'),
              _info('Сана:',
                  '${debt.date.day}/${debt.date.month}/${debt.date.year}'),
            ],
          ),
        ),
      ),
    );
  }

  void _showDebtOptions(BuildContext context, Debt debt, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Таҳрир'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Барои таҳрир кардани қарз, ба тафсилоти қарз гузаред'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Нест кардан', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteDebt(context, debt, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDebt(BuildContext context, Debt debt, AppProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Тасдиқ кунед'),
        content: const Text('Шумо мутмаин ҳастед, ки мехоҳед ин қарзро нест кунед? Ин амал бозгашт карда намешавад.'),
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

    if (confirm == true && context.mounted) {
      try {
        await provider.deleteDebt(debt.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Қарз бомуваффақият нест карда шуд')),
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
  }

  Widget _buildStatusChip(Debt debt) {
    final active = debt.status == DebtStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.orange[100] : Colors.green[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        debt.statusDisplay,
        style: TextStyle(
          color: active ? Colors.orange[800] : Colors.green[800],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ---------------- PAYMENT ----------------
  void _showPaymentDialog(BuildContext context, Debt debt) {
    final controller = TextEditingController();
    final key = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Пардохт'),
        content: Form(
          key: key,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Маблағ',
              suffixText: debt.currency,
            ),
            validator: (v) {
              final a = double.tryParse(v ?? '');
              if (a == null || a <= 0) return 'Нодуруст';
              if (a > debt.remainingAmount) return 'Аз боқимонда зиёд';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Бекор')),
          ElevatedButton(
            onPressed: () async {
              if (key.currentState?.validate() ?? false) {
                await ctx.read<AppProvider>().makePayment(
                      debt: debt,
                      amount: double.parse(controller.text),
                    );
                Navigator.pop(ctx); // танҳо диалог пӯшида мешавад
              }
            },
            child: const Text('Пардохт'),
          ),
        ],
      ),
    );
  }
}

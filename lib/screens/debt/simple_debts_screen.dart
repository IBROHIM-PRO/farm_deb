// lib/screens/debt/simple_debts_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../models/person.dart';
import '../../models/debt.dart';
import 'debt_transaction_history_screen.dart';
import 'add_debt_screen.dart';

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

          return Column(
            children: [
              _buildSummaryCard(provider),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: debts.length,
                  itemBuilder: (context, index) =>
                      _buildDebtCard(context, debts[index], provider),
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddDebtScreen()),
              );
            },
            child: const Icon(Icons.add),
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
                'Додашуда: ${amounts['given']!.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.green[700], fontSize: 13),
              ),
              Text(
                'Гирифташуда: ${amounts['taken']!.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.red[700], fontSize: 13),
              ),
            ],
          ),
        ],
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
                  _buildStatusChip(debt),
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
              if (key.currentState!.validate()) {
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

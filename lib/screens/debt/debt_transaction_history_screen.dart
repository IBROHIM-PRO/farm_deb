import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/app_provider.dart';
import '../../models/debt.dart';
import '../../models/person.dart';
import '../../models/payment.dart';

class DebtTransactionHistoryScreen extends StatefulWidget {
  final Debt debt;

  const DebtTransactionHistoryScreen({super.key, required this.debt});

  @override
  State<DebtTransactionHistoryScreen> createState() =>
      _DebtTransactionHistoryScreenState();
}

class _DebtTransactionHistoryScreenState
    extends State<DebtTransactionHistoryScreen> {
  late Person _person;
  List<Payment> _payments = [];
  List<_TransactionEntry> _timeline = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<AppProvider>();

    _person = provider.getPersonById(widget.debt.personId)!;
    _payments = await provider.getPaymentsByDebtId(widget.debt.id!);

    _buildTimeline();
    setState(() {});
  }

  void _buildTimeline() {
    _timeline.clear();

    // Сабти аввали қарз
    _timeline.add(
      _TransactionEntry(
        type: _TransactionType.debtCreated,
        date: widget.debt.date,
        amount: widget.debt.totalAmount,
        currency: widget.debt.currency,
        runningBalance: widget.debt.totalAmount,
        debtType: widget.debt.type,
        description: 'Қарз сабт шуд',
      ),
    );

    double runningBalance = widget.debt.totalAmount;

    for (final payment in _payments.reversed) {
      runningBalance -= payment.amount;

      _timeline.add(
        _TransactionEntry(
          type: _TransactionType.payment,
          date: payment.date,
          amount: payment.amount,
          currency: widget.debt.currency,
          runningBalance: runningBalance,
          debtType: widget.debt.type,
          description: 'Пардохт',
          isPayment: true,
        ),
      );
    }

    _timeline.sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.debt.type == DebtType.given ? Colors.green : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Таърихи муомилот'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildPersonCard(),
          _buildDebtSummary(),
          Expanded(child: _buildTimelineView()),
        ],
      ),
    );
  }

  Widget _buildPersonCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: widget.debt.type == DebtType.given
              ? Colors.green[100]
              : Colors.blue[100],
          child: Icon(
            Icons.person,
            color: widget.debt.type == DebtType.given
                ? Colors.green
                : Colors.blue,
          ),
        ),
        title: Text(_person.fullName),
        subtitle: _person.phone != null && _person.phone!.isNotEmpty
            ? Text(_person.phone!)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Намуди қарз
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (widget.debt.type == DebtType.given
                        ? Colors.green
                        : Colors.blue)[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.debt.type == DebtType.given ? 'Додашуда' : 'Гирифташуда',
                style: TextStyle(
                  color: widget.debt.type == DebtType.given
                      ? Colors.green[800]
                      : Colors.blue[800],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Тугмаи пардохт (+)
            if (widget.debt.remainingAmount > 0)
              FloatingActionButton(
                mini: true,
                backgroundColor: Colors.green,
                child: const Icon(Icons.add),
                onPressed: () => _showPaymentDialog(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.debt.type == DebtType.given ? Colors.green : Colors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _summaryItem(
            'Умумӣ',
            '${widget.debt.totalAmount.toStringAsFixed(2)} ${widget.debt.currency}',
          ),
          _summaryItem(
            'Боқимонда',
            '${widget.debt.remainingAmount.toStringAsFixed(2)} ${widget.debt.currency}',
          ),
          _summaryItem(
            'Пардохт',
            '${(widget.debt.totalAmount - widget.debt.remainingAmount).toStringAsFixed(2)} ${widget.debt.currency}',
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineView() {
    if (_timeline.isEmpty) return const Center(child: Text('Маълумот нест'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _timeline.length,
      itemBuilder: (context, index) {
        final entry = _timeline[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              entry.isPayment ? Icons.payment : Icons.assignment,
              color: entry.isPayment ? Colors.red : Colors.green,
            ),
            title: Text(entry.description),
            subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(entry.date)),
            trailing: Text(
              '${entry.isPayment ? '-' : '+'}${entry.amount.toStringAsFixed(2)} ${entry.currency}',
              style: TextStyle(
                color: entry.isPayment ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPaymentDialog(BuildContext context) async {
    final amountController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Пардохт'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Боқимонда: ${widget.debt.remainingAmount.toStringAsFixed(2)} ${widget.debt.currency}',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Боқимондаро ба TextField ворид мекунад
                    amountController.text =
                        widget.debt.remainingAmount.toStringAsFixed(2);
                  },
                  child: const Text('Ворид кардан'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Маблағ'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Бекор'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null ||
                  amount <= 0 ||
                  amount > widget.debt.remainingAmount) return;

              await ctx.read<AppProvider>().makePayment(
                    debt: widget.debt,
                    amount: amount,
                  );

              Navigator.pop(ctx, true);
            },
            child: const Text('Сабт'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }
}

enum _TransactionType { debtCreated, payment }

class _TransactionEntry {
  final _TransactionType type;
  final DateTime date;
  final double amount;
  final String currency;
  final String description;
  final double runningBalance;
  final DebtType debtType;
  final bool isPayment;

  _TransactionEntry({
    required this.type,
    required this.date,
    required this.amount,
    required this.currency,
    required this.description,
    required this.runningBalance,
    required this.debtType,
    this.isPayment = false,
  });
}

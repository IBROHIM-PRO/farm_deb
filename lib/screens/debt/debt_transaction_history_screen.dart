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
    late Debt _currentDebt;
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
      
      // Reload debt from database to get updated amounts
      final updatedDebt = await provider.getDebtById(widget.debt.id!);
      if (updatedDebt != null) {
        _currentDebt = updatedDebt;
      } else {
        _currentDebt = widget.debt;
      }
      
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
          date: _currentDebt.date,
          amount: _currentDebt.totalAmount,
          currency: _currentDebt.currency,
          runningBalance: _currentDebt.totalAmount,
          debtType: _currentDebt.type,
          description: 'Қарз сабт шуд',
        ),
      );

      double runningBalance = _currentDebt.totalAmount;

      for (final payment in _payments.reversed) {
        runningBalance -= payment.amount;

        _timeline.add(
          _TransactionEntry(
            type: _TransactionType.payment,
            date: payment.date,
            amount: payment.amount,
            currency: _currentDebt.currency,
            runningBalance: runningBalance,
            debtType: _currentDebt.type,
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
          _currentDebt.type == DebtType.given ? Colors.green : Colors.blue;

      return Scaffold(
        appBar: AppBar(
          title: Text(_person.fullName),
          backgroundColor: color,
          foregroundColor: Colors.white,
          centerTitle: true,
          actions: [
            if (_currentDebt.remainingAmount > 0)
              IconButton(
                onPressed: () => _showPaymentDialog(context), 
                icon: const Icon(Icons.add),
                tooltip: 'Пардохт',
              ),
          ],
        ),
        backgroundColor: Colors.grey[100],
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [        
                _buildDebtSummary(),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 250,
                  child: _buildTimelineView(),
                ),
              ],
            ),
          ),
        ),
      );
    }  

    Widget _buildDebtSummary() {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _currentDebt.type == DebtType.given ? Colors.green : Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _summaryItem(
              'Умумӣ',
              '${_currentDebt.totalAmount.toStringAsFixed(2)} ${_currentDebt.currency}',
            ),
            _summaryItem(
              'Боқимонда',
              '${_currentDebt.remainingAmount.toStringAsFixed(2)} ${_currentDebt.currency}',
            ),
            _summaryItem(
              'Пардохт',
              '${(_currentDebt.totalAmount - _currentDebt.remainingAmount).toStringAsFixed(2)} ${_currentDebt.currency}',
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
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
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
                  '${entry.isPayment ? '-' : '+'}${entry.amount.toStringAsFixed(3)} ${entry.currency}',
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
                      'Боқимонда: ${_currentDebt.remainingAmount.toStringAsFixed(2)} ${_currentDebt.currency}',
                    ),
                  ),                
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Маблағ'),
              ),
              TextButton(
                    onPressed: () {
                      // Боқимондаро ба TextField ворид мекунад
                      amountController.text =
                          _currentDebt.remainingAmount.toStringAsFixed(2);
                    },
                    child: const Text('Ворид кардан'),
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
                    amount > _currentDebt.remainingAmount) return;

                await ctx.read<AppProvider>().makePayment(
                      debt: _currentDebt,
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

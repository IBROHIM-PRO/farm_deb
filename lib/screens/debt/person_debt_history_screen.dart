import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/debt.dart';
import 'debt_transaction_history_screen.dart';

/// Person Debt History Screen
/// Shows all debts (both given and taken) for a specific person
class PersonDebtHistoryScreen extends StatefulWidget {
  final String personName;

  const PersonDebtHistoryScreen({
    super.key,
    required this.personName,
  });

  @override
  State<PersonDebtHistoryScreen> createState() => _PersonDebtHistoryScreenState();
}

class _PersonDebtHistoryScreenState extends State<PersonDebtHistoryScreen> {
  List<Debt> _debts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPersonDebts();
  }

  Future<void> _loadPersonDebts() async {
    setState(() => _isLoading = true);
    
    try {
      final debts = await context.read<AppProvider>().getDebtsByPersonName(widget.personName);
      setState(() {
        _debts = debts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Хатогӣ дар боркунии маълумот: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Таърихи қарз', style: TextStyle(fontSize: 18)),
            Text(
              widget.personName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _debts.isEmpty
              ? _buildEmptyState()
              : _buildDebtsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Ҳеҷ қарз ёфт нашуд',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Барои ин шахс ягон қарз сабт нашудааст',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDebtsList() {
    // Separate debts by type
    final givenDebts = _debts.where((d) => d.type == DebtType.given).toList();
    final takenDebts = _debts.where((d) => d.type == DebtType.taken).toList();

    // Calculate totals
    final totalGiven = givenDebts.fold(0.0, (sum, debt) => sum + debt.totalAmount);
    final totalTaken = takenDebts.fold(0.0, (sum, debt) => sum + debt.totalAmount);
    final remainingGiven = givenDebts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);
    final remainingTaken = takenDebts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);

    return Column(
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.personName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Таърихи қарз',
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
                  const Divider(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Додашуда',
                          '${remainingGiven.toStringAsFixed(0)} TJS',
                          Icons.arrow_upward,
                          Colors.green,
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Гирифташуда',
                          '${remainingTaken.toStringAsFixed(0)} TJS',
                          Icons.arrow_downward,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Debts List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _debts.length,
            itemBuilder: (context, index) {
              final debt = _debts[index];
              return _buildDebtCard(debt);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDebtCard(Debt debt) {
    final isGiven = debt.type == DebtType.given;
    final color = isGiven ? Colors.green : Colors.red;
    final typeText = isGiven ? 'Додашуда' : 'Гирифташуда';
    final icon = isGiven ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debt Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          DateFormat('dd.MM.yyyy').format(debt.date),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: debt.status == DebtStatus.active 
                            ? color.withOpacity(0.1) 
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        debt.status == DebtStatus.active ? 'Фаъол' : 'Пардохташуда',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: debt.status == DebtStatus.active ? color : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Amount Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ҳамагӣ маблағ:',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${debt.totalAmount.toStringAsFixed(0)} ${debt.currency}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Боқимонда:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${debt.remainingAmount.toStringAsFixed(0)} ${debt.currency}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: debt.status == DebtStatus.active ? color : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Progress Bar (if active)
            if (debt.status == DebtStatus.active && debt.totalAmount > 0) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (debt.totalAmount - debt.remainingAmount) / debt.totalAmount,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ],

            // Payment and Details Buttons
            const SizedBox(height: 12),
            Row(
              children: [
                if (debt.status == DebtStatus.active) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showPaymentDialog(debt),
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Пардохт'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToTransactionHistory(debt),
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('Таърихи муомилот'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      padding: const EdgeInsets.symmetric(vertical: 8),
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

  void _showPaymentDialog(Debt debt) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Пардохти қарз'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Боқимонда: ${debt.remainingAmount.toStringAsFixed(0)} ${debt.currency}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Маблағи пардохт (${debt.currency})',
                  prefixIcon: const Icon(Icons.money),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v?.isEmpty == true) return 'Зарур аст';
                  final amount = double.tryParse(v!);
                  if (amount == null || amount <= 0) return 'Маблағи дуруст ворид кунед';
                  if (amount > debt.remainingAmount) return 'Аз боқимонда зиёд аст';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Бекор'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  await context.read<AppProvider>().makePayment(
                    debt: debt,
                    amount: double.parse(controller.text),
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Пардохт муваффақият амалӣ шуд'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadPersonDebts(); // Reload debts to show updated amounts
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Хатогӣ дар пардохт: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Пардохт кардан'),
          ),
        ],
      ),
    );
  }

  void _navigateToTransactionHistory(Debt debt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DebtTransactionHistoryScreen(debt: debt),
      ),
    );
  }
}

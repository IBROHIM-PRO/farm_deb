import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/person.dart';
import '../../models/debt.dart';
import 'debt_transaction_history_screen.dart';

/// Simple Debt Management Screen - Exactly as per theoretical design
/// Displays all debts with: total amount, remaining amount, currency, type, status
class SimpleDebtsScreen extends StatelessWidget {
  const SimpleDebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Идоракунии қарзҳо'),
        centerTitle: true,
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
                  itemBuilder: (context, index) => _buildDebtCard(context, debts[index], provider),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "simple_debts_fab",
        onPressed: () => _showAddDebtDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Илова кардани қарз'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Ҳанӯз ҳеҷ қарз сабт нашудааст', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddDebtDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Илова кардани қарз'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AppProvider provider) {
    final totals = provider.getDebtTotalsByCurrency();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ҷамъбасти қарзҳо', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...totals.entries.map((entry) => _buildSummaryRow(entry.key, entry.value)),
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
          Text('$currency:', style: TextStyle(fontWeight: FontWeight.w600)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Додашуда: ${amounts['given']!.toStringAsFixed(2)}', 
                   style: TextStyle(color: Colors.green[700], fontSize: 13)),
              Text('Гирифташуда: ${amounts['taken']!.toStringAsFixed(2)}', 
                   style: TextStyle(color: Colors.red[700], fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, Debt debt, AppProvider provider) {
    final person = provider.getPersonById(debt.personId);
    if (person == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => DebtTransactionHistoryScreen(debt: debt))
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    person.fullName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: debt.status == DebtStatus.active ? Colors.orange[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    debt.statusDisplay,
                    style: TextStyle(
                      color: debt.status == DebtStatus.active ? Colors.orange[800] : Colors.green[800],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Core debt info as per theoretical design
            _buildDebtInfoRow('Намуди қарз:', debt.typeDisplay),
            _buildDebtInfoRow('Маблағи умумӣ:', '${debt.totalAmount.toStringAsFixed(2)} ${debt.currency}'),
            _buildDebtInfoRow('Боқӣ мондааст:', '${debt.remainingAmount.toStringAsFixed(2)} ${debt.currency}'),
            _buildDebtInfoRow('Асъор:', debt.currency),
            _buildDebtInfoRow('Сана:', '${debt.date.day}/${debt.date.month}/${debt.date.year}'),
            
            if (debt.status == DebtStatus.active && debt.remainingAmount > 0) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showPaymentDialog(context, debt),
                icon: const Icon(Icons.payment, size: 16),
                label: const Text('Пардохт'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebtInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showAddDebtDialog(BuildContext context) {
    final personController = TextEditingController();
    final amountController = TextEditingController();
    final currencyController = TextEditingController(text: 'сомонӣ');
    DebtType selectedType = DebtType.given;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Илова кардани қарз'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Person selection/entry
                Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    return DropdownButtonFormField<Person>(
                      decoration: const InputDecoration(
                        labelText: 'Шахс',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<Person>(
                          value: null,
                          child: Text('+ Шахси нав илова кунед'),
                        ),
                        ...provider.persons.map((person) => DropdownMenuItem(
                          value: person,
                          child: Text(person.fullName),
                        )),
                      ],
                      onChanged: (person) {
                        if (person == null) {
                          _showAddPersonDialog(context);
                        }
                      },
                      validator: (value) => value == null ? 'Шахсро интихоб кунед' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                
                // Amount
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Маблағ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    if (amount == null || amount <= 0) return 'Маблағи дуруст ворид кунед';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Currency
                TextFormField(
                  controller: currencyController,
                  decoration: const InputDecoration(
                    labelText: 'Асъор',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.trim().isEmpty == true ? 'Асъор зарур аст' : null,
                ),
                const SizedBox(height: 16),
                
                // Type
                DropdownButtonFormField<DebtType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Намуди қарз',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: DebtType.given, child: Text('Додашуда')),
                    DropdownMenuItem(value: DebtType.taken, child: Text('Гирифташуда')),
                  ],
                  onChanged: (type) => selectedType = type!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Бекор кардан'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Implementation would need person selection logic
                Navigator.pop(ctx);
              }
            },
            child: const Text('Сабт кардан'),
          ),
        ],
      ),
    );
  }

  void _showAddPersonDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Илова кардани шахс'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Номи пурра'),
                validator: (v) => Person.validate(v ?? ''),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Телефон (ихтиёрӣ)'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Бекор кардан'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await ctx.read<AppProvider>().addPerson(Person(
                  fullName: nameController.text.trim(),
                  phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Илова кардан'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Debt debt) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Пардохт'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Боқӣ мондааст: ${debt.remainingAmount.toStringAsFixed(2)} ${debt.currency}',
                   style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Маблағи пардохт',
                  suffixText: debt.currency,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) return 'Маблағи дуруст ворид кунед';
                  if (amount > debt.remainingAmount) return 'Аз боқимонда зиёд';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Бекор кардан'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await ctx.read<AppProvider>().makePayment(
                    debt: debt,
                    amount: double.parse(amountController.text),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пардохт бо муваффақият сабт шуд')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Хатогӣ: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Пардохт', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

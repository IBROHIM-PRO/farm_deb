import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/debt.dart';
import 'add_debt_screen.dart';
import 'debt_detail_screen.dart';
import 'person_debt_history_screen.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  DebtType? _filter;
  bool _showOnlyActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debts'),
        actions: [
          IconButton(
            icon: Icon(_showOnlyActive ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _showOnlyActive = !_showOnlyActive),
          ),
          PopupMenuButton<DebtType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All')),
              const PopupMenuItem(value: DebtType.given, child: Text('Given')),
              const PopupMenuItem(value: DebtType.taken, child: Text('Taken')),
            ],
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          var debts = provider.debts;
          if (_filter != null) debts = debts.where((d) => d.type == _filter).toList();
          if (_showOnlyActive) debts = debts.where((d) => d.status == DebtStatus.active).toList();

          if (debts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No debts found', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDebtScreen())), icon: const Icon(Icons.add), label: const Text('Add Debt')),
                ],
              ),
            );
          }

          // Group debts by person name
          final groupedDebts = <String, List<Debt>>{};
          for (final debt in debts) {
            final person = provider.getPersonById(debt.personId);
            final personName = person?.fullName ?? 'Unknown';
            groupedDebts.putIfAbsent(personName, () => []).add(debt);
          }

          final personNames = groupedDebts.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: personNames.length,
            itemBuilder: (context, index) {
              final personName = personNames[index];
              final personDebts = groupedDebts[personName]!;
              return _buildPersonCard(provider, personName, personDebts);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(heroTag: "debts_fab", onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDebtScreen())), child: const Icon(Icons.add)),
    );
  }

  Widget _buildPersonCard(AppProvider provider, String personName, List<Debt> debts) {
    // Calculate totals for this person
    double totalGiven = 0.0;
    double totalTaken = 0.0;
    double totalRemainingGiven = 0.0;
    double totalRemainingTaken = 0.0;
    final latestDate = debts.map((d) => d.date).reduce((a, b) => a.isAfter(b) ? a : b);
    
    for (final debt in debts) {
      if (debt.type == DebtType.given) {
        totalGiven += debt.totalAmount;
        totalRemainingGiven += debt.remainingAmount;
      } else {
        totalTaken += debt.totalAmount;
        totalRemainingTaken += debt.remainingAmount;
      }
    }

    final givenDebts = debts.where((d) => d.type == DebtType.given).length;
    final takenDebts = debts.where((d) => d.type == DebtType.taken).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToPersonHistory(personName),
        borderRadius: BorderRadius.circular(12),
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
                            'Охирин амал: ${DateFormat('dd/MM/yyyy').format(latestDate)}',
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
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${debts.length} қарз',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.purple,
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
                child: Column(
                  children: [
                    if (givenDebts > 0) ...[
                      Row(
                        children: [
                          Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Додашуда ($givenDebts)',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '${totalRemainingGiven.toStringAsFixed(0)} TJS',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      if (takenDebts > 0) const SizedBox(height: 8),
                    ],
                    if (takenDebts > 0) ...[
                      Row(
                        children: [
                          Icon(Icons.arrow_downward, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Гирифташуда ($takenDebts)',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '${totalRemainingTaken.toStringAsFixed(0)} TJS',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ҳамагӣ боқимонда:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${(totalRemainingGiven + totalRemainingTaken).toStringAsFixed(0)} TJS',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPersonHistory(String personName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonDebtHistoryScreen(
          personName: personName,
        ),
      ),
    );
  }
}

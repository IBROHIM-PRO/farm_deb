import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/debt.dart';
import 'add_debt_screen.dart';
import 'debt_detail_screen.dart';

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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: debts.length,
            itemBuilder: (context, index) {
              final debt = debts[index];
              final person = provider.getPersonById(debt.personId);
              final isGiven = debt.type == DebtType.given;
              final color = isGiven ? Colors.green : Colors.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DebtDetailScreen(debt: debt))),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(isGiven ? Icons.arrow_upward : Icons.arrow_downward, color: color)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(person?.fullName ?? 'Unknown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(DateFormat('MMM dd, yyyy').format(debt.date), style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(isGiven ? 'Given' : 'Taken', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))),
                                if (debt.status == DebtStatus.repaid)
                                  Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Text('Repaid', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total: ${debt.totalAmount.toStringAsFixed(2)} ${debt.currency}'),
                            Text('Remaining: ${debt.remainingAmount.toStringAsFixed(2)} ${debt.currency}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (debt.status == DebtStatus.active) ...[
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: (debt.totalAmount - debt.remainingAmount) / debt.totalAmount, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(color)),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(heroTag: "debts_fab", onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDebtScreen())), child: const Icon(Icons.add)),
    );
  }
}

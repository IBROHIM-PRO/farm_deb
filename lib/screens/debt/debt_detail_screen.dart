import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/debt.dart';
import '../../models/payment.dart';

class DebtDetailScreen extends StatefulWidget {
  final Debt debt;
  const DebtDetailScreen({super.key, required this.debt});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  late Debt _debt;
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _debt = widget.debt;
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    _payments = await context.read<AppProvider>().getPaymentsForDebt(_debt.id!);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final person = provider.getPersonById(_debt.personId);
    final isGiven = _debt.type == DebtType.given;
    final color = isGiven ? Colors.green : Colors.red;
    final isRepaid = _debt.status == DebtStatus.repaid;

    return Scaffold(
      appBar: AppBar(title: const Text('Debt Details'), actions: [if (!isRepaid) IconButton(icon: const Icon(Icons.delete), onPressed: () => _showDeleteConfirm(context))]),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.1), child: Icon(isGiven ? Icons.arrow_upward : Icons.arrow_downward, color: color, size: 32)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(person?.fullName ?? 'Unknown', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(isGiven ? 'Given' : 'Taken', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))), if (isRepaid) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Text('Repaid', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)))])])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildAmountRow('Total', _debt.totalAmount, _debt.currency),
                  const Divider(height: 24),
                  _buildAmountRow('Paid', _debt.totalAmount - _debt.remainingAmount, _debt.currency, color: Colors.green),
                  const Divider(height: 24),
                  _buildAmountRow('Remaining', _debt.remainingAmount, _debt.currency, color: isRepaid ? Colors.grey : Colors.orange, isBold: true),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: (_debt.totalAmount - _debt.remainingAmount) / _debt.totalAmount, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(color)),
                  const SizedBox(height: 8),
                  Text('${((_debt.totalAmount - _debt.remainingAmount) / _debt.totalAmount * 100).toStringAsFixed(1)}% paid', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Payment History', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), Text('${_payments.length} payments')]),
                  const SizedBox(height: 16),
                  if (_payments.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No payments yet')))
                  else ..._payments.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.green, size: 16)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${p.amount.toStringAsFixed(2)} ${_debt.currency}', style: const TextStyle(fontWeight: FontWeight.bold)), Text(DateFormat('MMM dd, yyyy', 'en_US').format(p.paymentDateTime), style: Theme.of(context).textTheme.bodySmall), if (p.note != null) Text(p.note!, style: Theme.of(context).textTheme.bodySmall)]))]),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isRepaid ? null : FloatingActionButton.extended(heroTag: "debt_detail_fab", onPressed: () => _showPaymentDialog(context), icon: const Icon(Icons.payment), label: const Text('Record Payment'), backgroundColor: color, foregroundColor: Colors.white),
    );
  }

  Widget _buildAmountRow(String label, double amount, String currency, {Color? color, bool isBold = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text('${amount.toStringAsFixed(2)} $currency', style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color))]);
  }

  void _showPaymentDialog(BuildContext context) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Remaining: ${_debt.remainingAmount.toStringAsFixed(2)} ${_debt.currency}'),
            const SizedBox(height: 16),
            TextFormField(controller: amountController, decoration: InputDecoration(labelText: 'Amount', suffixText: _debt.currency), keyboardType: TextInputType.number, validator: (v) { if (v?.isEmpty == true) return 'Required'; final a = double.tryParse(v!); if (a == null || a <= 0) return 'Invalid'; if (a > _debt.remainingAmount) return 'Exceeds remaining'; return null; }),
            const SizedBox(height: 16),
            TextFormField(controller: noteController, decoration: const InputDecoration(labelText: 'Note (optional)')),
            TextButton(onPressed: () => amountController.text = _debt.remainingAmount.toStringAsFixed(2), child: const Text('Pay Full Amount')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (formKey.currentState!.validate()) {
              await ctx.read<AppProvider>().makePayment(debt: _debt, amount: double.parse(amountController.text));
              if (ctx.mounted) { Navigator.pop(ctx); final p = ctx.read<AppProvider>(); final updated = p.debts.firstWhere((d) => d.id == _debt.id, orElse: () => _debt); setState(() => _debt = updated); await _loadPayments(); }
            }
          }, child: const Text('Record')),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Debt'),
        content: const Text('Delete this debt?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () async { await ctx.read<AppProvider>().deleteDebt(_debt.id!); if (ctx.mounted) { Navigator.pop(ctx); Navigator.pop(ctx); } }, child: const Text('Delete')),
        ],
      ),
    );
  }
}

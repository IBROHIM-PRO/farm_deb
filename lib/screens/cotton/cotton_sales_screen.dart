import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/cotton_sale.dart';

class CottonSalesScreen extends StatelessWidget {
  const CottonSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cotton Sales')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.cottonSales.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.point_of_sale_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(height: 16), const Text('No sales recorded'), const SizedBox(height: 8), ElevatedButton.icon(onPressed: () => _showAddSaleDialog(context), icon: const Icon(Icons.add), label: const Text('Add Sale'))]));
          }

          final totalSales = provider.cottonSales.fold(0.0, (s, sale) => s + sale.totalAmount);
          final pendingPayments = provider.cottonSales.where((s) => s.paymentStatus != PaymentStatus.paid).fold(0.0, (s, sale) => s + sale.remainingAmount);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 16), Row(children: [Expanded(child: _buildSummaryItem(context, 'Total Sales', '${totalSales.toStringAsFixed(0)} TJS', Icons.attach_money, Colors.green)), const SizedBox(width: 12), Expanded(child: _buildSummaryItem(context, 'Pending', '${pendingPayments.toStringAsFixed(0)} TJS', Icons.pending, Colors.orange))])]))),
              const SizedBox(height: 16),
              ...provider.cottonSales.map((sale) => _buildSaleCard(context, sale)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(heroTag: "cotton_sales_fab", onPressed: () => _showAddSaleDialog(context), child: const Icon(Icons.add)),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 24), const SizedBox(height: 8), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)), Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color))]));
  }

  Widget _buildSaleCard(BuildContext context, CottonSale sale) {
    final statusColor = sale.paymentStatus == PaymentStatus.paid ? Colors.green : sale.paymentStatus == PaymentStatus.partial ? Colors.orange : Colors.red;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSaleDetails(context, sale),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: const Icon(Icons.point_of_sale, color: Colors.blue)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(sale.buyerName ?? 'Unknown Buyer', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), Text(DateFormat('MMM dd, yyyy').format(sale.date), style: Theme.of(context).textTheme.bodySmall)])), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(sale.paymentStatus.name[0].toUpperCase() + sale.paymentStatus.name.substring(1), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)))]),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(sale.saleType == SaleType.byWeight ? '${sale.weight?.toStringAsFixed(0)} kg' : '${sale.units} units', style: const TextStyle(fontWeight: FontWeight.bold)), Text('@ ${sale.pricePerUnit.toStringAsFixed(0)} ${sale.currency}/${sale.saleType == SaleType.byWeight ? 'kg' : 'unit'}', style: Theme.of(context).textTheme.bodySmall)])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${sale.totalAmount.toStringAsFixed(0)} ${sale.currency}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), if (sale.paymentStatus != PaymentStatus.paid) Text('Remaining: ${sale.remainingAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontSize: 12))])]),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaleDetails(BuildContext context, CottonSale sale) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Sale Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDetailRow('Buyer', sale.buyerName ?? 'Unknown'),
            _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(sale.date)),
            _buildDetailRow('Quantity', sale.saleType == SaleType.byWeight ? '${sale.weight?.toStringAsFixed(0)} kg' : '${sale.units} units'),
            _buildDetailRow('Total', '${sale.totalAmount.toStringAsFixed(0)} ${sale.currency}'),
            _buildDetailRow('Paid', '${sale.paidAmount.toStringAsFixed(0)} ${sale.currency}'),
            _buildDetailRow('Remaining', '${sale.remainingAmount.toStringAsFixed(0)} ${sale.currency}'),
            const SizedBox(height: 16),
            if (sale.paymentStatus != PaymentStatus.paid) SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(ctx); _showRecordPaymentDialog(context, sale); }, child: const Text('Record Payment'))),
          ]),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]));

  void _showRecordPaymentDialog(BuildContext context, CottonSale sale) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment'),
        content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Remaining: ${sale.remainingAmount.toStringAsFixed(0)} ${sale.currency}'), const SizedBox(height: 16), TextFormField(controller: amountController, decoration: InputDecoration(labelText: 'Amount', suffixText: sale.currency), keyboardType: TextInputType.number, validator: (v) { if (v?.isEmpty == true) return 'Required'; final a = double.tryParse(v!); if (a == null || a <= 0 || a > sale.remainingAmount) return 'Invalid'; return null; }), TextButton(onPressed: () => amountController.text = sale.remainingAmount.toStringAsFixed(0), child: const Text('Pay Full Amount'))])),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () async { if (formKey.currentState!.validate()) { final amount = double.parse(amountController.text); final newPaid = sale.paidAmount + amount; await ctx.read<AppProvider>().updateCottonSale(sale.copyWith(paidAmount: newPaid, paymentStatus: newPaid >= sale.totalAmount ? PaymentStatus.paid : PaymentStatus.partial)); if (ctx.mounted) Navigator.pop(ctx); } }, child: const Text('Record'))],
      ),
    );
  }

  void _showAddSaleDialog(BuildContext context) {
    final weightController = TextEditingController();
    final unitsController = TextEditingController();
    final priceController = TextEditingController();
    final buyerController = TextEditingController();
    final paidAmountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    SaleType saleType = SaleType.byWeight;
    DateTime date = DateTime.now();
    bool isInstallment = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Cotton Sale'),
          content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            SegmentedButton<SaleType>(segments: const [ButtonSegment(value: SaleType.byWeight, label: Text('By Weight')), ButtonSegment(value: SaleType.byUnits, label: Text('By Units'))], selected: {saleType}, onSelectionChanged: (s) => setState(() => saleType = s.first)),
            const SizedBox(height: 16),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today), title: Text(DateFormat('MMM dd, yyyy').format(date)), onTap: () async { final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now()); if (d != null) setState(() => date = d); }),
            const SizedBox(height: 8),
            if (saleType == SaleType.byWeight) TextFormField(controller: weightController, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: TextInputType.number, validator: (v) => saleType == SaleType.byWeight && v?.isEmpty == true ? 'Required' : null) else TextFormField(controller: unitsController, decoration: const InputDecoration(labelText: 'Units'), keyboardType: TextInputType.number, validator: (v) => saleType == SaleType.byUnits && v?.isEmpty == true ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: priceController, decoration: InputDecoration(labelText: 'Price per ${saleType == SaleType.byWeight ? 'kg' : 'unit'}', suffixText: 'TJS'), keyboardType: TextInputType.number, validator: (v) => v?.isEmpty == true ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: buyerController, decoration: const InputDecoration(labelText: 'Buyer Name')),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Pay in installments'),
              subtitle: const Text('Allow partial payment'),
              value: isInstallment,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) async {
                if (value) {
                  final confirmed = await showDialog<bool>(
                    context: ctx,
                    builder: (c) => AlertDialog(
                      title: const Text('Installment Payment'),
                      content: const Text('Do you want to enable installment payment for this sale?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
                        ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Yes')),
                      ],
                    ),
                  );
                  if (confirmed == true) setState(() => isInstallment = true);
                } else {
                  setState(() => isInstallment = false);
                }
              },
            ),
            if (isInstallment) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: paidAmountController,
                decoration: const InputDecoration(labelText: 'Initial Payment (TJS)', hintText: 'Enter amount paid now'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (isInstallment && v?.isNotEmpty == true) {
                    final paid = double.tryParse(v!);
                    if (paid == null || paid < 0) return 'Invalid amount';
                    final weight = saleType == SaleType.byWeight ? double.tryParse(weightController.text) ?? 0 : 0.0;
                    final units = saleType == SaleType.byUnits ? int.tryParse(unitsController.text) ?? 0 : 0;
                    final price = double.tryParse(priceController.text) ?? 0;
                    final total = saleType == SaleType.byWeight ? weight * price : units * price;
                    if (paid > total) return 'Exceeds total';
                  }
                  return null;
                },
              ),
            ],
          ]))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () async {
              if (formKey.currentState!.validate()) {
                final weight = saleType == SaleType.byWeight ? double.parse(weightController.text) : null;
                final units = saleType == SaleType.byUnits ? int.parse(unitsController.text) : null;
                final price = double.parse(priceController.text);
                final total = saleType == SaleType.byWeight ? weight! * price : units! * price;
                final paidAmount = isInstallment && paidAmountController.text.isNotEmpty ? double.parse(paidAmountController.text) : total;
                final paymentStatus = paidAmount >= total ? PaymentStatus.paid : (paidAmount > 0 ? PaymentStatus.partial : PaymentStatus.pending);
                await ctx.read<AppProvider>().addCottonSale(CottonSale(
                  date: date,
                  saleType: saleType,
                  weight: weight,
                  units: units,
                  pricePerUnit: price,
                  totalAmount: total,
                  paidAmount: paidAmount,
                  paymentStatus: paymentStatus,
                  buyerName: buyerController.text.isEmpty ? null : buyerController.text.trim(),
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              }
            }, child: const Text('Add')),
          ],
        ),
      ),
    );
  }
}

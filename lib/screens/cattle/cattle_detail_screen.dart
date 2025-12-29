import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/cattle.dart';
import '../../models/cattle_record.dart';
import '../../models/cattle_sale.dart';

class CattleDetailScreen extends StatelessWidget {
  final Cattle cattle;
  const CattleDetailScreen({super.key, required this.cattle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cattle.earTag),
        actions: [if (cattle.status == CattleStatus.active) PopupMenuButton<String>(onSelected: (v) { if (v == 'sell') _showSellDialog(context); else if (v == 'delete') _showDeleteConfirm(context); }, itemBuilder: (_) => [const PopupMenuItem(value: 'sell', child: Text('Sell Cattle')), const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red)))])],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final records = provider.getRecordsForCattle(cattle.id!);
          final sale = provider.getSaleForCattle(cattle.id!);
          final totalCost = provider.getTotalCattleCost(cattle.id!);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInfoCard(context, totalCost, sale),
              const SizedBox(height: 16),
              _buildWeightCard(context),
              const SizedBox(height: 16),
              if (sale != null) _buildSaleCard(context, sale),
              if (sale != null) const SizedBox(height: 16),
              _buildRecordsCard(context, records),
            ],
          );
        },
      ),
      floatingActionButton: cattle.status == CattleStatus.active ? FloatingActionButton(heroTag: "cattle_detail_fab", onPressed: () => _showAddRecordDialog(context), child: const Icon(Icons.add)) : null,
    );
  }

  Widget _buildInfoCard(BuildContext context, double totalCost, CattleSale? sale) {
    final statusColor = cattle.status == CattleStatus.active ? Colors.green : cattle.status == CattleStatus.sold ? Colors.blue : Colors.grey;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.brown.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(cattle.gender == CattleGender.male ? Icons.male : Icons.female, color: Colors.brown, size: 32)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(cattle.earTag, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), if (cattle.name != null) Text(cattle.name!), Text(cattle.breed ?? 'Unknown breed')])), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(cattle.status.name[0].toUpperCase() + cattle.status.name.substring(1), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)))]), const Divider(height: 24), _buildInfoRow('Purchase Date', DateFormat('MMM dd, yyyy').format(cattle.purchaseDate)), _buildInfoRow('Purchase Price', '${cattle.purchasePrice.toStringAsFixed(0)} ${cattle.currency}'), _buildInfoRow('Total Cost', '${totalCost.toStringAsFixed(0)} ${cattle.currency}'), if (sale != null) _buildInfoRow('Profit', '${(sale.totalAmount - totalCost).toStringAsFixed(0)} ${cattle.currency}', color: (sale.totalAmount - totalCost) >= 0 ? Colors.green : Colors.red)])));
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color))]));

  Widget _buildWeightCard(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Weight Tracking', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 16), Row(children: [Expanded(child: _buildWeightItem(context, 'Initial', '${cattle.initialWeight.toStringAsFixed(0)} ${cattle.weightUnit}', Colors.grey)), const SizedBox(width: 12), Expanded(child: _buildWeightItem(context, 'Current', '${cattle.currentWeight.toStringAsFixed(0)} ${cattle.weightUnit}', Colors.blue)), const SizedBox(width: 12), Expanded(child: _buildWeightItem(context, 'Gain', '${cattle.weightGain >= 0 ? '+' : ''}${cattle.weightGain.toStringAsFixed(0)} ${cattle.weightUnit}', cattle.weightGain >= 0 ? Colors.green : Colors.red))])])));
  }

  Widget _buildWeightItem(BuildContext context, String label, String value, Color color) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)), Text(label, style: TextStyle(color: color, fontSize: 12))]));

  Widget _buildSaleCard(BuildContext context, CattleSale sale) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Sale Information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 16), _buildInfoRow('Buyer', sale.buyerName ?? 'Unknown'), _buildInfoRow('Sale Date', DateFormat('MMM dd, yyyy').format(sale.saleDate)), _buildInfoRow('Weight', '${sale.weight.toStringAsFixed(0)} kg'), _buildInfoRow('Price/kg', '${sale.pricePerKg.toStringAsFixed(0)} ${sale.currency}'), _buildInfoRow('Total', '${sale.totalAmount.toStringAsFixed(0)} ${sale.currency}'), _buildInfoRow('Paid', '${sale.paidAmount.toStringAsFixed(0)} ${sale.currency}'), if (sale.remainingAmount > 0) _buildInfoRow('Remaining', '${sale.remainingAmount.toStringAsFixed(0)} ${sale.currency}', color: Colors.red)])));
  }

  Widget _buildRecordsCard(BuildContext context, List<CattleRecord> records) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Records', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), Text('${records.length} entries')]), const SizedBox(height: 16), if (records.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No records yet'))) else ...records.map((r) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(_getRecordIcon(r.type), size: 20), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.typeDisplayName, style: const TextStyle(fontWeight: FontWeight.bold)), Text(DateFormat('MMM dd, yyyy').format(r.date), style: const TextStyle(fontSize: 12)), if (r.description != null) Text(r.description!, style: const TextStyle(fontSize: 12))])), if (r.cost > 0) Text('${r.cost.toStringAsFixed(0)} TJS', style: const TextStyle(fontWeight: FontWeight.bold))])))])));
  }

  IconData _getRecordIcon(RecordType type) { switch (type) { case RecordType.feeding: return Icons.restaurant; case RecordType.medication: return Icons.medical_services; case RecordType.weighing: return Icons.scale; case RecordType.vaccination: return Icons.vaccines; case RecordType.other: return Icons.more_horiz; } }

  void _showAddRecordDialog(BuildContext context) {
    final costController = TextEditingController();
    final descController = TextEditingController();
    final weightController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    RecordType type = RecordType.feeding;
    DateTime date = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Record'),
          content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButtonFormField<RecordType>(value: type, decoration: const InputDecoration(labelText: 'Type'), items: RecordType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name[0].toUpperCase() + t.name.substring(1)))).toList(), onChanged: (v) { if (v != null) setState(() => type = v); }), const SizedBox(height: 16), if (type == RecordType.weighing) TextFormField(controller: weightController, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: TextInputType.number), const SizedBox(height: 16), TextFormField(controller: costController, decoration: const InputDecoration(labelText: 'Cost (TJS)'), keyboardType: TextInputType.number), const SizedBox(height: 16), TextFormField(controller: descController, decoration: const InputDecoration(labelText: 'Description'))]))),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () async { await ctx.read<AppProvider>().addCattleRecord(CattleRecord(cattleId: cattle.id!, type: type, date: date, cost: double.tryParse(costController.text) ?? 0, description: descController.text.isEmpty ? null : descController.text, weight: type == RecordType.weighing ? double.tryParse(weightController.text) : null)); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('Add'))],
        ),
      ),
    );
  }

  void _showSellDialog(BuildContext context) {
    final weightController = TextEditingController(text: cattle.currentWeight.toString());
    final priceController = TextEditingController();
    final buyerController = TextEditingController();
    final paidAmountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    CattleSaleType saleType = CattleSaleType.alive;
    bool isInstallment = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Sell Cattle'),
          content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            SegmentedButton<CattleSaleType>(segments: const [ButtonSegment(value: CattleSaleType.alive, label: Text('Alive')), ButtonSegment(value: CattleSaleType.slaughtered, label: Text('Slaughtered'))], selected: {saleType}, onSelectionChanged: (s) => setState(() => saleType = s.first)),
            const SizedBox(height: 16),
            TextFormField(controller: weightController, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: TextInputType.number, validator: (v) => v?.isEmpty == true ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: priceController, decoration: const InputDecoration(labelText: 'Price per kg (TJS)'), keyboardType: TextInputType.number, validator: (v) => v?.isEmpty == true ? 'Required' : null),
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
                    final weight = double.tryParse(weightController.text) ?? 0;
                    final price = double.tryParse(priceController.text) ?? 0;
                    if (paid > weight * price) return 'Exceeds total';
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
                final weight = double.parse(weightController.text);
                final price = double.parse(priceController.text);
                final total = weight * price;
                final paidAmount = isInstallment && paidAmountController.text.isNotEmpty ? double.parse(paidAmountController.text) : total;
                final paymentStatus = paidAmount >= total ? SalePaymentStatus.paid : (paidAmount > 0 ? SalePaymentStatus.partial : SalePaymentStatus.pending);
                await ctx.read<AppProvider>().addCattleSale(CattleSale(
                  cattleId: cattle.id!,
                  saleDate: DateTime.now(),
                  saleType: saleType,
                  weight: weight,
                  pricePerKg: price,
                  totalAmount: total,
                  paidAmount: paidAmount,
                  paymentStatus: paymentStatus,
                  buyerName: buyerController.text.isEmpty ? null : buyerController.text,
                ));
                if (ctx.mounted) { Navigator.pop(ctx); Navigator.pop(ctx); }
              }
            }, child: const Text('Sell')),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete Cattle'), content: const Text('Delete this cattle?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () async { await ctx.read<AppProvider>().deleteCattle(cattle.id!); if (ctx.mounted) { Navigator.pop(ctx); Navigator.pop(ctx); } }, child: const Text('Delete'))]));
  }
}

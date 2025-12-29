import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/cattle.dart';
import 'cattle_detail_screen.dart';

class CattleListScreen extends StatefulWidget {
  const CattleListScreen({super.key});

  @override
  State<CattleListScreen> createState() => _CattleListScreenState();
}

class _CattleListScreenState extends State<CattleListScreen> {
  bool _showOnlyActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cattle Management'),
        actions: [IconButton(icon: Icon(_showOnlyActive ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _showOnlyActive = !_showOnlyActive))],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final cattle = _showOnlyActive ? provider.activeCattle : provider.cattleList;

          if (cattle.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.pets_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(height: 16), Text(_showOnlyActive ? 'No active cattle' : 'No cattle registered'), const SizedBox(height: 8), ElevatedButton.icon(onPressed: () => _showAddCattleDialog(context), icon: const Icon(Icons.add), label: const Text('Add Cattle'))]));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: _buildSummaryItem(context, 'Active', provider.activeCattle.length.toString(), Icons.pets, Colors.green)), const SizedBox(width: 12), Expanded(child: _buildSummaryItem(context, 'Sold', provider.soldCattle.length.toString(), Icons.sell, Colors.blue)), const SizedBox(width: 12), Expanded(child: _buildSummaryItem(context, 'Total Weight', '${provider.activeCattle.fold(0.0, (s, c) => s + c.currentWeight).toStringAsFixed(0)} kg', Icons.scale, Colors.orange))]))),
              const SizedBox(height: 16),
              ...cattle.map((c) => _buildCattleCard(context, c, provider)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(heroTag: "cattle_list_fab", onPressed: () => _showAddCattleDialog(context), child: const Icon(Icons.add)),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Column(children: [Icon(icon, color: color, size: 20), const SizedBox(height: 4), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)), Text(label, style: TextStyle(color: color, fontSize: 10))]));
  }

  Widget _buildCattleCard(BuildContext context, Cattle cattle, AppProvider provider) {
    final statusColor = cattle.status == CattleStatus.active ? Colors.green : cattle.status == CattleStatus.sold ? Colors.blue : Colors.grey;
    final totalCost = provider.getTotalCattleCost(cattle.id!);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CattleDetailScreen(cattle: cattle))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.brown.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(cattle.gender == CattleGender.male ? Icons.male : Icons.female, color: Colors.brown)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(cattle.earTag, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), if (cattle.name != null) Text(' (${cattle.name})', style: Theme.of(context).textTheme.bodyMedium)]), Text(cattle.breed ?? 'Unknown breed', style: Theme.of(context).textTheme.bodySmall)])), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(cattle.status.name[0].toUpperCase() + cattle.status.name.substring(1), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)))]),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: _buildInfoChip(context, Icons.scale, '${cattle.currentWeight.toStringAsFixed(0)} ${cattle.weightUnit}', 'Weight')), const SizedBox(width: 8), Expanded(child: _buildInfoChip(context, Icons.trending_up, '${cattle.weightGain >= 0 ? '+' : ''}${cattle.weightGain.toStringAsFixed(0)} kg', 'Gain')), const SizedBox(width: 8), Expanded(child: _buildInfoChip(context, Icons.attach_money, '${totalCost.toStringAsFixed(0)}', 'Total Cost'))]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String value, String label) {
    return Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: Column(children: [Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14), const SizedBox(width: 4), Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis))]), Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10))]));
  }

  void _showAddCattleDialog(BuildContext context) {
    final earTagController = TextEditingController();
    final nameController = TextEditingController();
    final breedController = TextEditingController();
    final priceController = TextEditingController();
    final weightController = TextEditingController();
    final paidAmountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    CattleGender gender = CattleGender.male;
    DateTime purchaseDate = DateTime.now();
    bool isInstallment = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Cattle'),
          content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: earTagController, decoration: const InputDecoration(labelText: 'Ear Tag'), validator: (v) => v?.isEmpty == true ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Name (optional)')),
            const SizedBox(height: 16),
            SegmentedButton<CattleGender>(segments: const [ButtonSegment(value: CattleGender.male, label: Text('Male'), icon: Icon(Icons.male)), ButtonSegment(value: CattleGender.female, label: Text('Female'), icon: Icon(Icons.female))], selected: {gender}, onSelectionChanged: (s) => setState(() => gender = s.first)),
            const SizedBox(height: 16),
            TextFormField(controller: breedController, decoration: const InputDecoration(labelText: 'Breed (optional)')),
            const SizedBox(height: 16),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today), title: Text(DateFormat('MMM dd, yyyy').format(purchaseDate)), subtitle: const Text('Purchase Date'), onTap: () async { final d = await showDatePicker(context: ctx, initialDate: purchaseDate, firstDate: DateTime(2020), lastDate: DateTime.now()); if (d != null) setState(() => purchaseDate = d); }),
            const SizedBox(height: 16),
            TextFormField(controller: priceController, decoration: const InputDecoration(labelText: 'Purchase Price', suffixText: 'TJS'), keyboardType: TextInputType.number, validator: (v) => v?.isEmpty == true ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: weightController, decoration: const InputDecoration(labelText: 'Initial Weight', suffixText: 'kg'), keyboardType: TextInputType.number, validator: (v) => v?.isEmpty == true ? 'Required' : null),
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
                      content: const Text('Do you want to enable installment payment for this purchase?'),
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
                    final price = double.tryParse(priceController.text) ?? 0;
                    if (paid > price) return 'Exceeds total';
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
                final paidAmount = isInstallment && paidAmountController.text.isNotEmpty ? double.parse(paidAmountController.text) : price;
                final paymentStatus = paidAmount >= price ? CattlePurchasePaymentStatus.paid : (paidAmount > 0 ? CattlePurchasePaymentStatus.partial : CattlePurchasePaymentStatus.pending);
                await ctx.read<AppProvider>().addCattle(Cattle(
                  earTag: earTagController.text.trim(),
                  name: nameController.text.isEmpty ? null : nameController.text.trim(),
                  gender: gender,
                  ageCategory: AgeCategory.adult,
                  purchaseDate: purchaseDate,
                  purchasePrice: price,
                  initialWeight: weight,
                  currentWeight: weight,
                  breed: breedController.text.isEmpty ? null : breedController.text.trim(),
                  purchasePaymentStatus: paymentStatus,
                  paidAmount: paidAmount,
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

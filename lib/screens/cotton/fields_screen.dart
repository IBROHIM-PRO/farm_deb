import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/field.dart';
import 'field_detail_screen.dart';

class FieldsScreen extends StatelessWidget {
  const FieldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cotton Fields')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.fields.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grass_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  const Text('No fields registered'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(onPressed: () => _showAddFieldDialog(context), icon: const Icon(Icons.add), label: const Text('Add Field')),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.fields.length,
            itemBuilder: (context, index) {
              final field = provider.fields[index];
              final harvests = provider.getHarvestsForField(field.id!);
              final activities = provider.getActivitiesForField(field.id!);
              final totalHarvested = harvests.fold(0.0, (s, h) => s + h.rawWeight);
              final totalCost = activities.fold(0.0, (s, a) => s + a.cost);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FieldDetailScreen(field: field))),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.grass, color: Colors.green)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(field.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), Text('${field.area} ${field.areaUnit}', style: Theme.of(context).textTheme.bodySmall)])),
                            if (field.seedType != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(field.seedType!, style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold))),
                          ],
                        ),
                        if (field.plantingDate != null) Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(width: 4), Text('Planted: ${DateFormat('MMM dd, yyyy').format(field.plantingDate!)}', style: Theme.of(context).textTheme.bodySmall)])),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildInfoChip(context, Icons.inventory_2, '${totalHarvested.toStringAsFixed(0)} kg', 'Harvested')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildInfoChip(context, Icons.attach_money, '${totalCost.toStringAsFixed(0)} TJS', 'Expenses')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildInfoChip(context, Icons.list_alt, '${activities.length}', 'Activities')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(heroTag: "fields_fab", onPressed: () => _showAddFieldDialog(context), child: const Icon(Icons.add)),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14), const SizedBox(width: 4), Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis))]), Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10))]),
    );
  }

  void _showAddFieldDialog(BuildContext context) {
    final nameController = TextEditingController();
    final areaController = TextEditingController();
    final seedTypeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String areaUnit = 'hectare';
    DateTime? plantingDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Field'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Field Name'), validator: (v) => v?.isEmpty == true ? 'Required' : null),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(flex: 2, child: TextFormField(controller: areaController, decoration: const InputDecoration(labelText: 'Area'), keyboardType: TextInputType.number, validator: (v) => v?.isEmpty == true ? 'Required' : null)),
                  const SizedBox(width: 8),
                  Expanded(child: DropdownButtonFormField<String>(value: areaUnit, decoration: const InputDecoration(labelText: 'Unit'), items: const [DropdownMenuItem(value: 'hectare', child: Text('ha')), DropdownMenuItem(value: 'acre', child: Text('ac'))], onChanged: (v) { if (v != null) areaUnit = v; })),
                ]),
                const SizedBox(height: 16),
                TextFormField(controller: seedTypeController, decoration: const InputDecoration(labelText: 'Seed Type (optional)')),
                const SizedBox(height: 16),
                ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today), title: Text(plantingDate != null ? DateFormat('MMM dd, yyyy').format(plantingDate!) : 'Planting Date (optional)'), onTap: () async { final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365))); if (d != null) setState(() => plantingDate = d); }),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () async { if (formKey.currentState!.validate()) { await ctx.read<AppProvider>().addField(Field(name: nameController.text.trim(), area: double.parse(areaController.text), areaUnit: areaUnit, seedType: seedTypeController.text.isEmpty ? null : seedTypeController.text.trim(), plantingDate: plantingDate)); if (ctx.mounted) Navigator.pop(ctx); } }, child: const Text('Add')),
          ],
        ),
      ),
    );
  }
}

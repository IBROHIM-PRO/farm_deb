import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/cotton_harvest.dart';

class HarvestsScreen extends StatelessWidget {
  const HarvestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cotton Harvests')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.cottonHarvests.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(height: 16), const Text('No harvests recorded'), const SizedBox(height: 8), const Text('Add harvests from field details')]));
          }

          final harvestsByField = <int, List<CottonHarvest>>{};
          for (final h in provider.cottonHarvests) { harvestsByField.putIfAbsent(h.fieldId, () => []).add(h); }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 16), Row(children: [Expanded(child: _buildSummaryItem(context, 'Total Harvested', '${provider.totalCottonHarvested.toStringAsFixed(0)} kg', Icons.inventory_2, Colors.orange)), const SizedBox(width: 12), Expanded(child: _buildSummaryItem(context, 'Processed', '${provider.totalCottonProcessed.toStringAsFixed(0)} kg', Icons.check_circle, Colors.green))])]))),
              const SizedBox(height: 16),
              ...harvestsByField.entries.map((e) {
                final field = provider.getFieldById(e.key);
                final harvests = e.value;
                final totalWeight = harvests.fold(0.0, (s, h) => s + h.rawWeight);
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Text(field?.name ?? 'Unknown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const Spacer(), Text('${totalWeight.toStringAsFixed(0)} kg total', style: Theme.of(context).textTheme.bodySmall)])), ...harvests.map((h) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: CircleAvatar(backgroundColor: h.isProcessed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), child: Icon(h.isProcessed ? Icons.check_circle : Icons.inventory_2, color: h.isProcessed ? Colors.green : Colors.orange)), title: Text('${h.rawWeight.toStringAsFixed(0)} ${h.weightUnit}'), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(DateFormat('MMM dd, yyyy').format(h.date)), if (h.isProcessed && h.processedWeight != null) Text('Processed: ${h.processedWeight!.toStringAsFixed(0)} kg (${h.yieldPercentage.toStringAsFixed(1)}%)', style: const TextStyle(color: Colors.green))]), trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: h.isProcessed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(h.isProcessed ? 'Processed' : 'Raw', style: TextStyle(color: h.isProcessed ? Colors.green : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold))), isThreeLine: h.isProcessed && h.processedWeight != null))), const SizedBox(height: 8)]);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 24), const SizedBox(height: 8), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)), Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color))]));
  }
}

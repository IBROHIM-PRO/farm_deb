import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/field.dart';
import '../../models/field_activity.dart';
import '../../models/cotton_harvest.dart';

class FieldDetailScreen extends StatelessWidget {
  final Field field;
  const FieldDetailScreen({super.key, required this.field});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: Text(field.name), bottom: const TabBar(tabs: [Tab(text: 'Activities'), Tab(text: 'Harvests')]), actions: [IconButton(icon: const Icon(Icons.delete), onPressed: () => _showDeleteConfirm(context))]),
        body: Consumer<AppProvider>(
          builder: (context, provider, _) {
            final activities = provider.getActivitiesForField(field.id!);
            final harvests = provider.getHarvestsForField(field.id!);
            return TabBarView(children: [_buildActivitiesTab(context, activities), _buildHarvestsTab(context, harvests)]);
          },
        ),
        floatingActionButton: FloatingActionButton(heroTag: "field_detail_fab", onPressed: () => _showActionSheet(context), child: const Icon(Icons.add)),
      ),
    );
  }

  Widget _buildActivitiesTab(BuildContext context, List<FieldActivity> activities) {
    if (activities.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.list_alt_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(height: 16), const Text('No activities recorded')]));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final a = activities[index];
        return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: CircleAvatar(backgroundColor: _getActivityColor(a.type).withOpacity(0.1), child: Icon(_getActivityIcon(a.type), color: _getActivityColor(a.type))), title: Text(a.typeDisplayName), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(DateFormat('MMM dd, yyyy').format(a.date)), if (a.description != null) Text(a.description!, style: Theme.of(context).textTheme.bodySmall)]), trailing: Text('${a.cost.toStringAsFixed(0)} ${a.currency}', style: const TextStyle(fontWeight: FontWeight.bold)), isThreeLine: a.description != null));
      },
    );
  }

  Widget _buildHarvestsTab(BuildContext context, List<CottonHarvest> harvests) {
    if (harvests.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(height: 16), const Text('No harvests recorded')]));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: harvests.length,
      itemBuilder: (context, index) {
        final h = harvests[index];
        return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.1), child: const Icon(Icons.inventory_2, color: Colors.orange)), title: Text('${h.rawWeight.toStringAsFixed(0)} ${h.weightUnit}'), subtitle: Text(DateFormat('MMM dd, yyyy').format(h.date)), trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: h.isProcessed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(h.isProcessed ? 'Processed' : 'Raw', style: TextStyle(color: h.isProcessed ? Colors.green : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold))), onTap: h.isProcessed ? null : () => _showProcessDialog(context, h)));
      },
    );
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) { case ActivityType.plowing: return Colors.brown; case ActivityType.irrigation: return Colors.blue; case ActivityType.fertilization: return Colors.green; case ActivityType.spraying: return Colors.purple; case ActivityType.harvesting: return Colors.orange; case ActivityType.other: return Colors.grey; }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) { case ActivityType.plowing: return Icons.agriculture; case ActivityType.irrigation: return Icons.water_drop; case ActivityType.fertilization: return Icons.eco; case ActivityType.spraying: return Icons.colorize; case ActivityType.harvesting: return Icons.inventory_2; case ActivityType.other: return Icons.more_horiz; }
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Icons.list_alt), title: const Text('Add Activity'), onTap: () { Navigator.pop(ctx); _showAddActivityDialog(context); }), ListTile(leading: const Icon(Icons.inventory_2), title: const Text('Add Harvest'), onTap: () { Navigator.pop(ctx); _showAddHarvestDialog(context); })])));
  }

  void _showAddActivityDialog(BuildContext context) {
    final costController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    ActivityType type = ActivityType.plowing;
    DateTime date = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Activity'),
          content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButtonFormField<ActivityType>(value: type, decoration: const InputDecoration(labelText: 'Activity Type'), items: ActivityType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name[0].toUpperCase() + t.name.substring(1)))).toList(), onChanged: (v) { if (v != null) type = v; }), const SizedBox(height: 16), ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today), title: Text(DateFormat('MMM dd, yyyy').format(date)), onTap: () async { final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now()); if (d != null) setState(() => date = d); }), const SizedBox(height: 16), TextFormField(controller: costController, decoration: const InputDecoration(labelText: 'Cost', suffixText: 'TJS'), keyboardType: TextInputType.number, validator: (v) => v?.isEmpty == true ? 'Required' : null), const SizedBox(height: 16), TextFormField(controller: descController, decoration: const InputDecoration(labelText: 'Description (optional)'), maxLines: 2)]))),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () async { if (formKey.currentState!.validate()) { await ctx.read<AppProvider>().addFieldActivity(FieldActivity(fieldId: field.id!, type: type, date: date, cost: double.parse(costController.text), description: descController.text.isEmpty ? null : descController.text.trim())); if (ctx.mounted) Navigator.pop(ctx); } }, child: const Text('Add'))],
        ),
      ),
    );
  }

  void _showAddHarvestDialog(BuildContext context) {
    final weightController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime date = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Harvest'),
          content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today), title: Text(DateFormat('MMM dd, yyyy').format(date)), onTap: () async { final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now()); if (d != null) setState(() => date = d); }), const SizedBox(height: 16), TextFormField(controller: weightController, decoration: const InputDecoration(labelText: 'Raw Weight', suffixText: 'kg'), keyboardType: TextInputType.number, validator: (v) => v?.isEmpty == true ? 'Required' : null)])),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () async { if (formKey.currentState!.validate()) { await ctx.read<AppProvider>().addCottonHarvest(CottonHarvest(fieldId: field.id!, date: date, rawWeight: double.parse(weightController.text))); if (ctx.mounted) Navigator.pop(ctx); } }, child: const Text('Add'))],
        ),
      ),
    );
  }

  void _showProcessDialog(BuildContext context, CottonHarvest harvest) {
    final processedWeightController = TextEditingController();
    final processedUnitsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Process Harvest'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [Text('Raw Weight: ${harvest.rawWeight} ${harvest.weightUnit}'), const SizedBox(height: 16), TextFormField(controller: processedWeightController, decoration: const InputDecoration(labelText: 'Processed Weight', suffixText: 'kg'), keyboardType: TextInputType.number), const SizedBox(height: 16), TextFormField(controller: processedUnitsController, decoration: const InputDecoration(labelText: 'Units/Bales'), keyboardType: TextInputType.number)]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () async { await ctx.read<AppProvider>().updateCottonHarvest(harvest.copyWith(isProcessed: true, processedWeight: processedWeightController.text.isNotEmpty ? double.parse(processedWeightController.text) : null, processedUnits: processedUnitsController.text.isNotEmpty ? int.parse(processedUnitsController.text) : null)); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('Process'))],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete Field'), content: Text('Delete "${field.name}"?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () async { await ctx.read<AppProvider>().deleteField(field.id!); if (ctx.mounted) { Navigator.pop(ctx); Navigator.pop(ctx); } }, child: const Text('Delete'))]));
  }
}

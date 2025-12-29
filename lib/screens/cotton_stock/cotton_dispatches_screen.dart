import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/cotton_batch.dart';
import '../../models/cotton_dispatch.dart';
import '../../models/cotton_type.dart';

class CottonDispatchesScreen extends StatefulWidget {
  const CottonDispatchesScreen({super.key});

  @override
  State<CottonDispatchesScreen> createState() => _CottonDispatchesScreenState();
}

class _CottonDispatchesScreenState extends State<CottonDispatchesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CottonBatch> availableBatches = [];
  List<CottonDispatch> recentDispatches = [];
  Map<int, CottonType> cottonTypesMap = {};
  Map<int, CottonBatch> batchesMap = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      final [batches, dispatches, types] = await Future.wait([
        DatabaseHelper.instance.getAvailableCottonBatches(),
        DatabaseHelper.instance.getAllCottonDispatches(),
        DatabaseHelper.instance.getAllCottonTypes(),
      ]);

      final allBatches = await DatabaseHelper.instance.getAllCottonBatches();
      
      setState(() {
        availableBatches = batches as List<CottonBatch>;
        recentDispatches = dispatches as List<CottonDispatch>;
        
        cottonTypesMap = {for (var type in types as List<CottonType>) type.id!: type};
        batchesMap = {for (var batch in allBatches) batch.id!: batch};
        
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotton Dispatches'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_box), text: 'New Dispatch'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDispatchTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildDispatchTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: availableBatches.isEmpty
          ? _buildEmptyBatchesState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: availableBatches.length,
              itemBuilder: (context, index) {
                final batch = availableBatches[index];
                final cottonType = cottonTypesMap[batch.cottonTypeId];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: _getTypeColor(cottonType?.name ?? '').withOpacity(0.1),
                      child: Icon(
                        Icons.inventory_2,
                        color: _getTypeColor(cottonType?.name ?? ''),
                      ),
                    ),
                    title: Text('${cottonType?.name ?? 'Unknown'} Batch #${batch.id}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Source: ${batch.source}'),
                        Text('Available: ${batch.remainingWeightKg.toStringAsFixed(1)} kg • ${batch.remainingUnits} units'),
                        Text('Arrived: ${DateFormat('MMM dd, yyyy').format(batch.arrivalDate)}'),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    'Total Weight',
                                    '${batch.weightKg.toStringAsFixed(1)} kg',
                                    Icons.scale,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildInfoCard(
                                    'Total Units',
                                    '${batch.units}',
                                    Icons.inventory,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    'Price/kg',
                                    '${batch.pricePerKg.toStringAsFixed(0)} TJS',
                                    Icons.money,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildInfoCard(
                                    'Total Cost',
                                    '${batch.totalCost.toStringAsFixed(0)} TJS',
                                    Icons.account_balance_wallet,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showDispatchDialog(batch),
                                icon: const Icon(Icons.local_shipping),
                                label: const Text('Dispatch from this Batch'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: recentDispatches.isEmpty
          ? _buildEmptyHistoryState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recentDispatches.length,
              itemBuilder: (context, index) {
                final dispatch = recentDispatches[index];
                final batch = batchesMap[dispatch.batchId];
                final cottonType = batch != null ? cottonTypesMap[batch.cottonTypeId] : null;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getTypeColor(cottonType?.name ?? '').withOpacity(0.1),
                      child: Icon(
                        Icons.local_shipping,
                        color: _getTypeColor(cottonType?.name ?? ''),
                      ),
                    ),
                    title: Text('${cottonType?.name ?? 'Unknown'} → ${dispatch.destination}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${dispatch.weightKg.toStringAsFixed(1)} kg • ${dispatch.units} units'),
                        Text('${DateFormat('MMM dd, yyyy').format(dispatch.dispatchDate)}'),
                        if (batch != null) Text('From batch #${batch.id} (${batch.source})'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteDispatch(dispatch),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBatchesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Cotton Batches Available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add cotton arrivals first to dispatch from batches',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Dispatch History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dispatch records will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String typeName) {
    switch (typeName) {
      case 'Lint':
        return Colors.green;
      case 'Uluk':
        return Colors.blue;
      case 'Valakno':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showDispatchDialog(CottonBatch batch) {
    final weightController = TextEditingController();
    final unitsController = TextEditingController();
    final destinationController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dispatch from Batch #${batch.id}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Available: ${batch.remainingWeightKg.toStringAsFixed(1)} kg • ${batch.remainingUnits} units',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight to dispatch (kg)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitsController,
                decoration: const InputDecoration(
                  labelText: 'Units to dispatch',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destinationController,
                decoration: const InputDecoration(
                  labelText: 'Destination/Customer',
                  hintText: 'Where is this being sent?',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _processDispatch(
              batch,
              weightController.text,
              unitsController.text,
              destinationController.text,
            ),
            child: const Text('Dispatch'),
          ),
        ],
      ),
    );
  }

  Future<void> _processDispatch(CottonBatch batch, String weightText, String unitsText, String destination) async {
    if (weightText.trim().isEmpty || unitsText.trim().isEmpty || destination.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final weight = double.tryParse(weightText);
    final units = int.tryParse(unitsText);

    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight')),
      );
      return;
    }

    if (units == null || units <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid units')),
      );
      return;
    }

    if (weight > batch.remainingWeightKg) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight exceeds available amount')),
      );
      return;
    }

    if (units > batch.remainingUnits) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Units exceed available amount')),
      );
      return;
    }

    try {
      await DatabaseHelper.instance.dispatchCottonFromBatch(
        batch.id!,
        weight,
        units,
        destination.trim(),
      );

      Navigator.pop(context);
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cotton dispatched successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing dispatch: $e')),
      );
    }
  }

  Future<void> _deleteDispatch(CottonDispatch dispatch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Dispatch'),
        content: const Text('This will remove the dispatch record but will NOT restore the cotton to the batch. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper.instance.deleteCottonDispatch(dispatch.id!);
        _loadData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dispatch record deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting dispatch: $e')),
        );
      }
    }
  }
}

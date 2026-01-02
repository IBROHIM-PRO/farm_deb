import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cattle_registry_provider.dart';
import '../../models/cattle_weight.dart';
import '../../theme/app_theme.dart';

class CattleWeightTrackingScreen extends StatefulWidget {
  final int cattleId;
  final String earTag;

  const CattleWeightTrackingScreen({
    super.key,
    required this.cattleId,
    required this.earTag,
  });

  @override
  State<CattleWeightTrackingScreen> createState() => _CattleWeightTrackingScreenState();
}

class _CattleWeightTrackingScreenState extends State<CattleWeightTrackingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _measurementDate = DateTime.now();
  bool _isLoading = false;
  List<CattleWeight> weights = [];

  @override
  void initState() {
    super.initState();
    _loadWeights();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadWeights() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<CattleRegistryProvider>();
      await provider.loadCattleWeights();
      setState(() {
        weights = provider.getCattleWeights(widget.cattleId);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хато: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Вазнкунӣ - ${widget.earTag}'),
        backgroundColor: AppTheme.primaryIndigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _buildWeightHistory()),
                _buildAddWeightForm(),
              ],
            ),
    );
  }

  Widget _buildWeightHistory() {
  if (weights.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_weight_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Ҳеҷ вазн бақайд нашудааст',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Вазни чорворо дар поён ворид кунед',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ҲАТМИАН: weights-ро тартиб диҳед аз навтарин ба кӯҳнатарин
  weights.sort((a, b) => b.measurementDate.compareTo(a.measurementDate));

  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: weights.length,
    itemBuilder: (context, index) {
      final weight = weights[index];
      
      // ИСЛОҲ ШУДА: Барои навтарин сабт (index = 0) previousWeight = null.
      // Барои дигар сабтҳо, previousWeight = weights[index - 1].weight (яъне навтарин сабт пеш аз ин)
      final previousWeight = index > 0 ? weights[index - 1].weight : null;
      
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: AppTheme.primaryIndigo),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy').format(weight.measurementDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${weight.weight} кг',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              if (previousWeight != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      weight.weight > previousWeight ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: weight.weight > previousWeight ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      weight.weightDifference(previousWeight) > 0
                          ? '+${weight.weightDifference(previousWeight).toStringAsFixed(1)} кг'
                          : '${weight.weightDifference(previousWeight).toStringAsFixed(1)} кг',
                      style: TextStyle(
                        fontSize: 14,
                        color: weight.weight > previousWeight ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${weight.weightGainPercentage(previousWeight).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              if (weight.notes != null && weight.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  weight.notes!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildAddWeightForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Вазн (кг)',
                prefixIcon: Icon(Icons.monitor_weight),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Вазн зарур аст';
                }
                final weight = double.tryParse(value);
                if (weight == null || weight <= 0) {
                  return 'Вазни дуруст ворид кунед';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Қайдҳо (ихтиёрӣ)',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveWeight,
                icon: const Icon(Icons.add),
                label: const Text('Илова кардан'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryIndigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveWeight() async {
    if (!_formKey.currentState!.validate()) return;

    final weight = CattleWeight(
      cattleId: widget.cattleId,
      weight: double.parse(_weightController.text.trim()),
      measurementDate: _measurementDate,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    try {
      final provider = context.read<CattleRegistryProvider>();
      await provider.addCattleWeight(weight);
      
      _weightController.clear();
      _notesController.clear();
      _measurementDate = DateTime.now();
      
      await _loadWeights();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вазн бомуваффақият илова шуд'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Хато: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

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
  bool _isLoading = false;
  List<CattleWeight> weights = [];

  @override
  void initState() {
    super.initState();
    _loadWeights();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showWeightForm(context, null),
            tooltip: 'Илова кардани вазн',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildWeightHistory(),
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
      
      // Муқоисаи вазн бо вазни пештар (аз ҷиҳати хронологӣ)
      // Чунки рӯйхат аз нав ба кӯҳна тартиб дода шудааст, вазни пештар дар index + 1 аст
      final previousWeight = index < weights.length - 1 ? weights[index + 1].weight : null;
      
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showWeightForm(context, weight),
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
        ),
      );
    },
  );
}

  // Inline modal form for adding/editing weight
  void _showWeightForm(BuildContext context, CattleWeight? weight) {
    final formKey = GlobalKey<FormState>();
    final weightController = TextEditingController(
      text: weight?.weight.toString() ?? '',
    );
    final notesController = TextEditingController(
      text: weight?.notes ?? '',
    );
    DateTime measurementDate = weight?.measurementDate ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          weight == null ? 'Илова кардани вазн' : 'Таҳрири вазн',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Weight input
                    TextFormField(
                      controller: weightController,
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
                        final w = double.tryParse(value);
                        if (w == null || w <= 0) {
                          return 'Вазни дуруст ворид кунед';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Date selector
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: measurementDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => measurementDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Санаи вазнкунӣ',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(measurementDate),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Notes
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Эзоҳ (ихтиёрӣ)',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Save button (and delete if editing)
                    if (weight == null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              try {
                                final provider = context.read<CattleRegistryProvider>();
                                
                                final newWeight = CattleWeight(
                                  cattleId: widget.cattleId,
                                  weight: double.parse(weightController.text.trim()),
                                  measurementDate: measurementDate,
                                  notes: notesController.text.trim().isNotEmpty 
                                    ? notesController.text.trim() 
                                    : null,
                                );
                                
                                await provider.addCattleWeight(newWeight);
                                await _loadWeights();
                                
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Вазн бомуваффақият илова шуд'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Хато: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryIndigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Илова кардан'),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  try {
                                    final provider = context.read<CattleRegistryProvider>();
                                    
                                    final newWeight = CattleWeight(
                                      id: weight!.id,
                                      cattleId: widget.cattleId,
                                      weight: double.parse(weightController.text.trim()),
                                      measurementDate: measurementDate,
                                      notes: notesController.text.trim().isNotEmpty 
                                        ? notesController.text.trim() 
                                        : null,
                                    );
                                    
                                    // For editing, delete and recreate
                                    await provider.deleteCattleWeight(weight!.id!);
                                    await provider.addCattleWeight(newWeight);
                                    await _loadWeights();
                                    
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Вазн бомуваффақият таҳрир шуд'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Хато: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryIndigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Нигоҳ доштан'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Тасдиқ кунед'),
                                    content: const Text('Шумо мутмаин ҳастед, ки мехоҳед ин вазнро нест кунед?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Бекор кардан'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Нест кардан'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirm == true && context.mounted) {
                                  try {
                                    final provider = context.read<CattleRegistryProvider>();
                                    await provider.deleteCattleWeight(weight!.id!);
                                    await _loadWeights();
                                    
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Вазн нест карда шуд'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Хато: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text('Нест кардан'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

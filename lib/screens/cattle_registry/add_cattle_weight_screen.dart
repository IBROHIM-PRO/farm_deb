import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cattle_registry_provider.dart';
import '../../models/cattle_weight.dart';
import '../../theme/app_theme.dart';

/// Add Cattle Weight Screen - Record periodic weight measurements
/// Registry pattern: Weight measurements linked to cattle ID for growth tracking
class AddCattleWeightScreen extends StatefulWidget {
  final int cattleId;

  const AddCattleWeightScreen({
    super.key,
    required this.cattleId,
  });

  @override
  State<AddCattleWeightScreen> createState() => _AddCattleWeightScreenState();
}

class _AddCattleWeightScreenState extends State<AddCattleWeightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _measurementDate = DateTime.now();
  String _weightUnit = 'кг';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Андозагирии вазн'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CattleRegistryProvider>(
        builder: (context, provider, _) {
          final cattle = provider.cattleRegistry
              .where((c) => c.id == widget.cattleId)
              .firstOrNull;
          
          final previousWeights = provider.getWeightsForCattle(widget.cattleId);
          final latestWeight = provider.getLatestWeightForCattle(widget.cattleId);
          final purchase = provider.getPurchaseForCattle(widget.cattleId);

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info
                  _buildHeaderCard(cattle),
                  
                  const SizedBox(height: 16),
                  
                  // Weight History Card
                  if (previousWeights.isNotEmpty || purchase != null)
                    _buildWeightHistoryCard(purchase, latestWeight, previousWeights),
                  
                  const SizedBox(height: 24),
                  
                  // Measurement Date
                  _buildMeasurementDateSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Weight Input
                  _buildWeightSection(latestWeight),
                  
                  const SizedBox(height: 24),
                  
                  // Weight Unit
                  _buildWeightUnitSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Notes
                  _buildNotesSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Save Button
                  _buildSaveButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(cattle) {
    return Card(
      color: Colors.purple.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.scale,
              color: Colors.purple,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Андозагирии вазни чорво ${cattle?.earTag ?? ''}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Барои пайгирии афзоиши вазн ва саломатӣ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightHistoryCard(purchase, latestWeight, List previousWeights) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Таърихи вазн',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Initial weight from purchase
            if (purchase != null)
              _buildWeightHistoryItem(
                'Вазни аввалия',
                '${purchase.weightAtPurchase.toStringAsFixed(1)} кг',
                'Дар вақти хариданӣ',
                Icons.shopping_cart,
                Colors.blue,
                true,
              ),
            
            // Latest weight
            if (latestWeight != null)
              _buildWeightHistoryItem(
                'Охирин вазн',
                latestWeight.weightDisplay,
                'Андозаи охирин',
                Icons.scale,
                Colors.green,
                false,
              ),
            
            // Weight gain calculation
            if (purchase != null && latestWeight != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Афзоиши вазн: +${(latestWeight.weight - purchase.weightAtPurchase).toStringAsFixed(1)} кг',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Number of measurements
            if (previousWeights.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Ҳамагӣ ${previousWeights.length} маротиба андоза карда шудааст',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightHistoryItem(
    String title,
    String weight,
    String subtitle,
    IconData icon,
    Color color,
    bool isFirst,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            weight,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Санаи андозагирӣ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.purple),
            title: const Text('Санаи андозагирӣ'),
            subtitle: Text(
              '${_measurementDate.day.toString().padLeft(2, '0')}/'
              '${_measurementDate.month.toString().padLeft(2, '0')}/'
              '${_measurementDate.year}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _selectMeasurementDate,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightSection(latestWeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Вазни нав',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _weightController,
          decoration: InputDecoration(
            labelText: 'Вазни ҳозираи чорво',
            suffixText: _weightUnit,
            prefixIcon: const Icon(Icons.scale, color: Colors.purple),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.trim().isEmpty == true) {
              return 'Вазни чорво зарур аст';
            }
            final weight = double.tryParse(value!);
            if (weight == null || weight <= 0) {
              return 'Вазни дуруст ворид кунед';
            }
            return null;
          },
          onChanged: _calculateWeightChange,
        ),
        
        // Weight change indicator
        if (_weightController.text.isNotEmpty && latestWeight != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildWeightChangeIndicator(latestWeight),
          ),
      ],
    );
  }

  Widget _buildWeightChangeIndicator(latestWeight) {
    final newWeight = double.tryParse(_weightController.text);
    if (newWeight == null) return const SizedBox.shrink();
    
    final change = newWeight - latestWeight.weight;
    final isIncrease = change > 0;
    final color = isIncrease ? Colors.green : (change < 0 ? Colors.red : Colors.grey);
    final icon = isIncrease ? Icons.trending_up : (change < 0 ? Icons.trending_down : Icons.trending_flat);
    final prefix = isIncrease ? '+' : '';
    
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              'Тағйирот: $prefix${change.toStringAsFixed(1)} $_weightUnit',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightUnitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Воҳиди андозагирӣ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _weightUnit,
          decoration: InputDecoration(
            labelText: 'Воҳиди вазн',
            prefixIcon: const Icon(Icons.straighten, color: Colors.purple),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: const [
            DropdownMenuItem(value: 'кг', child: Text('Килограм (кг)')),
            DropdownMenuItem(value: 'фунт', child: Text('Фунт (фунт)')),
          ],
          onChanged: (value) {
            setState(() {
              _weightUnit = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Эзоҳот',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'Эзоҳот дар бораи андозагирӣ (ихтиёрӣ)',
            prefixIcon: const Icon(Icons.note, color: Colors.purple),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            hintText: 'Мисол: Андоза пас аз ғизо, чорво солим...',
          ),
          keyboardType: TextInputType.text,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveWeight,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Вазн сабт кардан',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _calculateWeightChange(String value) {
    setState(() {}); // Trigger rebuild to update weight change indicator
  }

  Future<void> _selectMeasurementDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _measurementDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _measurementDate = date;
      });
    }
  }

  Future<void> _saveWeight() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final weight = CattleWeight(
          cattleId: widget.cattleId,
          measurementDate: _measurementDate,
          weight: double.parse(_weightController.text),
          weightUnit: _weightUnit,
          notes: _notesController.text.trim().isNotEmpty 
              ? _notesController.text.trim() 
              : null,
        );

        await context.read<CattleRegistryProvider>().addCattleWeight(weight);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Вазн бомуваффақият сабт шуд'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Хатогӣ: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

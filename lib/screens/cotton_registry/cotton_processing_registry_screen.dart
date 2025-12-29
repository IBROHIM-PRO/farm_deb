import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cotton_registry_provider.dart';
import '../../models/cotton_processing_registry.dart';
import '../../models/cotton_processing_calculator.dart';
import '../../theme/app_theme.dart';
import 'add_cotton_processing_screen.dart';

/// Cotton Processing Registry Screen - Processing operations linked to purchases
/// Shows cotton processing records with automatic calculator integration
class CottonProcessingRegistryScreen extends StatefulWidget {
  const CottonProcessingRegistryScreen({super.key});

  @override
  State<CottonProcessingRegistryScreen> createState() => _CottonProcessingRegistryScreenState();
}

class _CottonProcessingRegistryScreenState extends State<CottonProcessingRegistryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Коркарди пахта'),
        elevation: 0,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showProcessingGuide,
            icon: const Icon(Icons.help_outline),
            tooltip: 'Дастури коркард',
          ),
          IconButton(
            onPressed: _showStatistics,
            icon: const Icon(Icons.analytics),
            tooltip: 'Омор',
          ),
        ],
      ),
      body: Consumer<CottonRegistryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredProcessing = _getFilteredProcessing(provider.processingRegistry);

          return filteredProcessing.isEmpty
              ? _buildEmptyState(context)
              : _buildProcessingList(context, provider, filteredProcessing);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "cotton_processing_main_fab",
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddCottonProcessingScreen(),
          ),
        ),
        icon: const Icon(Icons.precision_manufacturing),
        label: const Text('Коркарди нав'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  Widget _buildSearchAndSummary(
    BuildContext context,
    CottonRegistryProvider provider,
    List<CottonProcessingRegistry> processing,
  ) {
    final stats = provider.overallStatistics;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Ҷустуҷӯи коркард...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Ҳамагӣ коркард',
                  '${stats['totalProcessed']}',
                  Icons.precision_manufacturing,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Самаранокӣ',
                  '${(stats['processingEfficiency'] as num?)?.toDouble()?.toStringAsFixed(1) ?? '0.0'}%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingList(
    BuildContext context,
    CottonRegistryProvider provider,
    List<CottonProcessingRegistry> processing,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: processing.length,
      itemBuilder: (context, index) {
        final proc = processing[index];
        return _buildProcessingCard(context, provider, proc);
      },
    );
  }

  Widget _buildProcessingCard(
    BuildContext context,
    CottonRegistryProvider provider,
    CottonProcessingRegistry processing,
  ) {
    final inputs = provider.processingInputs
        .where((input) => input.processingId == processing.id)
        .toList();
    
    final outputs = provider.processingOutputs
        .where((output) => output.processingId == processing.id)
        .toList();

    final linkedPurchase = provider.purchaseRegistry
        .where((p) => p.id == processing.linkedPurchaseId)
        .firstOrNull;

    final totalInputWeight = inputs.fold(0.0, (sum, input) => sum + input.weightUsed);
    final totalOutputWeight = outputs.fold(0.0, (sum, output) => sum + output.totalWeight);
    final yieldPercentage = totalInputWeight > 0 
        ? (totalOutputWeight / totalInputWeight) * 100 
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showProcessingDetails(processing, inputs, outputs, linkedPurchase),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      processing.processingDate != null
                          ? DateFormat('dd/MM/yyyy', 'en_US').format(processing.processingDate!)
                          : 'Санаи нест',
                      style: const TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getProcessingTypeColor(inputs).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getProcessingTypeDisplay(inputs),
                      style: TextStyle(
                        color: _getProcessingTypeColor(inputs),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),                            
              
              const SizedBox(height: 8),
              
              // Input Cotton Types
              if (inputs.isNotEmpty) ...[
                const Text(
                  'Навъҳои истифодашуда:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: inputs.map((input) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getCottonTypeColor(input.cottonType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${input.cottonTypeDisplay}: ${input.weightUsedDisplay}',
                        style: TextStyle(
                          color: _getCottonTypeColor(input.cottonType),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              const SizedBox(height: 12),
              
              const Divider(height: 1),
              
              const SizedBox(height: 8),
              
              // Summary Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Вазни дохилӣ:',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${totalInputWeight.toStringAsFixed(1)} кг',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Вазни хориҷӣ:',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${totalOutputWeight.toStringAsFixed(1)} кг',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Самаранокӣ:',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${yieldPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: yieldPercentage >= 70 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),                            
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.precision_manufacturing_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ҳеҷ коркард анҷом нашудааст',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Барои коркарди пахтаи харидашуда тугмаи зеринро пахш кунед',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddCottonProcessingScreen(),
              ),
            ),
            icon: const Icon(Icons.precision_manufacturing),
            label: const Text('Коркарди нав'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<CottonProcessingRegistry> _getFilteredProcessing(List<CottonProcessingRegistry> processing) {
    return processing.where((proc) {
      if (_searchQuery.isNotEmpty) {
        // Could add more search criteria here
        return false;
      }
      return true;
    }).toList();
  }

  Color _getCottonTypeColor(cottonType) {
    switch (cottonType.toString().split('.').last) {
      case 'lint':
        return Colors.green;
      case 'uluk':
        return Colors.blue;
      case 'valakno':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getProcessingTypeColor(List inputs) {
    final types = inputs.map((input) => input.cottonType).toSet();
    if (types.length == 3) return Colors.purple;
    if (types.length == 2) return Colors.blue;
    return Colors.green;
  }

  String _getProcessingTypeDisplay(List inputs) {
    final types = inputs.map((input) => input.cottonType).toSet();
    switch (types.length) {
      case 3: return 'Се навъ';
      case 2: return 'Ду навъ';
      case 1: return 'Як навъ';
      default: return 'Номаълум';
    }
  }

  void _showProcessingDetails(
    CottonProcessingRegistry processing,
    List inputs,
    List outputs,
    linkedPurchase,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Тафсилоти коркард'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (linkedPurchase != null) ...[
                Text('Хариди асосӣ: ${linkedPurchase.supplierName}'),
                const SizedBox(height: 8),
              ],
              if (processing.processingDate != null) ...[
                Text('Санаи коркард: ${DateFormat('dd/MM/yyyy', 'en_US').format(processing.processingDate!)}'),
                const SizedBox(height: 8),
              ],
              
              const Text('Навъҳои истифодашуда:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...inputs.map((input) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• ${input.cottonTypeDisplay}: ${input.weightUsedDisplay} (${input.unitsUsedDisplay})'),
              )),
              
              const SizedBox(height: 12),
              
              const Text('Бастаҳои тайёршуда:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...outputs.map((output) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• Коркард: ${output.unitsDisplay} × ${output.batchWeightDisplay}'),
              )),
              
              if (processing.notes != null) ...[
                const SizedBox(height: 12),
                const Text('Эзоҳот:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(processing.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Пӯшидан'),
          ),
        ],
      ),
    );
  }

  void _showProcessingGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Дастури коркарди пахта'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Формулаҳои коркард:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              
              const Text('1. Се навъи пахта (Линт + Улук + Валакно):', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('• Линт ва Улук якҷоя ҳисоб мешаванд'),
              const Text('• Валакно автоматӣ ҳисоб карда мешавад'),
              const Text('• Нисбат: (Линт + Улук) ≈ 1тона, Валакно ≈ 250 кило'),
              const SizedBox(height: 8),
              
              const Text('2. Ду навъи пахта:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('• (Линт ё Улук) + Валакно'),
              const Text('• Нисбат: Асосӣ ≈ 1 тона, Валакно ≈ 500 кило'),
              const SizedBox(height: 8),                           
              
              const Text(
                'Эзоҳ: Системаи автоматӣ нисбатҳоро ҳисоб мекунад, аммо шумо метавонед дастӣ тағйир диҳед.',
                style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Фаҳмидам'),
          ),
        ],
      ),
    );
  }

  void _showStatistics() {
    final provider = context.read<CottonRegistryProvider>();
    final stats = provider.overallStatistics;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Омори коркарди пахта'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Ҳамагӣ коркард:', '${stats['totalProcessed']}'),
              _buildStatRow('Ҳамагӣ фуруш:', '${stats['totalSales']}'),
              _buildStatRow('Самаранокӣ:', '${(stats['processingEfficiency'] as num?)?.toDouble()?.toStringAsFixed(1) ?? '0.0'}%'),
              const Divider(),
              _buildStatRow('Вазни инвентор:', '${(stats['totalInventoryWeight'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'} кг'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Пӯшидан'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

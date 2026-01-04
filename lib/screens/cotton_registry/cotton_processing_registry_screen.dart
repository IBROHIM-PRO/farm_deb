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
        actions: [          
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddCottonProcessingScreen(),
              ),
            ),
            icon: const Icon(Icons.add),
            tooltip: 'Коркарди нав',
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
    );
  }

  Widget _buildProcessingList(
    BuildContext context,
    CottonRegistryProvider provider,
    List<CottonProcessingRegistry> processing,
  ) {
    // Sort by date (newest first)
    processing.sort((a, b) => b.processingDate?.compareTo(a.processingDate ?? DateTime.now()) ?? 0);
    
    return RefreshIndicator(
      onRefresh: () async {
        await provider.loadAllData();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [        
          
          const SizedBox(height: 16),
          
          // Processing List
          ...processing.map((proc) => _buildProcessingCard(context, provider, proc)).toList(),
        ],
      ),
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

    final totalInputWeight = inputs.fold(0.0, (sum, input) => sum + input.weightUsed);
    final totalOutputWeight = outputs.fold(0.0, (sum, output) => sum + output.totalWeight);
    final yieldPercentage = totalInputWeight > 0 
        ? (totalOutputWeight / totalInputWeight) * 100 
        : 0.0;
    
    final dateStr = processing.processingDate != null
        ? DateFormat('dd.MM.yyyy').format(processing.processingDate!)
        : 'Санаи номаълум';

    return GestureDetector(
      onTap: () => _showProcessingDetailsModal(processing, inputs, outputs, provider),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row - Date and status indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Status indicator (colored circle like in the image)
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getProcessingStatusColor(yieldPercentage),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${inputs.length} навъ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[700],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Details Row - Like "Трек код" section in the image
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Input weight
                    Row(
                      children: [
                        Text(
                          'Вазни дохилӣ:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${totalInputWeight.toStringAsFixed(1)} кг',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Output weight
                    Row(
                      children: [
                        Text(
                          'Вазни хориҷӣ:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${totalOutputWeight.toStringAsFixed(1)} кг',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Efficiency
                    Row(
                      children: [
                        Text(
                          'Самаранокӣ:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${yieldPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getEfficiencyColor(yieldPercentage),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow at bottom
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProcessingStatusColor(double yieldPercentage) {
    if (yieldPercentage >= 70) return Colors.green;
    if (yieldPercentage >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getEfficiencyColor(double yieldPercentage) {
    if (yieldPercentage >= 70) return Colors.green;
    if (yieldPercentage >= 50) return Colors.orange;
    return Colors.red;
  }

  void _showProcessingDetailsModal(
    CottonProcessingRegistry processing,
    List inputs,
    List outputs,
    CottonRegistryProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            final totalInputWeight = inputs.fold(0.0, (sum, input) => sum + input.weightUsed);
            final totalOutputWeight = outputs.fold(0.0, (sum, output) => sum + output.totalWeight);
            final yieldPercentage = totalInputWeight > 0 
                ? (totalOutputWeight / totalInputWeight) * 100 
                : 0.0;
            
            final dateStr = processing.processingDate != null
                ? DateFormat('dd.MM.yyyy').format(processing.processingDate!)
                : 'Санаи номаълум';
            
            return Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getProcessingStatusColor(yieldPercentage),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Коркарди пахта',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 24),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Summary section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            _buildModalRow('Вазни умумии дохилӣ:', '${totalInputWeight.toStringAsFixed(1)} кг'),
                            const SizedBox(height: 12),
                            _buildModalRow('Вазни умумии хориҷӣ:', '${totalOutputWeight.toStringAsFixed(1)} кг'),
                            const SizedBox(height: 12),
                            _buildModalRow(
                              'Самаранокии коркард:',
                              '${yieldPercentage.toStringAsFixed(1)}%',
                              valueColor: _getEfficiencyColor(yieldPercentage),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Input Materials section
                      Text(
                        'Маводҳои дохилӣ:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      ...inputs.map((input) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                input.cottonTypeDisplay,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Вазн:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${input.weightUsed.toStringAsFixed(1)} кг',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Донаҳо:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${input.unitsUsed} дона',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      const SizedBox(height: 24),
                      
                      // Output Products section
                      Text(
                        'Маҳсулоти хориҷӣ:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      ...outputs.map((output) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${output.batchWeightPerUnit.toStringAsFixed(1)} кг',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Адад:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${output.numberOfUnits} дона',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),                              
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Вазни умумӣ:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${output.totalWeight.toStringAsFixed(1)} кг',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      // Notes section if exists
                      if (processing.notes != null && processing.notes!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Эзоҳот:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Text(
                            processing.notes!,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
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
    if (_searchQuery.isEmpty) {
      return processing;
    }
    
    return processing.where((proc) {
      final dateStr = proc.processingDate != null
          ? DateFormat('dd.MM.yyyy').format(proc.processingDate!)
          : '';
      
      return dateStr.toLowerCase().contains(_searchQuery);
    }).toList();
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cotton_warehouse_provider.dart';

class ProcessedCottonWarehouseScreen extends StatelessWidget {
  const ProcessedCottonWarehouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Анбори пахтаи коркардшуда'),
        centerTitle: true,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[50],
      body: Consumer<CottonWarehouseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final totalInventory = provider.totalProcessedCotton;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(context, totalInventory),
                const SizedBox(height: 20),
                _buildInventoryDetails(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, dynamic totalInventory) {
    final hasCotton = totalInventory != null && totalInventory.pieces > 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasCotton 
            ? [Colors.blue[600]!, Colors.blue[400]!]
            : [Colors.grey[400]!, Colors.grey[300]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (hasCotton ? Colors.blue : Colors.grey).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          
          const SizedBox(height: 16),
          if (hasCotton) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Миқдори умумӣ',
                  '${totalInventory.pieces} дона',
                  Colors.white,
                ),
                _buildSummaryItem(
                  'Вазни умумӣ',
                  '${totalInventory.totalWeight.toStringAsFixed(1)} кг',
                  Colors.white,
                ),
              ],
            ),           
          ] else ...[
            Text(
              'Анбор холӣ аст',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryDetails(BuildContext context, CottonWarehouseProvider provider) {
    final inventory = provider.processedCottonInventory;
    
    // Define allowed weight categories (10-50kg in 5kg increments)
    final allowedWeights = [10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 50.0];
    
    // Filter and group inventory by exact weight categories
    final Map<double, List<dynamic>> groupedByWeight = {};
    
    for (final batch in inventory) {
      // Find the closest allowed weight (within 2.5kg tolerance)
      final double matchingWeight = allowedWeights.firstWhere(
        (weight) => (batch.totalWeight - weight).abs() <= 2.5,
        orElse: () => -1.0,
      );
      
      if (matchingWeight != -1.0) {
        groupedByWeight.putIfAbsent(matchingWeight, () => []).add(batch);
      }
    }
    
    // Sort weight categories
    final sortedWeights = groupedByWeight.keys.toList()..sort();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Тафсилоти анбор',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            if (groupedByWeight.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${sortedWeights.length} Намуд',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (groupedByWeight.isEmpty) 
          _buildEmptyState()
        else ...[
          // Display weight categories (10-50kg only)
          ...sortedWeights.map((weight) {
            final batches = groupedByWeight[weight]!;
            final totalQuantity = batches.fold<int>(0, (sum, batch) => sum + (batch.pieces as int));
            final totalWeight = batches.fold<double>(0, (sum, batch) => sum + batch.totalWeight);
            
            return Column(
              children: [
                _buildWeightCategoryCard(weight, totalQuantity, totalWeight, batches.length),
                const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ],
    );
  }

  Widget _buildWeightCategoryCard(double weight, int totalQuantity, double totalWeight, int batchCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '#${weight.toInt()}',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weight.toStringAsFixed(0)} кг',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_formatDate(DateTime.now())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Вазнин',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Weight category details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.apps,
                  'Дона (Аслӣ)',
                  '$totalQuantity дона',
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  Icons.trending_up,
                  'Дона (Афзуд)',
                  '${(totalQuantity * (weight / 10)).toInt()} дона',
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.scale,
                  'Вазни умумӣ',
                  '${totalWeight.toStringAsFixed(0)} кг',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  Icons.assessment,
                  'Коэффитсиент',
                  'x${(weight / 10).toStringAsFixed(0)}',
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Анбор холӣ аст',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Пахтаи коркардшуда дар анбор мавҷуд нест',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildDetailItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getWeightRange(double weightPerPiece) {
    final min = (weightPerPiece * 0.9).toStringAsFixed(0);
    final max = (weightPerPiece * 1.1).toStringAsFixed(0);
    return '$min-$max кг';
  }
}

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
    
    // Categorize inventory by weight ranges
    final standardCargo = inventory.where((batch) => batch.totalWeight >= 10 && batch.totalWeight <= 50).toList();
    final heavyCargo = inventory.where((batch) => batch.totalWeight > 50).toList();
    final otherCargo = inventory.where((batch) => batch.totalWeight < 10).toList();
    
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
            if (inventory.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${inventory.length} Намуд',
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
        
        if (inventory.isEmpty) 
          _buildEmptyState()
        else ...[
          // Standard cargo section (10-50kg)
          if (standardCargo.isNotEmpty) ...[
            _buildWeightCategoryHeader('Боргирии стандартӣ (10-50 кг)', standardCargo.length, Colors.green),
            const SizedBox(height: 12),
            ...standardCargo.asMap().entries.map((entry) => 
              _buildStandardInventoryBatch(context, entry.value, entry.key + 1)
            ),
            const SizedBox(height: 20),
          ],
          
          // Heavy cargo section (>50kg)
          if (heavyCargo.isNotEmpty) ...[
            _buildWeightCategoryHeader('Боргирии вазнин (>50 кг)', heavyCargo.length, Colors.orange),
            const SizedBox(height: 12),
            ...heavyCargo.asMap().entries.map((entry) => 
              _buildHeavyInventoryBatch(context, entry.value, entry.key + 1)
            ),
            const SizedBox(height: 20),
          ],
          
          // Other cargo section (<10kg)
          if (otherCargo.isNotEmpty) ...[
            _buildWeightCategoryHeader('Боргирии хурд (<10 кг)', otherCargo.length, Colors.grey),
            const SizedBox(height: 12),
            ...otherCargo.asMap().entries.map((entry) => 
              _buildStandardInventoryBatch(context, entry.value, entry.key + 1)
            ),
          ],
        ],
      ],
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

  Widget _buildWeightCategoryHeader(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, (color.red * 0.8).round(), (color.green * 0.8).round(), (color.blue * 0.8).round()),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count дона',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardInventoryBatch(BuildContext context, dynamic batch, int batchNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '#$batchNumber',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 14,
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
                       '${batch.totalWeight.toStringAsFixed(1)} кг',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(batch.lastUpdated),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Стандартӣ',
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
          
          // Batch details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.apps,
                  'Дона',
                  '${batch.pieces} дона',
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  Icons.scale,
                  'Вазни умумӣ',
                  '${batch.totalWeight.toStringAsFixed(1)} кг',
                  Colors.green,
                ),
              ),
            ],
          ),                                        
        ],
      ),
    );
  }

  Widget _buildHeavyInventoryBatch(BuildContext context, dynamic batch, int batchNumber) {
    // Calculate increased quantity for heavy cargo (over 50kg)
    final baseQuantity = batch.pieces;
    final weightFactor = (batch.totalWeight / 50).ceil(); // Increase factor based on weight
    final increasedQuantity = baseQuantity * weightFactor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '#$batchNumber',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 14,
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
                       '${batch.totalWeight.toStringAsFixed(1)} кг',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(batch.lastUpdated),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Вазнин',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Heavy batch details with increased quantity
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.apps,
                  'Дона (Аслӣ)',
                  '${batch.pieces} дона',
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  Icons.trending_up,
                  'Дона (Афзуд)',
                  '$increasedQuantity дона',
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
                  '${batch.totalWeight.toStringAsFixed(1)} кг',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  Icons.assessment,
                  'Коэффитсиент',
                  'x${weightFactor}',
                  Colors.purple,
                ),
              ),
            ],
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

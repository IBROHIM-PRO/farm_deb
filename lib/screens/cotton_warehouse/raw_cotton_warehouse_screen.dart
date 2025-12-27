import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cotton_warehouse_provider.dart';
import '../../models/raw_cotton_warehouse.dart';

class RawCottonWarehouseScreen extends StatelessWidget {
  const RawCottonWarehouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Анбори пахтаи хом'),
        centerTitle: true,
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[50],
      body: Consumer<CottonWarehouseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(context, provider),
                const SizedBox(height: 20),
                _buildInventoryByType(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, CottonWarehouseProvider provider) {
    final summary = provider.getWarehouseSummary();
    final rawSummary = summary['rawCotton'];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warehouse, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                'Ҷамъи пахтаи хом',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Қисматҳо',
                '${rawSummary['totalPieces']} дона',
                Colors.white,
              ),
              _buildSummaryItem(
                'Вазн',
                '${rawSummary['totalWeight'].toStringAsFixed(1)} кг',
                Colors.white,
              ),
            ],
          ),
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

  Widget _buildInventoryByType(BuildContext context, CottonWarehouseProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Аз рӯи навъ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        ...RawCottonType.values.map((type) => _buildTypeCard(context, provider, type)),
      ],
    );
  }

  Widget _buildTypeCard(BuildContext context, CottonWarehouseProvider provider, RawCottonType type) {
    final inventory = provider.getRawCottonByType(type);
    final hasInventory = inventory != null && inventory.pieces > 0;

    Color cardColor;
    IconData icon;
    switch (type) {
      case RawCottonType.lint:
        cardColor = Colors.blue;
        icon = Icons.fiber_manual_record;
        break;
      case RawCottonType.sliver:
        cardColor = Colors.orange;
        icon = Icons.linear_scale;
        break;
      case RawCottonType.other:
        cardColor = Colors.purple;
        icon = Icons.category;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasInventory ? cardColor.withOpacity(0.3) : Colors.grey[300]!,
          width: hasInventory ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: cardColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTypeDisplayName(type),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (hasInventory) ...[
                  Text(
                    '${inventory!.pieces} қисмат • ${inventory.totalWeight.toStringAsFixed(1)} кг',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (inventory.averageWeightPerPiece > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Миёна: ${inventory.averageWeightPerPiece.toStringAsFixed(1)} кг/қисмат',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ] else ...[
                  Text(
                    'Холӣ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasInventory)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Мавҷуд',
                style: TextStyle(
                  color: Colors.green[800],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Холӣ',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getTypeDisplayName(RawCottonType type) {
    switch (type) {
      case RawCottonType.lint: return 'Линт';
      case RawCottonType.sliver: return 'Улук';
      case RawCottonType.other: return 'Валакно';
    }
  }
}

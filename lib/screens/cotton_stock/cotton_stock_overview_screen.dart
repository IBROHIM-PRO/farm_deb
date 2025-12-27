import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/cotton_type.dart';

class CottonStockOverviewScreen extends StatefulWidget {
  const CottonStockOverviewScreen({super.key});

  @override
  State<CottonStockOverviewScreen> createState() => _CottonStockOverviewScreenState();
}

class _CottonStockOverviewScreenState extends State<CottonStockOverviewScreen> {
  List<CottonType> cottonTypes = [];
  Map<String, dynamic> stockSummary = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final types = await DatabaseHelper.instance.getAllCottonTypes();
      final summary = await DatabaseHelper.instance.getCottonStockSummary();
      
      setState(() {
        cottonTypes = types;
        stockSummary = summary;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хатогӣ дар боркунии маълумот: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мурорҷоии захираи пахта'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Сатҳи ҳозираи захира',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (stockSummary['stockByType'] != null && (stockSummary['stockByType'] as List).isNotEmpty)
                      ..._buildStockCards()
                    else
                      _buildEmptyState(),
                    const SizedBox(height: 24),
                    _buildCottonTypesSection(),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildStockCards() {
    final stockByType = stockSummary['stockByType'] as List<Map<String, dynamic>>;
    
    return stockByType.map((stock) {
      final cottonType = stock['cottonType'] as String;
      final totalWeight = (stock['totalWeight'] as num?)?.toDouble() ?? 0;
      final totalUnits = (stock['totalUnits'] as int?) ?? 0;
      final batchCount = (stock['batchCount'] as int?) ?? 0;

      Color cardColor;
      switch (cottonType) {
        case 'Lint':
          cardColor = Colors.green;
          break;
        case 'Uluk':
          cardColor = Colors.blue;
          break;
        case 'Valakno':
          cardColor = Colors.orange;
          break;
        default:
          cardColor = Colors.grey;
      }

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: cardColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cottonType,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${totalWeight.toStringAsFixed(1)} кг • $totalUnits дона',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '$batchCount баста мавҷуд аст',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Захираи пахта мавҷуд нест',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Бастаҳои пахта илова кунед то сатҳи захираро дар ин ҷо бинед',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCottonTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Навъҳои пахта ва нархҳои асосӣ',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...cottonTypes.map((type) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getTypeColor(type.name).withOpacity(0.1),
              child: Icon(
                Icons.category,
                color: _getTypeColor(type.name),
              ),
            ),
            title: Text(type.name),
            subtitle: Text('Нархи асосӣ: ${type.pricePerKg.toStringAsFixed(2)} сомонӣ/кг'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editCottonType(type),
            ),
          ),
        )),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addCottonType,
            icon: const Icon(Icons.add),
            label: const Text('Илова кардани навъи пахта'),
          ),
        ),
      ],
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

  void _addCottonType() {
    _showCottonTypeDialog(null);
  }

  void _editCottonType(CottonType type) {
    _showCottonTypeDialog(type);
  }

  void _showCottonTypeDialog(CottonType? type) {
    final nameController = TextEditingController(text: type?.name ?? '');
    final priceController = TextEditingController(
      text: type?.pricePerKg.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == null ? 'Илова кардани навъи пахта' : 'Тағйири навъи пахта'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Номи навъи пахта',
                hintText: 'мисол: Линт, Улук, Валакно',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Нархи асосӣ барои як кг (сомонӣ)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Бекор кардан'),
          ),
          ElevatedButton(
            onPressed: () => _saveCottonType(type, nameController.text, priceController.text),
            child: Text(type == null ? 'Илова кардан' : 'Навсозӣ'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCottonType(CottonType? existingType, String name, String priceText) async {
    if (name.trim().isEmpty || priceText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Лутфан ҳамаи майдонҳоро пур кунед')),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Лутфан нархи дурустро ворид кунед')),
      );
      return;
    }

    try {
      final cottonType = CottonType(
        id: existingType?.id,
        name: name.trim(),
        pricePerKg: price,
      );

      if (existingType == null) {
        await DatabaseHelper.instance.insertCottonType(cottonType);
      } else {
        await DatabaseHelper.instance.updateCottonType(cottonType);
      }

      Navigator.pop(context);
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existingType == null ? 'Навъи пахта илова карда шуд' : 'Навъи пахта навсозӣ карда шуд'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Хатогӣ: $e')),
      );
    }
  }
}

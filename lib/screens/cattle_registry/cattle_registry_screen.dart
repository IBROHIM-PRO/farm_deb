import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cattle_registry_provider.dart';
import '../../providers/barn_provider.dart';
import '../../models/cattle_registry.dart';
import '../../theme/app_theme.dart';
import 'add_cattle_registry_screen.dart';
import 'cattle_financial_detail_screen.dart';
import 'add_cattle_purchase_screen.dart';
import 'add_cattle_weight_screen.dart';

class CattleRegistryScreen extends StatefulWidget {
  const CattleRegistryScreen({super.key});

  @override
  State<CattleRegistryScreen> createState() => _CattleRegistryScreenState();
}

class _CattleRegistryScreenState extends State<CattleRegistryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CattleRegistryProvider>().loadAllData();
      context.read<BarnProvider>().loadBarns();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Реестри чорво'),
        backgroundColor: AppTheme.primaryIndigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddCattleRegistryScreen(),
                ),
              );
              if (result == true) {
                context.read<CattleRegistryProvider>().loadAllData();
              }
            },
            tooltip: 'Илова кардани чорво',
          ),
        ],
      ),
      body: Consumer<CattleRegistryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final cattle = provider.allCattle;
          
          if (cattle.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadAllData(),
            child: Column(
              children: [
                _buildSummaryCard(cattle),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cattle.length,
                    itemBuilder: (context, index) {
                      return _buildCattleCard(cattle[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Ҳеҷ чорво бақайд нашудааст',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Барои илова кардан тугмаи + -ро пахш кунед',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<CattleRegistry> cattle) {
    final activeCattle = cattle.where((c) => c.status == CattleStatus.active).length;
    final soldCattle = cattle.where((c) => c.status == CattleStatus.sold).length;
    final males = cattle.where((c) => c.gender == CattleGender.male).length;
    final females = cattle.where((c) => c.gender == CattleGender.female).length;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.pets, color: AppTheme.primaryIndigo, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Хулосаи чорво',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Фаъол',
                      '$activeCattle',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  Container(height: 40, width: 1, color: Colors.grey[300]),
                  Expanded(
                    child: _buildStatItem(
                      'Фурӯхташуда',
                      '$soldCattle',
                      Icons.sell,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Нар',
                      '$males',
                      Icons.male,
                      Colors.blue,
                    ),
                  ),
                  Container(height: 40, width: 1, color: Colors.grey[300]),
                  Expanded(
                    child: _buildStatItem(
                      'Мода',
                      '$females',
                      Icons.female,
                      Colors.pink,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCattleCard(CattleRegistry cattle) {
    final barnProvider = context.read<BarnProvider>();
    final barn = cattle.barnId != null ? barnProvider.getBarnById(cattle.barnId!) : null;
    final cattleProvider = context.read<CattleRegistryProvider>();
    final purchase = cattleProvider.getCattlePurchases(cattle.id!).isNotEmpty
        ? cattleProvider.getCattlePurchases(cattle.id!).first
        : null;
    final weights = cattleProvider.getCattleWeights(cattle.id!);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CattleFinancialDetailScreen(cattleId: cattle.id!),
            ),
          );
          context.read<CattleRegistryProvider>().loadAllData();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cattle.gender == CattleGender.male
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.pink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      cattle.gender == CattleGender.male ? Icons.male : Icons.female,
                      color: cattle.gender == CattleGender.male ? Colors.blue : Colors.pink,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cattle.earTag,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                cattle.ageCategoryDisplay,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cattle.genderDisplay,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cattle.status == CattleStatus.active
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cattle.statusDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cattle.status == CattleStatus.active ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Barn Info
              if (barn != null)
                Row(
                  children: [
                    Icon(Icons.home_work, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Ховар: ${barn.name}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              
              // Purchase Info
              if (purchase != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Харид: ${purchase.weightAtPurchase.toStringAsFixed(0)} кг',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    if (purchase.totalPrice != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        '•',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${purchase.totalPrice!.toStringAsFixed(0)} ${purchase.currency}',
                        style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ],
              
              // Latest Weight
              if (weights.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Вазни охирин: ${weights.last.weight.toStringAsFixed(0)} кг',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${DateFormat('dd.MM.yyyy').format(weights.last.measurementDate)})',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddCattlePurchaseScreen(cattleId: cattle.id!),
                          ),
                        );
                        context.read<CattleRegistryProvider>().loadAllData();
                      },
                      icon: const Icon(Icons.shopping_bag, size: 16),
                      label: const Text('Харид', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddCattleWeightScreen(cattleId: cattle.id!),
                          ),
                        );
                        context.read<CattleRegistryProvider>().loadAllData();
                      },
                      icon: const Icon(Icons.scale, size: 16),
                      label: const Text('Вазн', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        foregroundColor: Colors.purple,
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
  }
}

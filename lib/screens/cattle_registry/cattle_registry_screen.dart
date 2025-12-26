import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cattle_registry_provider.dart';
import '../../models/cattle_registry.dart';
import '../../theme/app_theme.dart';
import 'add_cattle_registry_screen.dart';
import 'cattle_registry_detail_screen.dart';

/// Cattle Registry Main Screen - Central cattle management
/// Shows master registry records only (identity data)
class CattleRegistryScreen extends StatefulWidget {
  const CattleRegistryScreen({super.key});

  @override
  State<CattleRegistryScreen> createState() => _CattleRegistryScreenState();
}

class _CattleRegistryScreenState extends State<CattleRegistryScreen> {
  String _searchQuery = '';
  CattleStatus? _statusFilter;
  CattleGender? _genderFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Реестри чорво'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Филтр',
          ),
          IconButton(
            onPressed: _showStatistics,
            icon: const Icon(Icons.analytics),
            tooltip: 'Омор',
          ),
        ],
      ),
      body: Consumer<CattleRegistryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredCattle = _getFilteredCattle(provider.cattleRegistry);

          return filteredCattle.isEmpty
              ? _buildEmptyState(context)
              : _buildCattleList(context, filteredCattle);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "cattle_registry_fab",
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddCattleRegistryScreen(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Илова кардан'),
        backgroundColor: AppTheme.primaryIndigo,
      ),
    );
  }

  Widget _buildSearchAndSummary(
    BuildContext context,
    CattleRegistryProvider provider,
    List<CattleRegistry> filteredCattle,
  ) {
    final stats = provider.overallStatistics;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Ҷустуҷӯи рамзи гӯш...',
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
                  'Ҳамагӣ',
                  '${stats['totalCattle']}',
                  Icons.pets,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Фаъол',
                  '${stats['activeCattle']}',
                  Icons.favorite,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Фурӯхта',
                  '${stats['soldCattle']}',
                  Icons.sell,
                  Colors.orange,
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCattleList(BuildContext context, List<CattleRegistry> cattle) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: cattle.length,
      itemBuilder: (context, index) {
        final cattleItem = cattle[index];
        return _buildCattleCard(context, cattleItem);
      },
    );
  }

  Widget _buildCattleCard(BuildContext context, CattleRegistry cattle) {
    final provider = context.read<CattleRegistryProvider>();
    final summary = provider.getCattleSummary(cattle.id!);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CattleRegistryDetailScreen(cattleId: cattle.id!),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Ear Tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryIndigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cattle.earTag,
                      style: TextStyle(
                        color: AppTheme.primaryIndigo,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cattle.status == CattleStatus.active
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cattle.statusDisplay,
                      style: TextStyle(
                        color: cattle.status == CattleStatus.active
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Details Row
              Row(
                children: [
                  _buildDetailChip(
                    Icons.male,
                    cattle.genderDisplay,
                    cattle.gender == CattleGender.male
                        ? Colors.blue
                        : Colors.pink,
                  ),
                  
                  const SizedBox(width: 8),
                  
                  _buildDetailChip(
                    Icons.cake,
                    cattle.ageCategoryDisplay,
                    Colors.purple,
                  ),
                  
                  const Spacer(),
                  
                  Text(
                    DateFormat('dd/MM/yyyy').format(cattle.registrationDate),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              // Summary Info
              if (summary['purchase'] != null) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Хариданӣ: ${(summary['purchase']?.totalCost ?? 0).toStringAsFixed(0)} TJS',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (summary['expenseCount'] > 0)
                      Text(
                        'Харочот: ${summary['expenseCount']} дона',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    if (summary['weightGain'] != null)
                      Text(
                        'Афзоиш: +${(summary['weightGain'] ?? 0).toStringAsFixed(1)} кг',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ҳеҷ чорво бақайд нашудааст',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Барои бақайдгирии чорвои нав тугмаи зеринро пахш кунед',
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
                builder: (_) => const AddCattleRegistryScreen(),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Чорвои нав илова кунед'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryIndigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<CattleRegistry> _getFilteredCattle(List<CattleRegistry> cattle) {
    return cattle.where((item) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        if (!item.earTag.toLowerCase().contains(_searchQuery)) {
          return false;
        }
      }

      // Status filter
      if (_statusFilter != null && item.status != _statusFilter) {
        return false;
      }

      // Gender filter
      if (_genderFilter != null && item.gender != _genderFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Филтр'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ҳолат:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Ҳама'),
                    selected: _statusFilter == null,
                    onSelected: (selected) {
                      setDialogState(() {
                        _statusFilter = selected ? null : _statusFilter;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Фаъол'),
                    selected: _statusFilter == CattleStatus.active,
                    onSelected: (selected) {
                      setDialogState(() {
                        _statusFilter = selected ? CattleStatus.active : null;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Фурӯхта'),
                    selected: _statusFilter == CattleStatus.sold,
                    onSelected: (selected) {
                      setDialogState(() {
                        _statusFilter = selected ? CattleStatus.sold : null;
                      });
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              const Text('Ҷинс:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Ҳама'),
                    selected: _genderFilter == null,
                    onSelected: (selected) {
                      setDialogState(() {
                        _genderFilter = selected ? null : _genderFilter;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Нар'),
                    selected: _genderFilter == CattleGender.male,
                    onSelected: (selected) {
                      setDialogState(() {
                        _genderFilter = selected ? CattleGender.male : null;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Мода'),
                    selected: _genderFilter == CattleGender.female,
                    onSelected: (selected) {
                      setDialogState(() {
                        _genderFilter = selected ? CattleGender.female : null;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _statusFilter = null;
                  _genderFilter = null;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Пок кардан'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('Татбиқ кардан'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatistics() {
    final provider = context.read<CattleRegistryProvider>();
    final stats = provider.overallStatistics;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Омори чорво'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Ҳамагӣ чорво:', '${stats['totalCattle']}'),
              _buildStatRow('Фаъол:', '${stats['activeCattle']}'),
              _buildStatRow('Фурӯхта шуда:', '${stats['soldCattle']}'),
              const Divider(),
              _buildStatRow('Ҳамагӣ хариданӣ:', '${(stats['totalPurchaseCost'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'} сомонӣ'),
              _buildStatRow('Ҳамагӣ харочот:', '${(stats['totalExpenses'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'} сомонӣ'),
              _buildStatRow('Ҳамагӣ фуруш:', '${(stats['totalSalesRevenue'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'} сомонӣ'),
              const Divider(),
              _buildStatRow(
                'Ҳамагӣ фоида:', 
                '${(stats['totalProfit'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'} сомонӣ',
                color: ((stats['totalProfit'] as num?)?.toDouble() ?? 0) >= 0 ? Colors.green : Colors.red,
              ),
              if (stats['soldCattle'] > 0)
                _buildStatRow(
                  'Миёнаи фоида:', 
                  '${(stats['averageProfitPerCattle'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '0'} сомонӣ',
                ),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/history_provider.dart';
import '../providers/cattle_registry_provider.dart';
import '../providers/cotton_registry_provider.dart';
import '../providers/cotton_warehouse_provider.dart';
import '../utils/data_persistence_manager.dart';
import '../theme/app_theme.dart';
import 'debt/simple_debts_screen.dart';
import 'cotton_warehouse/raw_cotton_warehouse_screen.dart';
import 'cotton_warehouse/processed_cotton_warehouse_screen.dart';
import 'cattle_registry/cattle_management_hub_screen.dart';
import 'cattle_registry/cattle_sale_screen.dart';
import 'cotton_registry/cotton_management_hub_screen.dart';
import 'cotton_registry/cotton_processing_registry_screen.dart';
import 'cotton_stock/cotton_stock_main_screen.dart';
import 'cotton_stock/cotton_sales_screen.dart';
import 'reports/reports_screen.dart';
import 'history_screen.dart';
import 'debt/persons_screen.dart';
import 'barn/barn_list_screen.dart';
import 'daily_expenses/today_expenses_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await DataPersistenceManager.initializeAllProviders(context);
      } catch (e) {
        debugPrint('Error initializing data: $e');
        // Fallback to individual initialization if manager fails
        _fallbackInitialization();
      }
    });
  }

  /// Fallback initialization method in case DataPersistenceManager fails
  void _fallbackInitialization() {
    try {
      context.read<AppProvider>().loadAllData();
      context.read<HistoryProvider>().loadAllHistory();
      context.read<CattleRegistryProvider>().loadAllData();
      context.read<CottonRegistryProvider>().loadAllData();
      context.read<CottonWarehouseProvider>().loadAllData();
      debugPrint('Fallback initialization completed');
    } catch (e) {
      debugPrint('Fallback initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _DashboardView(),
          const SimpleDebtsScreen(),
          const CottonManagementHubScreen(),
          const CattleManagementHubScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 80,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: Colors.white,
        elevation: 8,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined, size: 26), 
            selectedIcon: const Icon(Icons.home, size: 26), 
            label: 'Асосӣ',
            tooltip: 'Асосӣ',
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 26), 
            selectedIcon: const Icon(Icons.account_balance_wallet, size: 26), 
            label: 'Қарзҳо',
            tooltip: 'Қарзҳо',
          ),
          NavigationDestination(
            icon: const Icon(Icons.agriculture_outlined, size: 26), 
            selectedIcon: const Icon(Icons.agriculture, size: 26), 
            label: 'Пахта',
            tooltip: 'Пахта',
          ),
          NavigationDestination(
            icon: const Icon(Icons.pets_outlined, size: 26), 
            selectedIcon: const Icon(Icons.pets, size: 26), 
            label: 'Чорво',
            tooltip: 'Чорво',
          ),
        ],
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  _DashboardView();

  @override
  List<(String, String, IconData, String, VoidCallback)> _getDashboardItems(BuildContext context) {
    return [
      ('Идоракунии қарзҳо', 'Сабт ва пайгирии қарзҳо', Icons.account_balance_wallet, 'debt', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimpleDebtsScreen()))),
      ('Анбори пахтаи хом', 'Линт, слайвер ва дигар', Icons.warehouse, 'raw_warehouse', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RawCottonWarehouseScreen()))),
      ('Анбори пахтаи коркардшуда', 'Пахтаи тайёр дар қуттиҳо', Icons.inventory_2, 'processed_warehouse', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProcessedCottonWarehouseScreen()))),      
      ('Коркарди пахта', 'Реестри коркарди пахта', Icons.precision_manufacturing, 'cotton_processing', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CottonProcessingRegistryScreen()))),
      ('Сабти фурӯш', 'Сабти фурӯши пахта', Icons.point_of_sale, 'cotton_stock_sale', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CottonSalesScreen()))),
      ('Идоракунии захираи пахта', 'Нигаҳдорӣ ва идораи пахта', Icons.inventory, 'cotton_stock', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CottonStockMainScreen()))),
      ('Идоракунии оғулҳо', 'Ҷойгиркунӣ ва харочоти оғул', Icons.home_work, 'barn', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BarnListScreen()))),
      ('Фурӯши чорво', 'Сабти фурӯши чорво', Icons.sell_outlined, 'cattle_sale', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CattleSaleScreen()))),
      ('Чорво', 'Сабт ва пайгирии чорво', Icons.pets, 'cattle', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CattleManagementHubScreen()))),
      ('Идоракунии корбарон', 'Ашхос ва контактҳо', Icons.people, 'users', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonsScreen()))),
      ('Харочоти ҳаррӯза', 'Сабти харочоти рӯзона', Icons.receipt_long, 'daily_expense', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodayExpensesScreen()))),
      ('Ҳисоботҳо ва таҳлил', 'Маълумоти молиявӣ', Icons.bar_chart, 'report', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
    ];
  }

  Widget build(BuildContext context) {
    final dashboardItems = _getDashboardItems(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Асосӣ'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: dashboardItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = dashboardItems[index];
              return _buildModernListItem(context, item.$1, item.$2, item.$3, item.$4, item.$5);
            },
          );
        },
      ),
    );
  }

  Widget _buildModernListItem(BuildContext context, String title, String subtitle, IconData icon, String category, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon with colored background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: _getCategoryColor(category),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chevron icon
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'debt':
        return Colors.blue;
      case 'raw_warehouse':
        return Colors.green;
      case 'processed_warehouse':
        return Colors.orange;
      case 'cotton_processing':
        return Colors.purple;
      case 'cotton_stock_sale':
        return Colors.red;
      case 'cotton_stock':
        return Colors.teal;
      case 'barn':
        return Colors.brown;
      case 'cattle_sale':
        return Colors.pink;
      case 'cattle':
        return Colors.indigo;
      case 'users':
        return Colors.cyan;
      case 'daily_expense':
        return Colors.deepOrange;
      case 'report':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
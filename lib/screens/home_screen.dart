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
import 'cattle_registry/cattle_registry_screen.dart';
import 'cotton_registry/cotton_purchase_registry_screen.dart';
import 'cotton_registry/cotton_processing_registry_screen.dart';
import 'cotton_registry/cotton_sales_registry_screen.dart';
import 'cotton_stock/cotton_stock_main_screen.dart';
import 'reports/reports_screen.dart';
import 'history_screen.dart';
import 'debt/persons_screen.dart';
import 'barn/barn_list_screen.dart';

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
        children: const [
          _DashboardView(),
          SimpleDebtsScreen(),
          CottonPurchaseRegistryScreen(),
          CattleRegistryScreen(),
          HistoryScreen(),
          ReportsScreen(),
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
          NavigationDestination(
            icon: const Icon(Icons.history_outlined, size: 26), 
            selectedIcon: const Icon(Icons.history, size: 26), 
            label: 'Таърих',
            tooltip: 'Таърих',
          ),
          NavigationDestination(
            icon: const Icon(Icons.analytics_outlined, size: 26), 
            selectedIcon: const Icon(Icons.analytics, size: 26), 
            label: 'Ҳисоботҳо',
            tooltip: 'Ҳисоботҳо',
          ),
        ],
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Асосӣ'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());

          return SingleChildScrollView(
            child: Column(
              children: [
                
                // Portfolio grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: 11,
                    itemBuilder: (context, index) {
                      final items = [
                        ('Идоракунии қарзҳо', 'Сабт ва пайгирии қарзҳо', Icons.account_balance_wallet, 'debt', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimpleDebtsScreen()))),
                        ('Анбори пахтаи хом', 'Линт, слайвер ва дигар', Icons.warehouse, 'raw_warehouse', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RawCottonWarehouseScreen()))),
                        ('Анбори пахтаи коркардшуда', 'Пахтаи тайёр дар қуттиҳо', Icons.inventory_2, 'processed_warehouse', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProcessedCottonWarehouseScreen()))),
                        ('Харидании пахта', 'Реестри харидани пахта', Icons.shopping_cart, 'cotton_purchase', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CottonPurchaseRegistryScreen()))),
                        ('Коркарди пахта', 'Реестри коркарди пахта', Icons.precision_manufacturing, 'cotton_processing', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CottonProcessingRegistryScreen()))),
                        ('Фурӯши пахта', 'Реестри фурӯши пахта', Icons.sell, 'cotton_sales', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CottonSalesRegistryScreen()))),
                        ('Идоракунии захираи пахта', 'Нигаҳдорӣ ва идораи пахта', Icons.inventory, 'cotton_stock', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CottonStockMainScreen()))),
                        ('Идоракунии ховарҳо', 'Ҷойгиркунӣ ва харочоти ховар', Icons.home_work, 'barn', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BarnListScreen()))),
                        ('Реестри чорво', 'Идоракунии чорво', Icons.pets, 'cattle', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CattleRegistryScreen()))),
                        ('Идоракунии корбарон', 'Ашхос ва контактҳо', Icons.people, 'users', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonsScreen()))),
                        ('Ҳисоботҳо ва таҳлил', 'Маълумоти молиявӣ', Icons.bar_chart, 'report', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
                      ];
                      
                      final item = items[index];
                      return _buildModernPortfolioCard(context, item.$1, item.$2, item.$3, item.$4, item.$5);
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernPortfolioCard(BuildContext context, String title, String subtitle, IconData icon, String category, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with colored background
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.getIconBackgroundColor(category),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.getIconColor(category),
                    size: 28,
                  ),
                ),
                const Spacer(),
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Subtitle
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

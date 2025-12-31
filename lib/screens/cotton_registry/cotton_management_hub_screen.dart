import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cotton_registry_provider.dart';
import '../../providers/cotton_warehouse_provider.dart';
import '../../theme/app_theme.dart';
import 'cotton_purchase_registry_screen.dart';
import 'cotton_processing_registry_screen.dart';
import '../cotton_stock/cotton_sales_screen.dart';
import '../cotton_warehouse/raw_cotton_warehouse_screen.dart';
import '../cotton_warehouse/processed_cotton_warehouse_screen.dart';

class CottonManagementHubScreen extends StatelessWidget {
  const CottonManagementHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Идоракунии пахта'),
        backgroundColor: AppTheme.primaryIndigo,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<CottonRegistryProvider, CottonWarehouseProvider>(
        builder: (context, cottonProvider, warehouseProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [                                
                const SizedBox(height: 32),
                
                // Main Action Buttons
                const Text(
                  'Амалиётҳо',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Buy Cotton Button
                _buildActionCard(
                  context: context,
                  title: 'Хариди пахта',
                  subtitle: 'Харидҳои нави пахтаро сабт кунед',
                  icon: Icons.add_shopping_cart,
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CottonPurchaseRegistryScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Process Cotton Button
                _buildActionCard(
                  context: context,
                  title: 'Коркарди пахта',
                  subtitle: 'Пахтаи хомро коркард кунед',
                  icon: Icons.settings_suggest,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CottonProcessingRegistryScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Sell Cotton Button
                _buildActionCard(
                  context: context,
                  title: 'Фурӯши пахта',
                  subtitle: 'Пахтаи фурӯхтаро сабт кунед',
                  icon: Icons.sell,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CottonSalesScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Storage Section
                const Text(
                  'Анборҳо',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Raw Cotton Storage Button
                _buildActionCard(
                  context: context,
                  title: 'Анбори пахтаи хом',                  
                  icon: Icons.warehouse,
                  color: Colors.brown,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RawCottonWarehouseScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Processed Cotton Storage Button
                _buildActionCard(
                  context: context,
                  title: 'Анбори пахтаи коркардшуда',
                  subtitle: 'Пахтаи коркардшударо дида баромадед',
                  icon: Icons.inventory_2,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProcessedCottonWarehouseScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
 
  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightStatItem({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: 24,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

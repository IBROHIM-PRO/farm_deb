import 'package:flutter/material.dart';
import '../cotton_registry/cotton_purchase_registry_screen.dart';
import '../cotton_registry/cotton_processing_registry_screen.dart';
import 'cotton_stock_overview_screen.dart';
import '../cotton_registry/add_cotton_purchase_screen.dart';
import '../cotton_registry/add_cotton_processing_screen.dart';
import '../cotton_registry/cotton_sales_registry_screen.dart';

class CottonStockMainScreen extends StatelessWidget {
  const CottonStockMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotton Stock Management'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildModuleCard(
              context,
              'Stock Overview',
              'View current cotton stock levels by type',
              Icons.inventory,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CottonStockOverviewScreen()),
              ),
            ),
            _buildModuleCard(
              context,
              'Purchase Registry',
              'Record cotton purchases from suppliers',
              Icons.add_box,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CottonPurchaseRegistryScreen()),
              ),
            ),
            _buildModuleCard(
              context,
              'Inventory Status',
              'View processed cotton inventory levels',
              Icons.warehouse,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CottonStockOverviewScreen()),
              ),
            ),
            _buildModuleCard(
              context,
              'Processing',
              'Cotton processing registry with auto calculations',
              Icons.settings,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CottonProcessingRegistryScreen()),
              ),
            ),
            _buildModuleCard(
              context,
              'Sales Registry',
              'Sell processed cotton with inventory tracking',
              Icons.shopping_cart,
              Colors.teal,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CottonSalesRegistryScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

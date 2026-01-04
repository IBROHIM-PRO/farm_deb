import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cattle_registry_provider.dart';
import '../../theme/app_theme.dart';
import 'add_cattle_registry_screen.dart';
import 'cattle_sale_screen.dart';
import '../debt/persons_screen.dart';
import '../barn/barn_list_screen.dart';

class CattleManagementHubScreen extends StatelessWidget {
  const CattleManagementHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Идоракунии чорво'),
        backgroundColor: AppTheme.primaryIndigo,
        foregroundColor: Colors.white,        
      ),
      body: Consumer<CattleRegistryProvider>(
        builder: (context, provider, _) {
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
                
                // Buy Cattle Button
                _buildActionCard(
                  context: context,
                  title: 'Хариди чорво',
                  subtitle: 'Чорвои нав ба реестр илова кунед',
                  icon: Icons.add_shopping_cart,
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddCattleRegistryScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Sell Cattle Button
                _buildActionCard(
                  context: context,
                  title: 'Фурӯши чорво',
                  subtitle: 'Чорвои фурӯхтаро сабт кунед',
                  icon: Icons.sell,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CattleSaleScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Barns Button
                _buildActionCard(
                  context: context,
                  title: 'Оғулҳо',
                  subtitle: 'Идоракунии оғулҳо ва ҷойгирии чорво',
                  icon: Icons.home_work,
                  color: Colors.brown,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BarnListScreen(),
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

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
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
}

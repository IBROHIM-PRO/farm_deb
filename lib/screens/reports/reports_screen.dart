import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, double>? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final stats = await context.read<AppProvider>().getStatistics();
    setState(() { _statistics = stats; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Statistics'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () { setState(() => _isLoading = true); _loadStatistics(); })]),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Consumer<AppProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () async { await provider.loadAllData(); await _loadStatistics(); },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfitCard(context),
                const SizedBox(height: 16),
                _buildIncomeCard(context),
                const SizedBox(height: 16),
                _buildExpensesCard(context),
                const SizedBox(height: 16),
                _buildDebtSummary(context, provider),
                const SizedBox(height: 16),
                _buildCottonSummary(context, provider),
                const SizedBox(height: 16),
                _buildCattleSummary(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfitCard(BuildContext context) {
    final profit = _statistics?['profit'] ?? 0;
    final isProfit = profit >= 0;
    return Card(child: Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: isProfit ? [Colors.green.shade400, Colors.green.shade600] : [Colors.red.shade400, Colors.red.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(isProfit ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 28), const SizedBox(width: 8), Text(isProfit ? 'Farm Profit' : 'Farm Loss', style: const TextStyle(color: Colors.white, fontSize: 16))]), const SizedBox(height: 12), Text('${isProfit ? '+' : ''}${profit.toStringAsFixed(2)} TJS', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('Income: ${(_statistics?['totalIncome'] ?? 0).toStringAsFixed(2)} TJS | Costs: ${(_statistics?['totalCosts'] ?? 0).toStringAsFixed(2)} TJS', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12))])));
  }

  Widget _buildIncomeCard(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.arrow_upward, color: Colors.green)), const SizedBox(width: 12), Text('Income', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const Spacer(), Text('${(_statistics?['totalIncome'] ?? 0).toStringAsFixed(2)} TJS', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green))]), const Divider(height: 24), _buildStatRow('Cotton Sales', '${(_statistics?['totalCottonSales'] ?? 0).toStringAsFixed(2)} TJS', Icons.grass, Colors.orange), const SizedBox(height: 8), _buildStatRow('Cattle Sales', '${(_statistics?['totalCattleSales'] ?? 0).toStringAsFixed(2)} TJS', Icons.pets, Colors.brown)])));
  }

  Widget _buildExpensesCard(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.arrow_downward, color: Colors.red)), const SizedBox(width: 12), Text('Expenses', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const Spacer(), Text('${(_statistics?['totalCosts'] ?? 0).toStringAsFixed(2)} TJS', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red))]), const Divider(height: 24), _buildStatRow('Field Activities', '${(_statistics?['totalFieldCosts'] ?? 0).toStringAsFixed(2)} TJS', Icons.agriculture, Colors.green), const SizedBox(height: 8), _buildStatRow('Cattle Purchases', '${(_statistics?['totalCattlePurchases'] ?? 0).toStringAsFixed(2)} TJS', Icons.shopping_cart, Colors.blue), const SizedBox(height: 8), _buildStatRow('Cattle Care', '${(_statistics?['totalCattleRecordCosts'] ?? 0).toStringAsFixed(2)} TJS', Icons.medical_services, Colors.purple)])));
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) => Row(children: [Icon(icon, size: 20, color: color), const SizedBox(width: 12), Text(label), const Spacer(), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]);

  Widget _buildDebtSummary(BuildContext context, AppProvider provider) {
    final totals = provider.getDebtTotalsByCurrency();
    double totalGiven = 0, totalTaken = 0;
    for (final t in totals.values) { totalGiven += t['given'] ?? 0; totalTaken += t['taken'] ?? 0; }

    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.account_balance_wallet, color: Colors.indigo)), const SizedBox(width: 12), Text('Debt Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))]), const SizedBox(height: 16), Row(children: [Expanded(child: _buildMiniStat('Given', '${totalGiven.toStringAsFixed(2)}', Colors.green)), Expanded(child: _buildMiniStat('Taken', '${totalTaken.toStringAsFixed(2)}', Colors.red)), Expanded(child: _buildMiniStat('Balance', '${(totalGiven - totalTaken).toStringAsFixed(2)}', totalGiven >= totalTaken ? Colors.green : Colors.red))])])));
  }

  Widget _buildCottonSummary(BuildContext context, AppProvider provider) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.grass, color: Colors.orange)), const SizedBox(width: 12), Text('Cotton Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))]), const SizedBox(height: 16), Row(children: [Expanded(child: _buildMiniStat('Fields', provider.fields.length.toString(), Colors.green)), Expanded(child: _buildMiniStat('Harvested', '${provider.totalCottonHarvested.toStringAsFixed(1)} kg', Colors.orange)), Expanded(child: _buildMiniStat('Processed', '${provider.totalCottonProcessed.toStringAsFixed(1)} kg', Colors.blue))])])));
  }

  Widget _buildCattleSummary(BuildContext context, AppProvider provider) {
    final totalWeight = provider.activeCattle.fold(0.0, (s, c) => s + c.currentWeight);
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.brown.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.pets, color: Colors.brown)), const SizedBox(width: 12), Text('Cattle Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))]), const SizedBox(height: 16), Row(children: [Expanded(child: _buildMiniStat('Active', provider.activeCattle.length.toString(), Colors.green)), Expanded(child: _buildMiniStat('Sold', provider.soldCattle.length.toString(), Colors.blue)), Expanded(child: _buildMiniStat('Total Weight', '${totalWeight.toStringAsFixed(1)} kg', Colors.orange))])])));
  }

  Widget _buildMiniStat(String label, String value, Color color) => Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)), Text(label, style: TextStyle(color: color, fontSize: 11))]));
}

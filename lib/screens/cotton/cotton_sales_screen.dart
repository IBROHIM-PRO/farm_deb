import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/cotton_sale.dart';
import 'buyer_cotton_history_screen.dart';

class CottonSalesScreen extends StatelessWidget {
  const CottonSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cotton Sales')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.cottonSales.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.point_of_sale_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(height: 16), const Text('No sales recorded'), const SizedBox(height: 8), ElevatedButton.icon(onPressed: () => _showAddSaleDialog(context), icon: const Icon(Icons.add), label: const Text('Add Sale'))]));
          }

          final totalSales = provider.cottonSales.fold(0.0, (s, sale) => s + sale.totalAmount);
          final pendingPayments = provider.cottonSales.where((s) => s.paymentStatus != PaymentStatus.paid).fold(0.0, (s, sale) => s + sale.remainingAmount);

          // Group sales by buyer name
          final groupedSales = <String, List<CottonSale>>{};
          for (final sale in provider.cottonSales) {
            final buyerName = sale.buyerName ?? 'Unknown Buyer';
            groupedSales.putIfAbsent(buyerName, () => []).add(sale);
          }

          final buyerNames = groupedSales.keys.toList()..sort();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 16), Row(children: [Expanded(child: _buildSummaryItem(context, 'Total Sales', '${totalSales.toStringAsFixed(0)} TJS', Icons.attach_money, Colors.green)), const SizedBox(width: 12), Expanded(child: _buildSummaryItem(context, 'Pending', '${pendingPayments.toStringAsFixed(0)} TJS', Icons.pending, Colors.orange))])]))),
              const SizedBox(height: 16),
              ...buyerNames.map((buyerName) => _buildBuyerCard(context, buyerName, groupedSales[buyerName]!)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(heroTag: "cotton_sales_fab", onPressed: () => _showAddSaleDialog(context), child: const Icon(Icons.add)),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 24), const SizedBox(height: 8), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)), Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color))]));
  }

  Widget _buildBuyerCard(BuildContext context, String buyerName, List<CottonSale> sales) {
    // Calculate totals for this buyer
    final totalAmount = sales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
    final totalPaid = sales.fold(0.0, (sum, sale) => sum + sale.paidAmount);
    final totalRemaining = totalAmount - totalPaid;
    final latestDate = sales.map((s) => s.date).reduce((a, b) => a.isAfter(b) ? a : b);
    
    final totalWeight = sales.fold(0.0, (sum, sale) => sum + (sale.weight ?? 0.0));
    final totalUnits = sales.fold(0, (sum, sale) => sum + (sale.units ?? 0));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToBuyerHistory(context, buyerName),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.person, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            buyerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Охирин харид: ${DateFormat('dd/MM/yyyy').format(latestDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${sales.length} фуруш',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (totalWeight > 0) ...[
                      Column(
                        children: [
                          Text(
                            '${totalWeight.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          Text(
                            'кг',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                    ],
                    if (totalUnits > 0) ...[
                      Column(
                        children: [
                          Text(
                            '$totalUnits',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            'шт',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                    ],
                    Column(
                      children: [
                        Text(
                          '${totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'TJS',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (totalRemaining > 0) ...[
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      Column(
                        children: [
                          Text(
                            '${totalRemaining.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            'боқимонда',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToBuyerHistory(BuildContext context, String buyerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BuyerCottonHistoryScreen(
          buyerName: buyerName,
        ),
      ),
    );
  }

  void _showSaleDetails(BuildContext context, CottonSale sale) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Sale Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDetailRow('Buyer', sale.buyerName ?? 'Unknown'),
            _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(sale.date)),
            _buildDetailRow('Quantity', sale.saleType == SaleType.byWeight ? '${sale.weight?.toStringAsFixed(0)} kg' : '${sale.units} units'),
            _buildDetailRow('Total', '${sale.totalAmount.toStringAsFixed(0)} ${sale.currency}'),
            _buildDetailRow('Paid', '${sale.paidAmount.toStringAsFixed(0)} ${sale.currency}'),
            _buildDetailRow('Remaining', '${sale.remainingAmount.toStringAsFixed(0)} ${sale.currency}'),
            const SizedBox(height: 16),
            if (sale.paymentStatus != PaymentStatus.paid) SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(ctx); _showRecordPaymentDialog(context, sale); }, child: const Text('Record Payment'))),
          ]),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]));

  void _showRecordPaymentDialog(BuildContext context, CottonSale sale) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Пардохти сабтшуда'),
        content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Remaining: ${sale.remainingAmount.toStringAsFixed(0)} ${sale.currency}'), const SizedBox(height: 16), TextFormField(controller: amountController, decoration: InputDecoration(labelText: 'Amount', suffixText: sale.currency), keyboardType: TextInputType.number, validator: (v) { if (v?.isEmpty == true) return 'Required'; final a = double.tryParse(v!); if (a == null || a <= 0 || a > sale.remainingAmount) return 'Invalid'; return null; }), TextButton(onPressed: () => amountController.text = sale.remainingAmount.toStringAsFixed(0), child: const Text('Pay Full Amount'))])),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () async { if (formKey.currentState!.validate()) { final amount = double.parse(amountController.text); final newPaid = sale.paidAmount + amount; await ctx.read<AppProvider>().updateCottonSale(sale.copyWith(paidAmount: newPaid, paymentStatus: newPaid >= sale.totalAmount ? PaymentStatus.paid : PaymentStatus.partial)); if (ctx.mounted) Navigator.pop(ctx); } }, child: const Text('Record'))],
      ),
    );
  }

  void _showAddSaleDialog(BuildContext context) {
    final weightController = TextEditingController();
    final unitsController = TextEditingController();
    final priceController = TextEditingController();
    final buyerController = TextEditingController();
    final paidAmountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    SaleType saleType = SaleType.byWeight;
    DateTime date = DateTime.now();
    bool isInstallment = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Cotton Sale'),
          content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            SegmentedButton<SaleType>(segments: const [ButtonSegment(value: SaleType.byWeight, label: Text('By Weight')), ButtonSegment(value: SaleType.byUnits, label: Text('By Units'))], selected: {saleType}, onSelectionChanged: (s) => setState(() => saleType = s.first)),
            const SizedBox(height: 16),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today), title: Text(DateFormat('MMM dd, yyyy').format(date)), onTap: () async { final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now()); if (d != null) setState(() => date = d); }),
            const SizedBox(height: 8),
            if (saleType == SaleType.byWeight) TextFormField(controller: weightController, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: TextInputType.number, validator: (v) => saleType == SaleType.byWeight && v?.isEmpty == true ? 'Required' : null) else TextFormField(controller: unitsController, decoration: const InputDecoration(labelText: 'Units'), keyboardType: TextInputType.number, validator: (v) => saleType == SaleType.byUnits && v?.isEmpty == true ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: priceController, decoration: InputDecoration(labelText: 'Price per ${saleType == SaleType.byWeight ? 'kg' : 'unit'}', suffixText: 'TJS'), keyboardType: TextInputType.number, validator: (v) => v?.isEmpty == true ? 'Required' : null),
            const SizedBox(height: 16),
            // Buyer Name with Autocomplete
            Autocomplete<String>(
              initialValue: TextEditingValue(text: buyerController.text),
              optionsBuilder: (TextEditingValue textEditingValue) async {
                try {
                  // Always get all buyer names first
                  final allBuyers = await context.read<AppProvider>().getBuyerNames();
                  
                  // If input is empty, return all buyers
                  if (textEditingValue.text.isEmpty) {
                    return allBuyers;
                  }
                  
                  // Filter buyers based on input
                  final query = textEditingValue.text.toLowerCase();
                  return allBuyers.where((buyer) => 
                    buyer.toLowerCase().contains(query)).toList();
                } catch (e) {
                  // Return empty list if there's an error
                  return <String>[];
                }
              },
              onSelected: (String selection) {
                buyerController.text = selection;
              },
              fieldViewBuilder: (
                BuildContext context,
                TextEditingController fieldTextEditingController,
                FocusNode fieldFocusNode,
                VoidCallback onFieldSubmitted,
              ) {
                // Sync with our main controller
                fieldTextEditingController.addListener(() {
                  buyerController.text = fieldTextEditingController.text;
                });
                
                return TextFormField(
                  controller: fieldTextEditingController,
                  focusNode: fieldFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Buyer Name',
                    prefixIcon: Icon(Icons.person),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                    hintText: 'Enter or select buyer name',
                  ),
                  textCapitalization: TextCapitalization.words,
                  onFieldSubmitted: (value) => onFieldSubmitted(),
                );
              },
              optionsViewBuilder: (
                BuildContext context,
                AutocompleteOnSelected<String> onSelected,
                Iterable<String> options,
              ) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person, 
                                    color: Colors.blue, 
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Pay in installments'),
              subtitle: const Text('Allow partial payment'),
              value: isInstallment,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) async {
                if (value) {
                  final confirmed = await showDialog<bool>(
                    context: ctx,
                    builder: (c) => AlertDialog(
                      title: const Text('Installment Payment'),
                      content: const Text('Do you want to enable installment payment for this sale?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
                        ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Yes')),
                      ],
                    ),
                  );
                  if (confirmed == true) setState(() => isInstallment = true);
                } else {
                  setState(() => isInstallment = false);
                }
              },
            ),
            if (isInstallment) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: paidAmountController,
                decoration: const InputDecoration(labelText: 'Initial Payment (TJS)', hintText: 'Enter amount paid now'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (isInstallment && v?.isNotEmpty == true) {
                    final paid = double.tryParse(v!);
                    if (paid == null || paid < 0) return 'Invalid amount';
                    final weight = saleType == SaleType.byWeight ? double.tryParse(weightController.text) ?? 0 : 0.0;
                    final units = saleType == SaleType.byUnits ? int.tryParse(unitsController.text) ?? 0 : 0;
                    final price = double.tryParse(priceController.text) ?? 0;
                    final total = saleType == SaleType.byWeight ? weight * price : units * price;
                    if (paid > total) return 'Exceeds total';
                  }
                  return null;
                },
              ),
            ],
          ]))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () async {
              if (formKey.currentState!.validate()) {
                final weight = saleType == SaleType.byWeight ? double.parse(weightController.text) : null;
                final units = saleType == SaleType.byUnits ? int.parse(unitsController.text) : null;
                final price = double.parse(priceController.text);
                final total = saleType == SaleType.byWeight ? weight! * price : units! * price;
                final paidAmount = isInstallment && paidAmountController.text.isNotEmpty ? double.parse(paidAmountController.text) : total;
                final paymentStatus = paidAmount >= total ? PaymentStatus.paid : (paidAmount > 0 ? PaymentStatus.partial : PaymentStatus.pending);
                await ctx.read<AppProvider>().addCottonSale(CottonSale(
                  date: date,
                  saleType: saleType,
                  weight: weight,
                  units: units,
                  pricePerUnit: price,
                  totalAmount: total,
                  paidAmount: paidAmount,
                  paymentStatus: paymentStatus,
                  buyerName: buyerController.text.isEmpty ? null : buyerController.text.trim(),
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              }
            }, child: const Text('Add')),
          ],
        ),
      ),
    );
  }
}

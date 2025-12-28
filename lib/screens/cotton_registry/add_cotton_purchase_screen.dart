import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cotton_registry_provider.dart';
import '../../models/cotton_purchase_registry.dart';
import '../../models/cotton_purchase_item.dart';
import '../../theme/app_theme.dart';

/// Add Cotton Purchase Screen - Registry Master+Items pattern
/// One purchase can contain 1-3 cotton types (Lint, Uluk, Valakno)
class AddCottonPurchaseScreen extends StatefulWidget {
  const AddCottonPurchaseScreen({super.key});

  @override
  State<AddCottonPurchaseScreen> createState() => _AddCottonPurchaseScreenState();
}

class _AddCottonPurchaseScreenState extends State<AddCottonPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supplierController = TextEditingController();
  final _transportationCostController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _purchaseDate = DateTime.now();
  bool _isLoading = false;

  // Cotton Items Management
  final List<CottonPurchaseItemData> _cottonItems = [];

  @override
  void initState() {
    super.initState();
    // Start with one cotton item
    _addCottonItem();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Харидании нави пахта'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Purchase Info (Supplier only, no date selection)
              _buildPurchaseInfoSection(),

              const SizedBox(height: 24),

              // Cotton Items Section
              _buildCottonItemsSection(),

              const SizedBox(height: 24),

              // Transportation Cost
              TextFormField(
                controller: _transportationCostController,
                decoration: InputDecoration(
                  labelText: 'Хароҷоти нақлиёт',
                  suffixText: 'с',
                  prefixIcon: const Icon(Icons.local_shipping, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  hintText: 'Хароҷоти нақлиётро дарҷ кунед',
                ),
                keyboardType: TextInputType.number,
              ),              
              const SizedBox(height: 24),

              // Purchase Summary
              _buildPurchaseSummary(),

              const SizedBox(height: 32),

              // Save Button
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Маълумоти хариданӣ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Supplier Name with Autocomplete
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _supplierController.text),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            try {
              // Always get all supplier names first
              final allSuppliers = await context.read<CottonRegistryProvider>().getSupplierNames();
              
              // If input is empty, return all suppliers
              if (textEditingValue.text.isEmpty) {
                return allSuppliers;
              }
              
              // Filter suppliers based on input
              final query = textEditingValue.text.toLowerCase();
              return allSuppliers.where((supplier) => 
                supplier.toLowerCase().contains(query)).toList();
            } catch (e) {
              // Return empty list if there's an error
              return <String>[];
            }
          },
          onSelected: (String selection) {
            _supplierController.text = selection;
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
          ) {
            // Sync with our main controller
            fieldTextEditingController.addListener(() {
              _supplierController.text = fieldTextEditingController.text;
            });
            
            return TextFormField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              decoration: InputDecoration(
                labelText: 'Номи таъминкунанда',
                prefixIcon: const Icon(Icons.person, color: Colors.green),
                suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],                
              ),
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value?.trim().isEmpty == true) {
                  return 'Номи таъминкунанда зарур аст';
                }
                return null;
              },
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
                                color: Colors.green, 
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
      ],
    );
  }

  Widget _buildCottonItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Навъҳои пахта', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${_cottonItems.length}/3 навъ', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _cottonItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildCottonItemCard(index),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (_cottonItems.length < 3)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addCottonItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Навъи дигар илова кунед'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.green, side: const BorderSide(color: Colors.green)),
                ),
              ),
            if (_cottonItems.length > 1) ...[
              if (_cottonItems.length < 3) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _removeCottonItem,
                  icon: const Icon(Icons.remove),
                  label: const Text('Навъи охиринро нест кунед'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCottonItemCard(int index) {
    final item = _cottonItems[index];
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Навъи пахта ${index + 1}:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildCottonTypeChip(index, CottonType.lint, 'Линт', Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _buildCottonTypeChip(index, CottonType.uluk, 'Улук', Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _buildCottonTypeChip(index, CottonType.valakno, 'Валакно', Colors.orange)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.weightController,
                    decoration: InputDecoration(
                      labelText: 'Вазн',
                      suffixText: 'кг',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.trim().isEmpty == true) return 'Вазн зарур аст';
                      if (double.tryParse(value!) == null) return 'Адади дуруст ворид кунед';
                      return null;
                    },
                    onChanged: (value) => _calculateTotalPrice(index),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: item.unitsController,
                    decoration: InputDecoration(
                      labelText: 'Донаҳо',
                      suffixText: 'шт',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.trim().isEmpty == true) return 'Донаҳо зарур аст';
                      if (int.tryParse(value!) == null) return 'Адади дуруст ворид кунед';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.pricePerKgController,
                    decoration: InputDecoration(
                      labelText: 'Нархи як кг',                      
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.trim().isEmpty == true) return 'Нарх зарур аст';
                      if (double.tryParse(value!) == null) return 'Адади дуруст ворид кунед';
                      return null;
                    },
                    onChanged: (value) => _calculateTotalPrice(index),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ҳамагӣ нарх:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        Text('${item.totalPrice.toStringAsFixed(0)} с',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
                ),
              ],
            ),            
          ],
        ),
      ),
    );
  }

  Widget _buildCottonTypeChip(int itemIndex, CottonType type, String label, Color color) {
    final isSelected = _cottonItems[itemIndex].cottonType == type;
    final isDisabled = _isTypeAlreadySelected(type, itemIndex);
    return GestureDetector(
      onTap: isDisabled ? null : () => setState(() => _cottonItems[itemIndex].cottonType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.withOpacity(0.1) : isSelected ? color.withOpacity(0.2) : Colors.grey[50],
          border: Border.all(
            color: isDisabled ? Colors.grey.withOpacity(0.3) : isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(
              color: isDisabled ? Colors.grey : isSelected ? color : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            )),
            if (isDisabled) Text('Интихоб шуда', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseSummary() {
    final totalWeight = _cottonItems.fold(0.0, (sum, item) => sum + (double.tryParse(item.weightController.text) ?? 0));
    final totalUnits = _cottonItems.fold(0, (sum, item) => sum + (int.tryParse(item.unitsController.text) ?? 0));
    final subtotal = _cottonItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final transportCost = double.tryParse(_transportationCostController.text) ?? 0;
    final grandTotal = subtotal + transportCost;

    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Хулосаи хариданӣ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Ҳамагӣ вазн:'),
              Text('${totalWeight.toStringAsFixed(1)} кг', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Ҳамагӣ донаҳо:'),
              Text('$totalUnits шт', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Нархи пахта:'),
              Text('${subtotal.toStringAsFixed(0)} с', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            if (transportCost > 0) ...[
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Харҷи интиқол:'),
                Text('${transportCost.toStringAsFixed(0)} с', style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ],
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Ҳамагӣ харҷ:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${grandTotal.toStringAsFixed(0)} с', 
                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _savePurchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Хариданӣ сабт кардан', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _addCottonItem() {
    if (_cottonItems.length < 3) {
      setState(() {
        final availableType = _getNextAvailableCottonType();
        _cottonItems.add(CottonPurchaseItemData(cottonType: availableType));
      });
    }
  }

  void _removeCottonItem() {
    if (_cottonItems.length > 1) {
      setState(() {
        final removed = _cottonItems.removeLast();
        removed.dispose();
      });
    }
  }

  CottonType _getNextAvailableCottonType() {
    final usedTypes = _cottonItems.map((item) => item.cottonType).toSet();
    for (final type in CottonType.values) {
      if (!usedTypes.contains(type)) return type;
    }
    return CottonType.lint;
  }

  bool _isTypeAlreadySelected(CottonType type, int currentIndex) {
    for (int i = 0; i < _cottonItems.length; i++) {
      if (i != currentIndex && _cottonItems[i].cottonType == type) return true;
    }
    return false;
  }

  void _calculateTotalPrice(int index) {
    final item = _cottonItems[index];
    final weight = double.tryParse(item.weightController.text) ?? 0;
    final pricePerKg = double.tryParse(item.pricePerKgController.text) ?? 0;
    setState(() => item.totalPrice = weight * pricePerKg);
  }

  Future<void> _savePurchase() async {
    if (_formKey.currentState!.validate()) {
      for (final item in _cottonItems) {
        if (item.weightController.text.trim().isEmpty ||
            item.unitsController.text.trim().isEmpty ||
            item.pricePerKgController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ҳама маълумоти пахтаро пур кунед'), backgroundColor: Colors.red),
          );
          return;
        }
      }

      setState(() => _isLoading = true);

      try {
        final registry = CottonPurchaseRegistry(
          purchaseDate: DateTime.now(),
          supplierName: _supplierController.text.trim(),
          transportationCost: double.tryParse(_transportationCostController.text) ?? 0,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );

        final items = _cottonItems.map((itemData) {
          final weight = double.parse(itemData.weightController.text);
          final pricePerKg = double.parse(itemData.pricePerKgController.text);
          return CottonPurchaseItem(
            purchaseId: 0,
            cottonType: itemData.cottonType,
            weight: weight,
            units: int.parse(itemData.unitsController.text),
            pricePerKg: pricePerKg,
            totalPrice: weight * pricePerKg,
            notes: itemData.notesController.text.trim().isNotEmpty ? itemData.notesController.text.trim() : null,
          );
        }).toList();

        await context.read<CottonRegistryProvider>().addCottonPurchase(registry: registry, items: items);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Харидании пахта бомуваффақият сабт шуд'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Хатогӣ: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _transportationCostController.dispose();
    _notesController.dispose();
    for (final item in _cottonItems) {
      item.dispose();
    }
    super.dispose();
  }
}

/// Helper class to manage cotton purchase item data
class CottonPurchaseItemData {
  CottonType cottonType;
  final TextEditingController weightController = TextEditingController();
  final TextEditingController unitsController = TextEditingController();
  final TextEditingController pricePerKgController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  double totalPrice = 0.0;

  CottonPurchaseItemData({required this.cottonType});

  void dispose() {
    weightController.dispose();
    unitsController.dispose();
    pricePerKgController.dispose();
    notesController.dispose();
  }
}

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
              // Header Info
              _buildHeaderCard(),

              const SizedBox(height: 24),

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
                  suffixText: 'сомонӣ',
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

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Эзоҳоти умумӣ',
                  prefixIcon: const Icon(Icons.note, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  hintText: 'Эзоҳоти хариданӣро дарҷ кунед (ихтиёрӣ)',
                ),
                keyboardType: TextInputType.text,
                maxLines: 3,
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

        // Supplier Name
        TextFormField(
          controller: _supplierController,
          decoration: InputDecoration(
            labelText: 'Номи таъминкунанда',
            prefixIcon: const Icon(Icons.person, color: Colors.green),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            hintText: 'Номи таъминкунандаро дарҷ кунед',
          ),
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value?.trim().isEmpty == true) {
              return 'Номи таъминкунанда зарур аст';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ... Қисмҳои дигар ҳеҷ тағйир наёфтаанд, ба монанди _buildCottonItemsSection, _buildCottonItemCard, _buildPurchaseSummary, _buildSaveButton, _addCottonItem, _removeCottonItem, _calculateTotalPrice ва _savePurchase

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

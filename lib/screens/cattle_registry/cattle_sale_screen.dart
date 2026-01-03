import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cattle_registry_provider.dart';
import '../../providers/barn_provider.dart';
import '../../models/cattle_sale.dart';
import '../../models/cattle_registry.dart';
import '../../models/barn.dart';
import '../../theme/app_theme.dart';

class CattleSaleScreen extends StatefulWidget {
  const CattleSaleScreen({super.key});

  @override
  State<CattleSaleScreen> createState() => _CattleSaleScreenState();
}

class _CattleSaleScreenState extends State<CattleSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _liveWeightController = TextEditingController();
  final _meatWeightController = TextEditingController();
  final _pricePerKgController = TextEditingController();
  final _fixedPriceController = TextEditingController();
  final _buyerNameController = TextEditingController();
  final _buyerPhoneController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedBarnId;
  int? _selectedCattleId;
  CattleSaleType _saleType = CattleSaleType.alive;
  SalePaymentStatus _paymentStatus = SalePaymentStatus.paid;
  DateTime _saleDate = DateTime.now();
  bool _useWeighing = true;
  bool _isLoading = false;

  List<CattleRegistry> filteredCattle = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BarnProvider>().loadBarns();
    });
  }

  @override
  void dispose() {
    _liveWeightController.dispose();
    _meatWeightController.dispose();
    _pricePerKgController.dispose();
    _fixedPriceController.dispose();
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onBarnSelected(int? barnId) {
    setState(() {
      _selectedBarnId = barnId;
      _selectedCattleId = null;
      if (barnId != null) {
        final provider = context.read<CattleRegistryProvider>();
        filteredCattle = provider.cattleRegistry
            .where((c) => c.barnId == barnId && c.status == CattleStatus.active)
            .toList();
      } else {
        filteredCattle = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Фурӯши чорво'),
        backgroundColor: AppTheme.primaryIndigo,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBarnSelection(),
              const SizedBox(height: 16),
              _buildCattleSelection(),
              const SizedBox(height: 24),
              _buildSaleTypeSelection(),
              const SizedBox(height: 24),
              _buildWeightSection(),
              const SizedBox(height: 24),
              _buildPriceSection(),
              const SizedBox(height: 24),
              _buildBuyerSection(),
              const SizedBox(height: 24),
              _buildPaymentSection(),
              const SizedBox(height: 24),
              _buildNotesSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }  

  Widget _buildBarnSelection() {
    return Consumer<BarnProvider>(
      builder: (context, barnProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Интихоби оғул',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedBarnId,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.home_work),
                hintText: 'Оғулро интихоб кунед',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              menuMaxHeight: 300,
              items: barnProvider.barns.map((barn) {
                return DropdownMenuItem(
                  value: barn.id,
                  child: Text(
                    barn.name,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _onBarnSelected,
              validator: (value) {
                if (value == null) return 'Оғулро интихоб кунед';
                return null;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCattleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Интихоби чорво',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedCattleId,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.pets),
            hintText: 'Чорворо интихоб кунед',
            border: OutlineInputBorder(),
          ),
          isExpanded: true,
          menuMaxHeight: 300,
          items: filteredCattle.map((cattle) {
            return DropdownMenuItem(
              value: cattle.id,
              child: Text(
                '${cattle.earTag}  (${cattle.genderDisplay}) - ${cattle.name}',
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedCattleId = value),
          validator: (value) {
            if (value == null) return 'Чорворо интихоб кунед';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSaleTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Навъи фурӯш',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSaleTypeCard(
                CattleSaleType.alive,
                'Зинда',
                Icons.pets,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSaleTypeCard(
                CattleSaleType.slaughtered,
                'Сарборидашуда',
                Icons.restaurant,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaleTypeCard(CattleSaleType type, String label, IconData icon, Color color) {
    final isSelected = _saleType == type;
    return GestureDetector(
      onTap: () => setState(() => _saleType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Маълумоти вазн',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Switch(
              value: _useWeighing,
              onChanged: (value) => setState(() => _useWeighing = value),
            ),
            Text(_useWeighing ? 'Бо вазн' : 'Бе вазн'),
          ],
        ),
        const SizedBox(height: 12),
        if (_useWeighing) ...[
          if (_saleType == CattleSaleType.alive)
            TextFormField(
              controller: _liveWeightController,
              decoration: const InputDecoration(
                labelText: 'Вазни зинда (кг)',
                prefixIcon: Icon(Icons.monitor_weight),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (_useWeighing && _saleType == CattleSaleType.alive && (value == null || value.trim().isEmpty)) {
                  return 'Вазни зинда зарур аст';
                }
                return null;
              },
            ),
          if (_saleType == CattleSaleType.slaughtered)
            TextFormField(
              controller: _meatWeightController,
              decoration: const InputDecoration(
                labelText: 'Вазни гӯшт (кг)',
                prefixIcon: Icon(Icons.scale),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (_saleType == CattleSaleType.slaughtered && _useWeighing && 
                    (value == null || value.trim().isEmpty)) {
                  return 'Вазни гӯшт зарур аст';
                }
                return null;
              },
            ),
        ],
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Маълумоти нарх',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_useWeighing)
          TextFormField(
            controller: _pricePerKgController,
            decoration: const InputDecoration(
              labelText: 'Нархи 1 кг (сомонӣ)',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (_useWeighing && (value == null || value.trim().isEmpty)) {
                return 'Нархи як килограм зарур аст';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          )
        else
          TextFormField(
            controller: _fixedPriceController,
            decoration: const InputDecoration(
              labelText: 'Нархи умумӣ (сомонӣ)',
              prefixIcon: Icon(Icons.money),
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (!_useWeighing && (value == null || value.trim().isEmpty)) {
                return 'Нархи умумӣ зарур аст';
              }
              return null;
            },
          ),
        if (_useWeighing && _pricePerKgController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildTotalPriceCard(),
        ],
      ],
    );
  }

  Widget _buildTotalPriceCard() {
    final weight = _saleType == CattleSaleType.slaughtered && _meatWeightController.text.isNotEmpty
        ? double.tryParse(_meatWeightController.text) ?? 0
        : double.tryParse(_liveWeightController.text) ?? 0;
    final pricePerKg = double.tryParse(_pricePerKgController.text) ?? 0;
    final totalPrice = weight * pricePerKg;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Ҷамъи нарх:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            '${totalPrice.toStringAsFixed(2)} сомонӣ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Маълумоти харидор',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _buyerNameController,
          decoration: const InputDecoration(
            labelText: 'Номи харидор (ихтиёрӣ)',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _buyerPhoneController,
          decoration: const InputDecoration(
            labelText: 'Телефони харидор (ихтиёрӣ)',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Маълумоти пардохт',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<SalePaymentStatus>(
          value: _paymentStatus,
          decoration: const InputDecoration(
            labelText: 'Ҳолати пардохт',
            prefixIcon: Icon(Icons.payment),
            border: OutlineInputBorder(),
          ),
          items: SalePaymentStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(_getPaymentStatusText(status)),
            );
          }).toList(),
          onChanged: (value) => setState(() => _paymentStatus = value!),
        ),
        if (_paymentStatus == SalePaymentStatus.partial) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _paidAmountController,
            decoration: const InputDecoration(
              labelText: 'Маблағи пардохтшуда',
              prefixIcon: Icon(Icons.money),
              suffixText: 'сомонӣ',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (_paymentStatus == SalePaymentStatus.partial &&
                  (value == null || value.trim().isEmpty)) {
                return 'Маблағи пардохтшударо ворид кунед';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildNotesSection() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Қайдҳо (ихтиёрӣ)',
        prefixIcon: Icon(Icons.notes),
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveSale,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryIndigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Ворид кардан', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  String _getPaymentStatusText(SalePaymentStatus status) {
    switch (status) {
      case SalePaymentStatus.paid:
        return 'Пардохтшуда';
      case SalePaymentStatus.pending:
        return 'Пардохтнашуда';
      case SalePaymentStatus.partial:
        return 'Қисман пардохтшуда';
    }
  }

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final liveWeightValue = _useWeighing ? double.tryParse(_liveWeightController.text.trim()) : null;
      final meatWeight = _saleType == CattleSaleType.slaughtered && _useWeighing
          ? double.tryParse(_meatWeightController.text.trim())
          : null;
      final pricePerKg = _useWeighing ? (double.tryParse(_pricePerKgController.text.trim()) ?? 0.0) : 0.0;
      final fixedPrice = !_useWeighing ? double.parse(_fixedPriceController.text.trim()) : null;
      final paidAmountValue = _paymentStatus == SalePaymentStatus.partial
          ? double.parse(_paidAmountController.text.trim())
          : 0.0;
      
      // Determine the weight to use (meat weight for slaughtered, live weight for alive)
      final saleWeight = _saleType == CattleSaleType.slaughtered && meatWeight != null
          ? meatWeight
          : liveWeightValue!;

      final sale = CattleSale(
        cattleId: _selectedCattleId!,
        saleType: _saleType,
        saleDate: _saleDate,
        weight: saleWeight,
        liveWeight: liveWeightValue,
        slaughterDate: _saleType == CattleSaleType.slaughtered ? _saleDate : null,
        pricePerKg: pricePerKg,
        totalAmount: _useWeighing ? saleWeight * pricePerKg : fixedPrice!,
        buyerName: _buyerNameController.text.trim().isNotEmpty
            ? _buyerNameController.text.trim()
            : null,
        buyerPhone: _buyerPhoneController.text.trim().isNotEmpty
            ? _buyerPhoneController.text.trim()
            : null,
        paymentStatus: _paymentStatus,
        paidAmount: paidAmountValue,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      final provider = context.read<CattleRegistryProvider>();
      await provider.sellCattle(sale);
      await provider.loadAllData();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Фурӯш бомуваффақият сабт шуд'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Хато: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

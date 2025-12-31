import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/barn_provider.dart';
import '../../models/barn_expense.dart';
import '../../theme/app_theme.dart';

class AddBarnExpenseScreen extends StatefulWidget {
  final int barnId;
  final BarnExpense? expense;

  const AddBarnExpenseScreen({super.key, required this.barnId, this.expense});

  @override
  State<AddBarnExpenseScreen> createState() => _AddBarnExpenseScreenState();
}

class _AddBarnExpenseScreenState extends State<AddBarnExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _quantityUnitController = TextEditingController();
  final _pricePerUnitController = TextEditingController();
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();

  BarnExpenseType _expenseType = BarnExpenseType.feed;
  FeedType? _feedType;
  DateTime _expenseDate = DateTime.now();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _isEditing = true;
      _expenseType = widget.expense!.expenseType;
      _feedType = widget.expense!.feedType;
      _itemNameController.text = widget.expense!.itemName;
      _quantityController.text = widget.expense!.quantity.toString();
      _quantityUnitController.text = widget.expense!.quantityUnit;
      _pricePerUnitController.text = widget.expense!.pricePerUnit.toString();
      _supplierController.text = widget.expense!.supplier ?? '';
      _notesController.text = widget.expense!.notes ?? '';
      _expenseDate = widget.expense!.expenseDate;
    } else {
      _quantityUnitController.text = 'кг';
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _quantityUnitController.dispose();
    _pricePerUnitController.dispose();
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Таҳрири харочот' : 'Харочоти нав'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<BarnExpenseType>(
              value: _expenseType,
              decoration: const InputDecoration(
                labelText: 'Навъи харочот *',
                prefixIcon: Icon(Icons.category),
              ),
              items: BarnExpenseType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getExpenseIcon(type), size: 20),
                      const SizedBox(width: 8),
                      Text(_getExpenseTypeDisplay(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _expenseType = value;
                    _updateDefaultUnit();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Feed type dropdown (only for feed expenses)
            if (_expenseType == BarnExpenseType.feed) ...[
              DropdownButtonFormField<FeedType>(
                value: _feedType,
                decoration: const InputDecoration(
                  labelText: 'Навъи хӯрок *',
                  prefixIcon: Icon(Icons.grass),
                ),
                items: FeedType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getFeedTypeDisplay(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _feedType = value;
                    if (value != null) {
                      _itemNameController.text = _getFeedTypeDisplay(value);
                      _updateUnitByFeedType(value);
                    }
                  });
                },
                validator: (value) {
                  if (_expenseType == BarnExpenseType.feed && value == null) {
                    return 'Навъи хӯрок зарур аст';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            // Item name field (hidden for feed, shown for others)
            if (_expenseType != BarnExpenseType.feed)
              TextFormField(
                controller: _itemNameController,
                decoration: const InputDecoration(
                  labelText: 'Номи мол *',
                  prefixIcon: Icon(Icons.inventory),
                ),
                validator: (value) {
                  if (_expenseType != BarnExpenseType.feed && (value == null || value.trim().isEmpty)) {
                    return 'Номи мол зарур аст';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Миқдор *',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Миқдор зарур аст';
                      }
                      final quantity = double.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return 'Миқдори дуруст ворид кунед';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _quantityUnitController,
                    decoration: const InputDecoration(
                      labelText: 'Воҳид *',
                      hintText: 'кг/литр/дона',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Воҳид зарур аст';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pricePerUnitController,
              decoration: const InputDecoration(
                labelText: 'Нархи як воҳид *',
                hintText: 'Нархи як кг/литр/дона',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'TJS',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Нархи як воҳид зарур аст';
                }
                final price = double.tryParse(value);
                if (price == null || price < 0) {
                  return 'Нархи дуруст ворид кунед';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (_quantityController.text.isNotEmpty && _pricePerUnitController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ҳамагӣ харочот:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${_calculateTotalCost().toStringAsFixed(2)} TJS',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Таърихи харочот'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_expenseDate)),
              onTap: _selectDate,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _supplierController,
              decoration: const InputDecoration(
                labelText: 'Таъминкунанда (ихтиёрӣ)',
                hintText: 'Номи таъминкунанда',
                prefixIcon: Icon(Icons.store),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Қайдҳо (ихтиёрӣ)',
                hintText: 'Қайдҳои иловагӣ',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryIndigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isEditing ? 'Нигоҳ доштан' : 'Илова кардан'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateDefaultUnit() {
    setState(() {
      _feedType = null; // Reset feed type when changing expense type
      _itemNameController.clear(); // Clear item name
    });
    
    switch (_expenseType) {
      case BarnExpenseType.feed:
        _quantityUnitController.text = 'кг';
        break;
      case BarnExpenseType.medication:
        _quantityUnitController.text = 'дона';
        break;
      case BarnExpenseType.water:
        _quantityUnitController.text = 'литр';
        break;
      case BarnExpenseType.other:
        _quantityUnitController.text = 'дона';
        break;
    }
  }
  
  void _updateUnitByFeedType(FeedType type) {
    switch (type) {
      case FeedType.press:
        _quantityUnitController.text = 'дона';
        break;
      case FeedType.karma:
        _quantityUnitController.text = 'кг';
        break;
    }
  }

  double _calculateTotalCost() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final pricePerUnit = double.tryParse(_pricePerUnitController.text) ?? 0;
    return quantity * pricePerUnit;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final quantity = double.parse(_quantityController.text.trim());
    final pricePerUnit = double.parse(_pricePerUnitController.text.trim());
    final totalCost = quantity * pricePerUnit;

    final expense = BarnExpense(
      id: widget.expense?.id,
      barnId: widget.barnId,
      expenseType: _expenseType,
      feedType: _feedType,
      itemName: _itemNameController.text.trim(),
      quantity: quantity,
      quantityUnit: _quantityUnitController.text.trim(),
      pricePerUnit: pricePerUnit,
      totalCost: totalCost,
      supplier: _supplierController.text.trim().isNotEmpty
          ? _supplierController.text.trim()
          : null,
      expenseDate: _expenseDate,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    try {
      final provider = context.read<BarnProvider>();
      
      if (_isEditing) {
        await provider.updateBarnExpense(expense);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Харочот бомуваффақият таҳрир шуд')),
          );
        }
      } else {
        await provider.addBarnExpense(expense);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Харочот бомуваффақият илова шуд')),
          );
        }
      }
      
      // Reload barn data to refresh all barn-related pages
      if (mounted) {
        await provider.loadBarns();
      }
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хато: ${e.toString()}')),
        );
      }
    }
  }

  IconData _getExpenseIcon(BarnExpenseType type) {
    switch (type) {
      case BarnExpenseType.feed:
        return Icons.grass;
      case BarnExpenseType.medication:
        return Icons.medication;
      case BarnExpenseType.water:
        return Icons.water_drop;
      case BarnExpenseType.other:
        return Icons.more_horiz;
    }
  }

  String _getExpenseTypeDisplay(BarnExpenseType type) {
    switch (type) {
      case BarnExpenseType.feed:
        return 'Хӯрок';
      case BarnExpenseType.medication:
        return 'Дово';
      case BarnExpenseType.water:
        return 'Об';
      case BarnExpenseType.other:
        return 'Дигар';
    }
  }
  
  String _getFeedTypeDisplay(FeedType type) {
    switch (type) {
      case FeedType.press:
        return 'Пресс';
      case FeedType.karma:
        return 'Корм';
    }
  }
}

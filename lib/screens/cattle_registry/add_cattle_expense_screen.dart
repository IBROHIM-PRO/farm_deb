import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cattle_registry_provider.dart';
import '../../models/cattle_expense.dart';
import '../../theme/app_theme.dart';

/// Add Cattle Expense Screen - Record feeding, medication, and other costs
/// Registry pattern: Expense events linked to cattle ID
class AddCattleExpenseScreen extends StatefulWidget {
  final int cattleId;

  const AddCattleExpenseScreen({
    super.key,
    required this.cattleId,
  });

  @override
  State<AddCattleExpenseScreen> createState() => _AddCattleExpenseScreenState();
}

class _AddCattleExpenseScreenState extends State<AddCattleExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();

  ExpenseType _expenseType = ExpenseType.feed;
  String _quantityUnit = 'кг';
  DateTime _expenseDate = DateTime.now();
  String _currency = 'TJS';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сабти хароҷот'),
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
              // Header Info
              _buildHeaderCard(),
              
              const SizedBox(height: 24),
              
              // Expense Type Selection
              _buildExpenseTypeSection(),
              
              const SizedBox(height: 24),
              
              // Item Name
              _buildItemNameSection(),
              
              const SizedBox(height: 24),
              
              // Quantity Section
              _buildQuantitySection(),
              
              const SizedBox(height: 24),
              
              // Cost Section
              _buildCostSection(),
              
              const SizedBox(height: 24),
              
              // Expense Date
              _buildExpenseDateSection(),
              
              const SizedBox(height: 24),
              
              // Supplier Information
              _buildSupplierSection(),
              
              const SizedBox(height: 24),
              
              // Notes
              _buildNotesSection(),
              
              const SizedBox(height: 32),
              
              // Save Button
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.payment,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Сабти харочоти чорво',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Харочоти хӯрок, дово ва дигар маводро сабт кунед',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Навъи харочот',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildExpenseTypeCard(
                ExpenseType.feed,
                'Хӯрок',
                Icons.restaurant,
                Colors.green,
                'Харочоти озуқаворӣ',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildExpenseTypeCard(
                ExpenseType.medication,
                'Дово',
                Icons.medical_services,
                Colors.red,
                'Харочоти табобат',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildExpenseTypeCard(
                ExpenseType.other,
                'Дигар',
                Icons.more_horiz,
                Colors.blue,
                'Харочоти дигар',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseTypeCard(
    ExpenseType type,
    String title,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    final isSelected = _expenseType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _expenseType = type;
          // Update quantity unit based on expense type
          _quantityUnit = type == ExpenseType.feed ? 'кг' : 
                          type == ExpenseType.medication ? 'дона' : 'дона';
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
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
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getItemNameLabel(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _itemNameController,
          decoration: InputDecoration(
            labelText: _getItemNameHint(),
            prefixIcon: Icon(_getExpenseTypeIcon()),
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
              return '${_getItemNameLabel()} зарур аст';
            }
            return null;
          },
        ),
        const SizedBox(height: 4),
        Text(
          _getItemNameDescription(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Миқдор',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Миқдор',
                  prefixIcon: const Icon(Icons.straighten),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.trim().isEmpty == true) {
                    return 'Миқдор зарур аст';
                  }
                  final quantity = double.tryParse(value!);
                  if (quantity == null || quantity <= 0) {
                    return 'Миқдори дуруст ворид кунед';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _quantityUnit,
                decoration: InputDecoration(
                  labelText: 'Воҳид',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: _getQuantityUnits(),
                onChanged: (value) {
                  setState(() {
                    _quantityUnit = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCostSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Харч',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _costController,
                decoration: InputDecoration(
                  labelText: 'Ҳамагӣ харч',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.trim().isEmpty == true) {
                    return 'Харч зарур аст';
                  }
                  final cost = double.tryParse(value!);
                  if (cost == null || cost <= 0) {
                    return 'Харҷи дуруст ворид кунед';
                  }
                  return null;
                },
                onChanged: _calculateCostPerUnit,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _currency,
                decoration: InputDecoration(
                  labelText: 'Асъор',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: const [
                  DropdownMenuItem(value: 'TJS', child: Text('TJS')),
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'RUB', child: Text('RUB')),
                ],
                onChanged: (value) {
                  setState(() {
                    _currency = value!;
                  });
                },
              ),
            ),
          ],
        ),
        
        // Cost per unit display
        if (_costController.text.isNotEmpty && _quantityController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const Icon(Icons.calculate, color: Colors.blue, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Нархи як $_quantityUnit: ${_getCostPerUnit().toStringAsFixed(2)} $_currency',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExpenseDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Санаи харочот',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Санаи харочот'),
            subtitle: Text(
              '${_expenseDate.day.toString().padLeft(2, '0')}/'
              '${_expenseDate.month.toString().padLeft(2, '0')}/'
              '${_expenseDate.year}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _selectExpenseDate,
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Таъминкунанда',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _supplierController,
          decoration: InputDecoration(
            labelText: 'Номи таъминкунанда (ихтиёрӣ)',
            prefixIcon: const Icon(Icons.store),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Эзоҳот',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'Эзоҳот (ихтиёрӣ)',
            prefixIcon: const Icon(Icons.note),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.text,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveExpense,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Харочот сабт кардан',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String _getItemNameLabel() {
    switch (_expenseType) {
      case ExpenseType.feed:
        return 'Навъи хӯрок';
      case ExpenseType.medication:
        return 'Номи дово';
      case ExpenseType.other:
        return 'Номи мавод';
    }
  }

  String _getItemNameHint() {
    switch (_expenseType) {
      case ExpenseType.feed:
        return 'Мисол: Алаф, ҷав, кунҷора...';
      case ExpenseType.medication:
        return 'Мисол: Антибиотик, витамин...';
      case ExpenseType.other:
        return 'Мисол: Обшӯрӣ, нигоҳдорӣ...';
    }
  }

  String _getItemNameDescription() {
    switch (_expenseType) {
      case ExpenseType.feed:
        return 'Навъи хӯроки истифодашуда барои чорво';
      case ExpenseType.medication:
        return 'Номи давои истифодашуда барои табобат';
      case ExpenseType.other:
        return 'Номи мавод ё хидматҳои дигар';
    }
  }

  IconData _getExpenseTypeIcon() {
    switch (_expenseType) {
      case ExpenseType.feed:
        return Icons.restaurant;
      case ExpenseType.medication:
        return Icons.medical_services;
      case ExpenseType.other:
        return Icons.build;
    }
  }

  List<DropdownMenuItem<String>> _getQuantityUnits() {
    switch (_expenseType) {
      case ExpenseType.feed:
        return const [
          DropdownMenuItem(value: 'кг', child: Text('кг')),
          DropdownMenuItem(value: 'тонна', child: Text('тонна')),
          DropdownMenuItem(value: 'дона', child: Text('дона')),
        ];
      case ExpenseType.medication:
        return const [
          DropdownMenuItem(value: 'дона', child: Text('дона')),
          DropdownMenuItem(value: 'мл', child: Text('мл')),
          DropdownMenuItem(value: 'гр', child: Text('гр')),
          DropdownMenuItem(value: 'укол', child: Text('укол')),
        ];
      case ExpenseType.other:
        return const [
          DropdownMenuItem(value: 'дона', child: Text('дона')),
          DropdownMenuItem(value: 'соат', child: Text('соат')),
          DropdownMenuItem(value: 'рӯз', child: Text('рӯз')),
          DropdownMenuItem(value: 'хидмат', child: Text('хидмат')),
        ];
    }
  }

  double _getCostPerUnit() {
    final cost = double.tryParse(_costController.text) ?? 0;
    final quantity = double.tryParse(_quantityController.text) ?? 1;
    return quantity > 0 ? cost / quantity : 0;
  }

  void _calculateCostPerUnit(String value) {
    setState(() {}); // Trigger rebuild to update cost per unit display
  }

  Future<void> _selectExpenseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _expenseDate = date;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final expense = CattleExpense(
          cattleId: widget.cattleId,
          expenseType: _expenseType,
          itemName: _itemNameController.text.trim(),
          quantity: double.parse(_quantityController.text),
          quantityUnit: _quantityUnit,
          cost: double.parse(_costController.text),
          currency: _currency,
          supplier: _supplierController.text.trim().isNotEmpty 
              ? _supplierController.text.trim() 
              : null,
          expenseDate: _expenseDate,
          notes: _notesController.text.trim().isNotEmpty 
              ? _notesController.text.trim() 
              : null,
        );

        await context.read<CattleRegistryProvider>().addCattleExpense(expense);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Харочот бомуваффақият сабт шуд'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Хатогӣ: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

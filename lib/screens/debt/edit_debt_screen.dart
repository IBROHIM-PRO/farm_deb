import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../database/database_helper.dart';
import '../../models/person.dart';
import '../../models/debt.dart';

class EditDebtScreen extends StatefulWidget {
  final Debt debt;

  const EditDebtScreen({super.key, required this.debt});

  @override
  State<EditDebtScreen> createState() => _EditDebtScreenState();
}

class _EditDebtScreenState extends State<EditDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _personNameController = TextEditingController();
  Person? _selectedPerson;
  DebtType _debtType = DebtType.given;
  String _currency = 'TJS';
  final List<String> _currencies = ['TJS', 'USD', 'EUR', 'RUB'];

  @override
  void initState() {
    super.initState();
    // Pre-fill form with existing debt data
    _amountController.text = widget.debt.totalAmount.toStringAsFixed(2);
    _debtType = widget.debt.type;
    _currency = widget.debt.currency;
    
    // Set the person
    final provider = context.read<AppProvider>();
    _selectedPerson = provider.getPersonById(widget.debt.personId);
    if (_selectedPerson != null) {
      _personNameController.text = _selectedPerson!.fullName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Таҳрири қарз')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---------- PERSON ----------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Шахс', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    // Person Name with Autocomplete
                    Autocomplete<String>(
                      initialValue: TextEditingValue(text: _personNameController.text),
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        try {
                          // Always get all person names first
                          final allPersons = await context.read<AppProvider>().getPersonNames();
                           
                          // If input is empty, return all persons
                          if (textEditingValue.text.isEmpty) {
                            return allPersons;
                          }
                           
                          // Filter persons based on input
                          final query = textEditingValue.text.toLowerCase();
                          return allPersons.where((person) => 
                            person.toLowerCase().contains(query)).toList();
                        } catch (e) {
                          // Return empty list if there's an error
                          return <String>[];
                        }
                      },
                      onSelected: (String selection) {
                        _personNameController.text = selection;
                        // Find person by name
                        final person = provider.persons.firstWhere(
                          (p) => p.fullName == selection,
                          orElse: () => Person(fullName: selection),
                        );
                        setState(() => _selectedPerson = person);
                      },
                      fieldViewBuilder: (
                        BuildContext context,
                        TextEditingController fieldTextEditingController,
                        FocusNode fieldFocusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
                        // Sync with our main controller
                        fieldTextEditingController.addListener(() {
                          _personNameController.text = fieldTextEditingController.text;
                          // Auto-create person if name is entered but doesn't exist
                          final existingPerson = provider.persons.cast<Person?>().firstWhere(
                            (p) => p?.fullName == fieldTextEditingController.text,
                            orElse: () => null,
                          );
                          if (existingPerson != null) {
                            setState(() => _selectedPerson = existingPerson);
                          } else if (fieldTextEditingController.text.isNotEmpty) {
                            setState(() => _selectedPerson = Person(fullName: fieldTextEditingController.text.trim()));
                          }
                        });
                        
                        return TextFormField(
                          controller: fieldTextEditingController,
                          focusNode: fieldFocusNode,
                          decoration: const InputDecoration(
                            labelText: 'Номи шахс',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v?.isEmpty == true ? 'Зарур аст' : null,
                          onFieldSubmitted: (value) => onFieldSubmitted(),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    if (_selectedPerson?.phone != null)
                      Text(
                        'Телефон: ${_selectedPerson!.phone}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---------- DEBT TYPE ----------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Намуди қарз', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDebtTypeOption(
                            context,
                            DebtType.given,
                            'Додашуда',
                            'Қарзи дода шуда',
                            Icons.arrow_upward,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDebtTypeOption(
                            context,
                            DebtType.taken,
                            'Гирифташуда',
                            'Қарзи гирифта шуда',
                            Icons.arrow_downward,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---------- AMOUNT ----------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Маблағ', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Маблағ',
                        prefixIcon: const Icon(Icons.attach_money),
                        suffixText: _currency,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final a = double.tryParse(v ?? '');
                        if (a == null || a <= 0) return 'Маблағи дуруст ворид кунед';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Асъор',
                        prefixIcon: Icon(Icons.currency_exchange),
                        border: OutlineInputBorder(),
                      ),
                      items: _currencies.map((currency) {
                        return DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _currency = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ---------- SUBMIT BUTTON ----------
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Нигоҳ доштани тағйирот'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtTypeOption(
    BuildContext context,
    DebtType type,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _debtType == type;
    
    return GestureDetector(
      onTap: () => setState(() => _debtType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? color.withOpacity(0.1) : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: isSelected ? color : Colors.grey, fontWeight: FontWeight.bold)),
            Text(subtitle, style: TextStyle(color: isSelected ? color : Colors.grey, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if ((_formKey.currentState?.validate() ?? false) && _selectedPerson != null) {
      try {
        final provider = context.read<AppProvider>();
        
        // If person doesn't have ID, create them first
        Person personToUse = _selectedPerson!;
        if (personToUse.id == null) {
          final newPersonId = await provider.addPerson(personToUse);
          personToUse = personToUse.copyWith(id: newPersonId);
        }

        // Update the debt - use database helper directly since updateDebt doesn't exist
        await DatabaseHelper.instance.updateDebt(
          widget.debt.copyWith(
            personId: personToUse.id!,
            totalAmount: double.parse(_amountController.text),
            currency: _currency,
            type: _debtType,
          ),
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Қарз бомуваффақият тағйир дода шуд')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Хато: ${e.toString()}')),
          );
        }
      }
    }
  }
}

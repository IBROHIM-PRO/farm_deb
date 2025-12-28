import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/person.dart';
import '../../models/debt.dart';

class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _personNameController = TextEditingController();
  Person? _selectedPerson;
  DebtType _debtType = DebtType.given;
  String _currency = 'TJS';
  final List<String> _currencies = ['TJS', 'USD', 'EUR', 'RUB'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Илова кардани қарз')),
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
                        // Find the person by name
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
                            suffixIcon: Icon(Icons.arrow_drop_down),
                            hintText: 'Номи шахсро дарҷ кунед ё интихоб кунед',
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value?.trim().isEmpty == true) {
                              return 'Номи шахс зарур аст';
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
                        Expanded(child: _buildTypeCard('Додашуда', 'Пуле, ки шумо додаед', Icons.arrow_upward, Colors.green, DebtType.given)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTypeCard('Гирифташуда', 'Пуле, ки шумо гирифтаед', Icons.arrow_downward, Colors.red, DebtType.taken)),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: 'Маблағ',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v?.isEmpty == true) return 'Мавҷуд аст';
                              if (double.tryParse(v!) == null || double.parse(v) <= 0) return 'Нодуруст';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _currency,
                            decoration: const InputDecoration(labelText: 'Currency'),
                            items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _currency = v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ---------- NOTE ----------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Эзоҳ (ихтиёрӣ)',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ---------- SUBMIT BUTTON ----------
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _debtType == DebtType.given ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _debtType == DebtType.given ? 'Қарзи додашударо сабт кунед' : 'Қарзи гирифташударо сабт кунед',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(String title, String subtitle, IconData icon, Color color, DebtType type) {
    final isSelected = _debtType == type;
    return GestureDetector(
      onTap: () => setState(() => _debtType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : null,
          border: Border.all(color: isSelected ? color : Colors.grey.withOpacity(0.3), width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
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

  void _showAddPersonDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Илова кардани шахс'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Номи пурра'),
                validator: (v) => v?.isEmpty == true ? 'Мавҷуд аст' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Телефон (ихтиёрӣ)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Бекор')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final id = await ctx.read<AppProvider>().addPerson(
                  Person(
                    fullName: nameController.text.trim(),
                    phone: phoneController.text.isEmpty ? null : phoneController.text.trim(),
                  ),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  final p = ctx.read<AppProvider>().persons.firstWhere((p) => p.id == id);
                  setState(() => _selectedPerson = p);
                }
              }
            },
            child: const Text('Илова'),
          ),
        ],
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

        // Add the debt
        await provider.addDebt(
          personId: personToUse.id!,
          amount: double.parse(_amountController.text),
          currency: _currency,
          type: _debtType,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Қарз барои ${personToUse.fullName} сабт шуд'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Хатогӣ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

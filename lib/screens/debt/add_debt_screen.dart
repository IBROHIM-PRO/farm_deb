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
                    if (provider.persons.isEmpty)
                      ElevatedButton.icon(
                        onPressed: () => _showAddPersonDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Илова кардани шахс'),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<Person>(
                              value: _selectedPerson,
                              decoration: const InputDecoration(
                                labelText: 'Шахсро интихоб кунед',
                                prefixIcon: Icon(Icons.person),
                              ),
                              items: provider.persons
                                  .map((p) => DropdownMenuItem(value: p, child: Text(p.fullName)))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedPerson = v),
                              validator: (v) => v == null ? 'Мавҷуд аст' : null,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showAddPersonDialog(context),
                            icon: const Icon(Icons.person_add),
                          ),
                        ],
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
              if (formKey.currentState!.validate()) {
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
    if (_formKey.currentState!.validate()) {
      await context.read<AppProvider>().addDebt(
            personId: _selectedPerson!.id!,
            amount: double.parse(_amountController.text),
            currency: _currency,
            type: _debtType,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Қарз барои ${_selectedPerson!.fullName} сабт шуд'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}

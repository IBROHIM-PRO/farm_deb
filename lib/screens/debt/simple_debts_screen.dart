// lib/screens/debt/simple_debts_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/person.dart';
import '../../models/debt.dart';
import 'debt_transaction_history_screen.dart';
import 'person_debt_history_screen.dart';

class SimpleDebtsScreen extends StatelessWidget {
  const SimpleDebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Идоракунии қарзҳо'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showDebtForm(context, null),
            tooltip: 'Қарзи нав',
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final debts = provider.debts;

          if (debts.isEmpty) {
            return _buildEmptyState(context);
          }

          // Group debts by person name
          final groupedDebts = <String, List<Debt>>{};
          for (final debt in debts) {
            final personName = provider.getPersonById(debt.personId)?.fullName ?? 'Unknown';
            groupedDebts.putIfAbsent(personName, () => []).add(debt);
          }

          final personNames = groupedDebts.keys.toList()..sort();

          return Column(
            children: [
              _buildSummaryCard(provider),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: personNames.length,
                  itemBuilder: (context, index) {
                    final personName = personNames[index];
                    final personDebts = groupedDebts[personName]!;
                    return _buildPersonCard(context, personName, personDebts, provider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------- EMPTY STATE ----------------
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Ҳанӯз ҳеҷ қарз сабт нашудааст',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),          
        ],
      ),
    );
  }

  // ---------------- SUMMARY ----------------
  Widget _buildSummaryCard(AppProvider provider) {
    final totals = provider.getDebtTotalsByCurrency();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ҷамъбасти қарзҳо',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...totals.entries.map(
            (e) => _buildSummaryRow(e.key, e.value),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String currency, Map<String, double> amounts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(currency, style: const TextStyle(fontWeight: FontWeight.w600)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Додашуда: ${(amounts['given'] ?? 0.0).toStringAsFixed(2)}',
                style: TextStyle(color: Colors.green[700], fontSize: 13),
              ),
              Text(
                'Гирифташуда: ${(amounts['taken'] ?? 0.0).toStringAsFixed(2)}',
                style: TextStyle(color: Colors.red[700], fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- PERSON CARD ----------------
  Widget _buildPersonCard(BuildContext context, String personName, List<Debt> debts, AppProvider provider) {
    // Calculate totals for this person
    double totalGiven = 0.0;
    double totalTaken = 0.0;
    double remainingGiven = 0.0;
    double remainingTaken = 0.0;
    
    for (final debt in debts) {
      if (debt.type == DebtType.given) {
        totalGiven += debt.totalAmount;
        remainingGiven += debt.remainingAmount;
      } else {
        totalTaken += debt.totalAmount;
        remainingTaken += debt.remainingAmount;
      }
    }
    
    final activeCount = debts.where((d) => d.status == DebtStatus.active).length;
    final latestDate = debts.isEmpty 
        ? DateTime.now() 
        : debts.map((d) => d.date).reduce((a, b) => a.isAfter(b) ? a : b);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _navigateToPersonHistory(context, personName),
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
                            personName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Санаи охирин: ${DateFormat('dd/MM/yyyy').format(latestDate)}',
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
                      color: activeCount > 0 ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$activeCount фаъол',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: activeCount > 0 ? Colors.orange : Colors.green,
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
                    if (remainingGiven > 0) ...[
                      Column(
                        children: [
                          Text(
                            '${remainingGiven.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'Додашуда',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (remainingGiven > 0 && remainingTaken > 0) 
                      Container(height: 30, width: 1, color: Colors.grey[300]),
                    if (remainingTaken > 0) ...[
                      Column(
                        children: [
                          Text(
                            '${remainingTaken.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            'Гирифташуда',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (remainingGiven == 0 && remainingTaken == 0) ...[
                      Column(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          Text(
                            'Пардохташуда',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
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

  void _navigateToPersonHistory(BuildContext context, String personName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonDebtHistoryScreen(
          personName: personName,
        ),
      ),
    );
  }

  // ---------------- DEBT CARD ----------------
  Widget _buildDebtCard(
      BuildContext context, Debt debt, AppProvider provider) {
    final person = provider.getPersonById(debt.personId);
    if (person == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Edit/Delete buttons ABOVE the information
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, _) {
              if (!settingsProvider.editDeleteEnabled) {
                return const SizedBox.shrink();
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                      onPressed: () => _showDebtForm(context, debt),
                      tooltip: 'Таҳрир',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 18,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () => _confirmDeleteDebt(context, debt, provider),
                      tooltip: 'Нест кардан',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 18,
                    ),
                  ],
                ),
              );
            },
          ),
          // Information display
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DebtTransactionHistoryScreen(debt: debt),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          person.fullName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildStatusChip(debt),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _info('Намуди қарз:', debt.typeDisplay),
                  _info('Маблағи умумӣ:',
                      '${debt.totalAmount.toStringAsFixed(2)} ${debt.currency}'),
                  _info('Боқӣ мондааст:',
                      '${debt.remainingAmount.toStringAsFixed(2)} ${debt.currency}'),
                  _info('Сана:',
                      '${debt.date.day}/${debt.date.month}/${debt.date.year}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _confirmDeleteDebt(BuildContext context, Debt debt, AppProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Тасдиқ кунед'),
        content: const Text('Шумо мутмаин ҳастед, ки мехоҳед ин қарзро нест кунед? Ин амал бозгашт карда намешавад.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Бекор кардан'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Нест кардан'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await provider.deleteDebt(debt.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Қарз бомуваффақият нест карда шуд')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Хато: ${e.toString()}')),
          );
        }
      }
    }
  }

  Widget _buildStatusChip(Debt debt) {
    final active = debt.status == DebtStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.orange[100] : Colors.green[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        debt.statusDisplay,
        style: TextStyle(
          color: active ? Colors.orange[800] : Colors.green[800],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ---------------- PAYMENT ----------------
  void _showPaymentDialog(BuildContext context, Debt debt) {
    final controller = TextEditingController();
    final key = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Пардохт'),
        content: Form(
          key: key,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Маблағ',
              suffixText: debt.currency,
            ),
            validator: (v) {
              final a = double.tryParse(v ?? '');
              if (a == null || a <= 0) return 'Нодуруст';
              if (a > debt.remainingAmount) return 'Аз боқимонда зиёд';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Бекор')),
          ElevatedButton(
            onPressed: () async {
              if (key.currentState?.validate() ?? false) {
                await ctx.read<AppProvider>().makePayment(
                      debt: debt,
                      amount: double.parse(controller.text),
                    );
                Navigator.pop(ctx); // танҳо диалог пӯшида мешавад
              }
            },
            child: const Text('Пардохт'),
          ),
        ],
      ),
    );
  }

  // ---------------- INLINE DEBT FORM (ADD/EDIT) ----------------
  static void _showDebtForm(BuildContext context, Debt? debt) {
    final formKey = GlobalKey<FormState>();
    final personNameController = TextEditingController();
    final amountController = TextEditingController(
      text: debt?.totalAmount.toString() ?? '',
    );
    final notesController = TextEditingController();
    
    DebtType debtType = debt?.type ?? DebtType.given;
    String currency = debt?.currency ?? 'TJS';
    Person? selectedPerson;
    
    // If editing, load the person data
    if (debt != null) {
      final provider = context.read<AppProvider>();
      selectedPerson = provider.getPersonById(debt.personId);
      if (selectedPerson != null) {
        personNameController.text = selectedPerson.fullName;
      }
    }
    
    final currencies = ['TJS', 'USD', 'EUR', 'RUB'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          debt == null ? 'Қарзи нав' : 'Таҳрири қарз',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Person Name with Autocomplete
                    Autocomplete<String>(
                      initialValue: TextEditingValue(text: personNameController.text),
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        try {
                          final allPersons = await context.read<AppProvider>().getPersonNames();
                          if (textEditingValue.text.isEmpty) {
                            return allPersons;
                          }
                          final query = textEditingValue.text.toLowerCase();
                          return allPersons.where((person) => 
                            person.toLowerCase().contains(query)).toList();
                        } catch (e) {
                          return <String>[];
                        }
                      },
                      onSelected: (String selection) {
                        personNameController.text = selection;
                        final provider = context.read<AppProvider>();
                        final person = provider.persons.firstWhere(
                          (p) => p.fullName == selection,
                          orElse: () => Person(fullName: selection),
                        );
                        selectedPerson = person;
                      },
                      fieldViewBuilder: (
                        BuildContext context,
                        TextEditingController fieldTextEditingController,
                        FocusNode fieldFocusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
                        fieldTextEditingController.addListener(() {
                          personNameController.text = fieldTextEditingController.text;
                          final provider = context.read<AppProvider>();
                          final existingPerson = provider.persons.cast<Person?>().firstWhere(
                            (p) => p?.fullName == fieldTextEditingController.text,
                            orElse: () => null,
                          );
                          if (existingPerson != null) {
                            selectedPerson = existingPerson;
                          } else if (fieldTextEditingController.text.isNotEmpty) {
                            selectedPerson = Person(fullName: fieldTextEditingController.text.trim());
                          }
                        });
                        
                        return TextFormField(
                          controller: fieldTextEditingController,
                          focusNode: fieldFocusNode,
                          decoration: const InputDecoration(
                            labelText: 'Номи шахс',
                            prefixIcon: Icon(Icons.person),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                            border: OutlineInputBorder(),
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
                              color: Colors.white,
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
                                          const Icon(Icons.person, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(child: Text(option)),
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
                    
                    // Debt Type Selection
                    const Text(
                      'Намуди қарз',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeCard(
                            'Додашуда',
                            'Пуле, ки шумо додаед',
                            Icons.arrow_upward,
                            Colors.green,
                            DebtType.given,
                            debtType,
                            (type) => setState(() => debtType = type),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTypeCard(
                            'Гирифташуда',
                            'Пуле, ки шумо гирифтаед',
                            Icons.arrow_downward,
                            Colors.red,
                            DebtType.taken,
                            debtType,
                            (type) => setState(() => debtType = type),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Amount and Currency
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: amountController,
                            decoration: const InputDecoration(
                              labelText: 'Маблағ',
                              prefixIcon: Icon(Icons.attach_money),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v?.isEmpty == true) return 'Мавҷуд аст';
                              if (double.tryParse(v!) == null || double.parse(v) <= 0) 
                                return 'Нодуруст';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: currency,
                            decoration: const InputDecoration(
                              labelText: 'Асъор',
                              border: OutlineInputBorder(),
                            ),
                            items: currencies.map((c) => 
                              DropdownMenuItem(value: c, child: Text(c))
                            ).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => currency = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate() && selectedPerson != null) {
                            try {
                              final provider = context.read<AppProvider>();
                              
                              if (debt != null) {
                                // Editing - delete old and create new
                                await provider.deleteDebt(debt.id!);
                              }
                              
                              // If person doesn't have ID, create them first
                              Person personToUse = selectedPerson!;
                              if (personToUse.id == null) {
                                final newPersonId = await provider.addPerson(personToUse);
                                personToUse = personToUse.copyWith(id: newPersonId);
                              }

                              // Add the debt
                              await provider.addDebt(
                                personId: personToUse.id!,
                                amount: double.parse(amountController.text),
                                currency: currency,
                                type: debtType,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      debt == null 
                                        ? 'Қарз барои ${personToUse.fullName} сабт шуд'
                                        : 'Қарз барои ${personToUse.fullName} таҳрир шуд',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Хатогӣ: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: debtType == DebtType.given 
                            ? Colors.green 
                            : Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          debt == null 
                            ? (debtType == DebtType.given ? 'Қарзи додашударо сабт кунед' : 'Қарзи гирифташударо сабт кунед')
                            : 'Нигоҳ доштан',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildTypeCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    DebtType type,
    DebtType currentType,
    Function(DebtType) onTap,
  ) {
    final isSelected = currentType == type;
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : null,
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
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

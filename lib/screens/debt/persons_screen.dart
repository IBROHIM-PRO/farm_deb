import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/person.dart';

class PersonsScreen extends StatelessWidget {
  const PersonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Идоракунии корбарон')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.persons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  const Text('Ҳанӯз ҳеҷ шахс илова нашудааст'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(onPressed: () => _showAddPersonDialog(context), icon: const Icon(Icons.add), label: const Text('Илова кардани шахс')),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.persons.length,
            itemBuilder: (context, index) {
              final person = provider.persons[index];
              final debts = provider.getDebtsForPerson(person.id!);
              final activeCount = debts.where((d) => d.status.name == 'active').length;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Text(person.fullName[0].toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold))),
                  title: Text(person.fullName),
                  subtitle: Text(person.phone ?? 'Рақами телефон нест'),
                  trailing: activeCount > 0 ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)), child: Text('$activeCount фаъол', style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 12))) : null,
                  onLongPress: () => _showPersonOptions(context, person),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(heroTag: "persons_fab", onPressed: () => _showAddPersonDialog(context), child: const Icon(Icons.add)),
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
              TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Номи пурра', prefixIcon: Icon(Icons.person)), validator: (v) => v?.isEmpty == true ? 'Зарур аст' : null, textCapitalization: TextCapitalization.words),
              const SizedBox(height: 16),
              TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: 'Телефон (ихтиёрӣ)', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Бекор кардан')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await ctx.read<AppProvider>().addPerson(Person(fullName: nameController.text.trim(), phone: phoneController.text.isEmpty ? null : phoneController.text.trim()));
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Илова кардан'),
          ),
        ],
      ),
    );
  }

  void _showPersonOptions(BuildContext context, Person person) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.edit), title: const Text('Таҳрир кардан'), onTap: () { Navigator.pop(ctx); _showEditPersonDialog(context, person); }),
            ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Нест кардан', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(ctx); _showDeleteConfirm(context, person); }),
          ],
        ),
      ),
    );
  }

  void _showEditPersonDialog(BuildContext context, Person person) {
    final nameController = TextEditingController(text: person.fullName);
    final phoneController = TextEditingController(text: person.phone ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Таҳрири шахс'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Номи пурра'), validator: (v) => v?.isEmpty == true ? 'Зарур аст' : null),
              const SizedBox(height: 16),
              TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: 'Телефон (ихтиёрӣ)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Бекор кардан')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await ctx.read<AppProvider>().updatePerson(person.copyWith(fullName: nameController.text.trim(), phone: phoneController.text.isEmpty ? null : phoneController.text.trim()));
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Нигоҳ доштан'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, Person person) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Нест кардани шахс'),
        content: Text('Нест кардани ${person.fullName}? Ин инчунин ҳамаи қарзҳои алоқамандро нест хоҳад кард.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Бекор кардан')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () async { await ctx.read<AppProvider>().deletePerson(person.id!); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('Нест кардан')),
        ],
      ),
    );
  }
}

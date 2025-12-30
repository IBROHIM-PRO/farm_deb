import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/barn_provider.dart';
import '../../models/barn.dart';
import '../../theme/app_theme.dart';

class AddBarnScreen extends StatefulWidget {
  final Barn? barn;

  const AddBarnScreen({super.key, this.barn});

  @override
  State<AddBarnScreen> createState() => _AddBarnScreenState();
}

class _AddBarnScreenState extends State<AddBarnScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.barn != null) {
      _isEditing = true;
      _nameController.text = widget.barn!.name;
      _locationController.text = widget.barn!.location ?? '';
      _capacityController.text = widget.barn!.capacity?.toString() ?? '';
      _notesController.text = widget.barn!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Таҳрири ховар' : 'Ховари нав'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Номи ховар *',
                hintText: 'Номи ховарро ворид кунед',
                prefixIcon: Icon(Icons.home_work),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Номи ховар зарур аст';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Мавқеият (ихтиёрӣ)',
                hintText: 'Мавқеияти ховарро ворид кунед',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _capacityController,
              decoration: const InputDecoration(
                labelText: 'Ғунҷоиш (ихтиёрӣ)',
                hintText: 'Шумораи максималӣ чорво',
                prefixIcon: Icon(Icons.business),
                suffixText: 'сар',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final capacity = int.tryParse(value);
                  if (capacity == null || capacity <= 0) {
                    return 'Ғунҷоиш бояд адади мусбат бошад';
                  }
                }
                return null;
              },
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
              onPressed: _saveBarn,
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

  Future<void> _saveBarn() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final capacity = _capacityController.text.trim().isNotEmpty
        ? int.tryParse(_capacityController.text.trim())
        : null;
    final notes = _notesController.text.trim();

    final barn = Barn(
      id: widget.barn?.id,
      name: name,
      location: location.isNotEmpty ? location : null,
      capacity: capacity,
      createdDate: widget.barn?.createdDate ?? DateTime.now(),
      notes: notes.isNotEmpty ? notes : null,
    );

    try {
      final provider = context.read<BarnProvider>();
      
      if (_isEditing) {
        await provider.updateBarn(barn);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ховар бомуваффақият таҳрир шуд')),
          );
        }
      } else {
        await provider.addBarn(barn);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ховар бомуваффақият илова шуд')),
          );
        }
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
}

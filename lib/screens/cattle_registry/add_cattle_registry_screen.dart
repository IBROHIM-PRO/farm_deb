import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cattle_registry_provider.dart';
import '../../providers/barn_provider.dart';
import '../../models/cattle_registry.dart';
import '../../models/barn.dart';
import '../../theme/app_theme.dart';

/// Add Cattle Registry Screen - Register new cattle identity only
/// Clean Registry approach: only ear tag, gender, age category, barn, registration date
class AddCattleRegistryScreen extends StatefulWidget {
  const AddCattleRegistryScreen({super.key});

  @override
  State<AddCattleRegistryScreen> createState() => _AddCattleRegistryScreenState();
}

class _AddCattleRegistryScreenState extends State<AddCattleRegistryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _earTagController = TextEditingController();
  
  CattleGender _selectedGender = CattleGender.male;
  AgeCategory _selectedAgeCategory = AgeCategory.adult;
  int? _selectedBarnId;
  DateTime _registrationDate = DateTime.now();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load barns when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BarnProvider>().loadBarns();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Бақайдгирии чорво'),
        elevation: 0,
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
              // Ear Tag Input
              _buildEarTagSection(),
              
              const SizedBox(height: 24),
              
              // Gender Selection
              _buildGenderSection(),
              
              const SizedBox(height: 24),
              
              // Age Category Selection
              _buildAgeCategorySection(),
              
              const SizedBox(height: 24),
              
              // Barn Selection (Required)
              _buildBarnSelectionSection(),
              
              const SizedBox(height: 32),
              
              // Register Button
              _buildRegisterButton(),
            ],
          ),
        ),
      ),
    );
  }  

  Widget _buildEarTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Рамзи гӯш',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _earTagController,
          decoration: InputDecoration(
            hintText: 'Мисол: A001, Ҷ12, ...',
            prefixIcon: const Icon(Icons.tag),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          validator: (value) {
            if (value?.trim().isEmpty == true) {
              return 'Рамзи гӯш зарур аст';
            }
            return null;
          },
        ),
        const SizedBox(height: 4),
        Text(
          'Рамзи якто барои шиносоии чорво',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ҷинс',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGenderCard(
                CattleGender.male,
                'Нар',
                Icons.male,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderCard(
                CattleGender.female,
                'Мода',
                Icons.female,
                Colors.pink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderCard(
    CattleGender gender,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedGender == gender;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
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
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Синну сол',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAgeCategoryCard(
                AgeCategory.calf,
                'Гӯсола',
                '< 1 сол',
                Icons.child_care,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAgeCategoryCard(
                AgeCategory.young,
                'Ҷавон',
                '1-2 сол',
                Icons.pets,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAgeCategoryCard(
                AgeCategory.adult,
                'Калон',
                '> 2 сол',
                Icons.agriculture,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgeCategoryCard(
    AgeCategory category,
    String label,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedAgeCategory == category;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAgeCategory = category;
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
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarnSelectionSection() {
  return Consumer<BarnProvider>(
    builder: (context, barnProvider, _) {
      final barns = barnProvider.barns;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Ховар',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedBarnId,
            decoration: InputDecoration(
              hintText: 'Ховарро интихоб кунед',
              prefixIcon: const Icon(Icons.home_work),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null) {
                return 'Ховарро интихоб кунед (ҳатмӣ)';
              }
              return null;
            },
            items: barns.map((barn) {
              return DropdownMenuItem<int>(
                value: barn.id,
                child: Text(barn.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBarnId = value;
              });
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Интихоби ховар ҳатмӣ аст - чорвор бояд дар ховар бошад',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      );
    },
  );
}
 

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registerCattle,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryIndigo,
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
                'Ворид кардан',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _registerCattle() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final cattle = CattleRegistry(
          earTag: _earTagController.text.trim(),
          gender: _selectedGender,
          ageCategory: _selectedAgeCategory,
          barnId: _selectedBarnId,
          registrationDate: _registrationDate,
        );

        await context.read<CattleRegistryProvider>().addCattleToRegistry(cattle);
        
        // Reload barn provider to update cattle counts
        if (_selectedBarnId != null && mounted) {
          await context.read<BarnProvider>().loadBarns();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Чорво бомуваффақият бақайд шуд'),
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
    _earTagController.dispose();
    super.dispose();
  }
}

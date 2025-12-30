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
              // Header Info Card
              _buildHeaderCard(),
              
              const SizedBox(height: 24),
              
              // Ear Tag Input
              _buildEarTagSection(),
              
              const SizedBox(height: 24),
              
              // Gender Selection
              _buildGenderSection(),
              
              const SizedBox(height: 24),
              
              // Age Category Selection
              _buildAgeCategorySection(),
              
              const SizedBox(height: 24),
              
              // Barn Selection
              _buildBarnSelectionSection(),
              
              const SizedBox(height: 24),
              
              // Registration Date
              _buildRegistrationDateSection(),
              
              const SizedBox(height: 32),
              
              // Register Button
              _buildRegisterButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: AppTheme.primaryIndigo.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pets,
                  color: AppTheme.primaryIndigo,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Бақайдгирии чорвои нав',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Танҳо маълумоти асосии чорво дарҷ кунед. Хариданӣ ва хароҷотҳо баъдан илова мешаванд.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
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
            const Text(
              'Ховар (ихтиёрӣ)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: barns.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Ҳеҷ ховар бақайд нашудааст',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : DropdownButtonFormField<int>(
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
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Бе ховар'),
                        ),
                        ...barns.map((barn) {
                          final cattleCount = barnProvider.getCattleCount(barn.id!);
                          final isAtCapacity = barnProvider.isAtCapacity(barn.id!);
                          
                          return DropdownMenuItem<int>(
                            value: barn.id,
                            enabled: !isAtCapacity,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    barn.name,
                                    style: TextStyle(
                                      color: isAtCapacity ? Colors.grey : null,
                                    ),
                                  ),
                                ),
                                if (barn.capacity != null)
                                  Text(
                                    '$cattleCount/${barn.capacity}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isAtCapacity ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                if (isAtCapacity)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.block, size: 16, color: Colors.red),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedBarnId = value;
                        });
                      },
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              'Шумо метавонед чорворо ба ховар муайян кунед ё бидуни ховар бақайд кунед',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRegistrationDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Санаи бақайдгирӣ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Санаи бақайдгирӣ'),
            subtitle: Text(
              '${_registrationDate.day.toString().padLeft(2, '0')}/'
              '${_registrationDate.month.toString().padLeft(2, '0')}/'
              '${_registrationDate.year}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _selectRegistrationDate,
          ),
        ),
      ],
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
                'Бақайд кардан',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _selectRegistrationDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _registrationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _registrationDate = date;
      });
    }
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

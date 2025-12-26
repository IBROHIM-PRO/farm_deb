import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cattle_registry_provider.dart';
import '../../models/cattle_purchase.dart';
import '../../theme/app_theme.dart';

/// Add Cattle Purchase Screen - Record purchase event linked to cattle registry
/// Registry pattern: Purchase is separate event linked to cattle ID
class AddCattlePurchaseScreen extends StatefulWidget {
  final int cattleId;

  const AddCattlePurchaseScreen({
    super.key,
    required this.cattleId,
  });

  @override
  State<AddCattlePurchaseScreen> createState() => _AddCattlePurchaseScreenState();
}

class _AddCattlePurchaseScreenState extends State<AddCattlePurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _pricePerKgController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _sellerNameController = TextEditingController();
  final _transportationCostController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _purchaseDate = DateTime.now();
  String _currency = 'сомонӣ';
  PurchasePaymentStatus _paymentStatus = PurchasePaymentStatus.paid;
  bool _usePricePerKg = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сабти хариданӣ'),
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
              
              // Purchase Date
              _buildPurchaseDateSection(),
              
              const SizedBox(height: 24),
              
              // Weight Section
              _buildWeightSection(),
              
              const SizedBox(height: 24),
              
              // Price Section
              _buildPriceSection(),
              
              const SizedBox(height: 24),
              
              // Seller Information
              _buildSellerSection(),
              
              const SizedBox(height: 24),
              
              // Transportation Cost
              _buildTransportationSection(),
              
              const SizedBox(height: 24),
              
              // Payment Information
              _buildPaymentSection(),
              
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
      color: AppTheme.primaryIndigo.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.shopping_cart,
              color: AppTheme.primaryIndigo,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Сабти харидании чорво',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Маълумоти хариданӣ ба чорвои бақайдшуда пайваст мешавад',
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

  Widget _buildPurchaseDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Санаи хариданӣ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Санаи хариданӣ'),
            subtitle: Text(
              '${_purchaseDate.day.toString().padLeft(2, '0')}/'
              '${_purchaseDate.month.toString().padLeft(2, '0')}/'
              '${_purchaseDate.year}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _selectPurchaseDate,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Вазни чорво',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _weightController,
          decoration: InputDecoration(
            labelText: 'Вазн дар вақти хариданӣ',
            suffixText: 'кг',
            prefixIcon: const Icon(Icons.scale),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.trim().isEmpty == true) {
              return 'Вазни чорво зарур аст';
            }
            final weight = double.tryParse(value!);
            if (weight == null || weight <= 0) {
              return 'Вазни дуруст ворид кунед';
            }
            return null;
          },
          onChanged: _calculateTotalPrice,
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Нархгузорӣ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Price Type Selection
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Нарх аз рӯи кг'),
                value: true,
                groupValue: _usePricePerKg,
                onChanged: (value) {
                  setState(() {
                    _usePricePerKg = value!;
                    _totalPriceController.clear();
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Нархи умумӣ'),
                value: false,
                groupValue: _usePricePerKg,
                onChanged: (value) {
                  setState(() {
                    _usePricePerKg = value!;
                    _pricePerKgController.clear();
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        if (_usePricePerKg) ...[
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _pricePerKgController,
                  decoration: InputDecoration(
                    labelText: 'Нарх барои як кг',
                    suffixText: _currency,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    hintText: 'Нархро барои як кг дарҷ кунед',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_usePricePerKg && (value?.trim().isEmpty == true)) {
                      return 'Нархи як кг зарур аст';
                    }
                    return null;
                  },
                  onChanged: _calculateTotalPrice,
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
                    DropdownMenuItem(value: 'TJS', child: Text('сомонӣ')),
                    DropdownMenuItem(value: 'USD', child: Text('доллар')),
                    DropdownMenuItem(value: 'EUR', child: Text('евро')),
                    DropdownMenuItem(value: 'RUB', child: Text('рубл')),
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
          
          const SizedBox(height: 12),
          
          // Calculated Total Price Display
          if (_pricePerKgController.text.isNotEmpty && _weightController.text.isNotEmpty)
            Card(
              color: Colors.green.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.calculate, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text('Нархи умумӣ: '),
                    Text(
                      '${_getCalculatedTotal().toStringAsFixed(0)} $_currency',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ] else ...[
          TextFormField(
            controller: _totalPriceController,
            decoration: InputDecoration(
              labelText: 'Нархи умумӣ',
              suffixText: _currency,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              hintText: 'Нархи умумиро дарҷ кунед',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (!_usePricePerKg && (value?.trim().isEmpty == true)) {
                return 'Нархи умумӣ зарур аст';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSellerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Маълумоти фурушанда',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _sellerNameController,
          decoration: InputDecoration(
            labelText: 'Номи фурушанда (ихтиёрӣ)',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            hintText: 'Номи фурӯшандаро дарҷ кунед',
          ),
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildTransportationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Харҷи нақлиёт',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _transportationCostController,
          decoration: InputDecoration(
            labelText: 'Харҷи интиқол (ихтиёрӣ)',
            suffixText: _currency,
            prefixIcon: const Icon(Icons.local_shipping),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            hintText: 'Хароҷоти наклиётро дарҷ кунед',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Маълумоти пардохт',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Payment Status
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ҳолати пардохт:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<PurchasePaymentStatus>(
                        title: const Text('Пардохт'),
                        value: PurchasePaymentStatus.paid,
                        groupValue: _paymentStatus,
                        onChanged: (value) {
                          setState(() {
                            _paymentStatus = value!;
                            if (value == PurchasePaymentStatus.paid) {
                              _paidAmountController.clear();
                            }
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<PurchasePaymentStatus>(
                        title: const Text('Қисман'),
                        value: PurchasePaymentStatus.partial,
                        groupValue: _paymentStatus,
                        onChanged: (value) {
                          setState(() {
                            _paymentStatus = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                RadioListTile<PurchasePaymentStatus>(
                  title: const Text('Интизор'),
                  value: PurchasePaymentStatus.pending,
                  groupValue: _paymentStatus,
                  onChanged: (value) {
                    setState(() {
                      _paymentStatus = value!;
                      if (value == PurchasePaymentStatus.pending) {
                        _paidAmountController.clear();
                      }
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
        
        // Partial Payment Amount
        if (_paymentStatus == PurchasePaymentStatus.partial) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _paidAmountController,
            decoration: InputDecoration(
              labelText: 'Миқдори пардохташуда',
              suffixText: _currency,
              prefixIcon: const Icon(Icons.payments),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_paymentStatus == PurchasePaymentStatus.partial) {
                if (value?.trim().isEmpty == true) {
                  return 'Миқдори пардохташуда зарур аст';
                }
                final paid = double.tryParse(value!);
                if (paid == null || paid <= 0) {
                  return 'Миқдори дуруст ворид кунед';
                }
                final total = _getTotalCost();
                if (paid >= total) {
                  return 'Миқдор аз нархи умумӣ камтар бояд бошад';
                }
              }
              return null;
            },
          ),
        ],
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
        onPressed: _isLoading ? null : _savePurchase,
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
                'Хариданӣ сабт кардан',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  double _getCalculatedTotal() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final pricePerKg = double.tryParse(_pricePerKgController.text) ?? 0;
    return weight * pricePerKg;
  }

  double _getTotalCost() {
    final basePrice = _usePricePerKg 
        ? _getCalculatedTotal()
        : (double.tryParse(_totalPriceController.text) ?? 0);
    final transportCost = double.tryParse(_transportationCostController.text) ?? 0;
    return basePrice + transportCost;
  }

  void _calculateTotalPrice(String value) {
    setState(() {}); // Trigger rebuild to update calculated total display
  }

  Future<void> _selectPurchaseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _purchaseDate = date;
      });
    }
  }

  Future<void> _savePurchase() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final weight = double.parse(_weightController.text);
        final pricePerKg = _usePricePerKg ? double.parse(_pricePerKgController.text) : null;
        final totalPrice = !_usePricePerKg ? double.parse(_totalPriceController.text) : null;
        final transportationCost = double.tryParse(_transportationCostController.text) ?? 0;
        
        double paidAmount;
        switch (_paymentStatus) {
          case PurchasePaymentStatus.paid:
            paidAmount = _getTotalCost();
            break;
          case PurchasePaymentStatus.partial:
            paidAmount = double.parse(_paidAmountController.text);
            break;
          case PurchasePaymentStatus.pending:
            paidAmount = 0;
            break;
        }

        final purchase = CattlePurchase(
          cattleId: widget.cattleId,
          purchaseDate: _purchaseDate,
          weightAtPurchase: weight,
          pricePerKg: pricePerKg,
          totalPrice: totalPrice,
          currency: _currency,
          sellerName: _sellerNameController.text.trim().isNotEmpty 
              ? _sellerNameController.text.trim() 
              : null,
          transportationCost: transportationCost,
          paymentStatus: _paymentStatus,
          paidAmount: paidAmount,
          notes: _notesController.text.trim().isNotEmpty 
              ? _notesController.text.trim() 
              : null,
        );

        await context.read<CattleRegistryProvider>().addCattlePurchase(purchase);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Хариданӣ бомуваффақият сабт шуд'),
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
    _weightController.dispose();
    _pricePerKgController.dispose();
    _totalPriceController.dispose();
    _sellerNameController.dispose();
    _transportationCostController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/payment.dart';
import '../../models/debt.dart';
import '../../models/person.dart';
import '../../providers/app_provider.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final Debt debt;
  final Person person;

  const PaymentHistoryScreen({
    super.key,
    required this.debt,
    required this.person,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final payments = await appProvider.getPaymentsForDebt(widget.debt.id!);
      setState(() {
        _payments = payments..sort((a, b) => b.paymentDateTime.compareTo(a.paymentDateTime));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Таърихи пардохтҳо', style: TextStyle(fontSize: 18)),
            Text('${widget.person.fullName}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildDebtSummaryCard(),
                Expanded(child: _buildPaymentsList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPaymentDialog(),
        heroTag: "payment_history_fab",
        icon: Icon(Icons.payment),
        label: Text('Пардохти нав'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildDebtSummaryCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Маълумоти қарз', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.debt.status == DebtStatus.active ? Colors.orange[100] : Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.debt.statusDisplay,
                  style: TextStyle(
                    color: widget.debt.status == DebtStatus.active ? Colors.orange[800] : Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildSummaryRow('Намуди қарз:', widget.debt.typeDisplay),
          _buildSummaryRow('Маблағи умумӣ:', '${widget.debt.totalAmount.toStringAsFixed(2)} ${widget.debt.currency}'),
          _buildSummaryRow('Пардохт шуда:', '${widget.debt.paidAmount.toStringAsFixed(2)} ${widget.debt.currency}'),
          _buildSummaryRow('Боқӣ мондааст:', '${widget.debt.remainingAmount.toStringAsFixed(2)} ${widget.debt.currency}'),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: widget.debt.paymentProgress / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('Ягон пардохт сабт нашудааст', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _payments.length,
      itemBuilder: (context, index) => _buildPaymentCard(_payments[index]),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${payment.amount.toStringAsFixed(2)} ${widget.debt.currency}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[700]),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(payment.paymentTypeDisplay, style: TextStyle(fontSize: 12, color: Colors.blue[800])),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildPaymentDetailRow(Icons.calendar_today, 'Санаи пардохт:', payment.formattedPaymentDateTime),
          _buildPaymentDetailRow(Icons.access_time, 'Санаи сабт:', payment.formattedRecordedDateTime),
          _buildPaymentDetailRow(Icons.payment, 'Усули пардохт:', payment.paymentMethodDisplay),
          if (payment.receiptNumber != null) 
            _buildPaymentDetailRow(Icons.receipt, 'Рақами расид:', payment.receiptNumber!),
          if (payment.payerName != null && payment.payerName!.isNotEmpty) 
            _buildPaymentDetailRow(Icons.person, 'Пардохткунанда:', payment.payerName!),
          if (payment.location != null && payment.location!.isNotEmpty) 
            _buildPaymentDetailRow(Icons.location_on, 'Ҷойи пардохт:', payment.location!),
          if (payment.note != null && payment.note!.isNotEmpty) 
            _buildPaymentDetailRow(Icons.note, 'Шарҳ:', payment.note!),
          if (payment.remainingBalance != null) 
            _buildPaymentDetailRow(Icons.account_balance_wallet, 'Боқӣ монда:', '${payment.remainingBalance!.toStringAsFixed(2)} ${widget.debt.currency}'),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                Flexible(child: Text(value, style: TextStyle(fontSize: 14), textAlign: TextAlign.right)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AddPaymentDialog(debt: widget.debt, person: widget.person),
    ).then((_) => _loadPayments());
  }
}

class AddPaymentDialog extends StatefulWidget {
  final Debt debt;
  final Person person;

  const AddPaymentDialog({super.key, required this.debt, required this.person});

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _receiptController = TextEditingController();
  final _payerController = TextEditingController();
  final _locationController = TextEditingController();
  final _noteController = TextEditingController();
  
  DateTime _paymentDateTime = DateTime.now();
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(24),
        constraints: BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Сабти пардохти нав', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Маблағи пардохт *',
                          suffixText: widget.debt.currency,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final amount = double.tryParse(value ?? '');
                          if (amount == null || amount <= 0) return 'Маблағи дуруст ворид кунед';
                          if (amount > widget.debt.remainingAmount) return 'Аз боқимонда зиёд';
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<PaymentMethod>(
                        value: _paymentMethod,
                        decoration: InputDecoration(labelText: 'Усули пардохт', border: OutlineInputBorder()),
                        items: PaymentMethod.values.map((method) => DropdownMenuItem(
                          value: method,
                          child: Text(_getPaymentMethodDisplay(method)),
                        )).toList(),
                        onChanged: (value) => setState(() => _paymentMethod = value!),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _receiptController,
                        decoration: InputDecoration(labelText: 'Рақами расид', border: OutlineInputBorder()),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _payerController,
                        decoration: InputDecoration(labelText: 'Пардохткунанда', border: OutlineInputBorder()),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(labelText: 'Ҷойи пардохт', border: OutlineInputBorder()),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(labelText: 'Шарҳ', border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Бекор кардан'),
                  ),
                  ElevatedButton(
                    onPressed: _savePayment,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text('Сабт кардан', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPaymentMethodDisplay(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return 'Нақдӣ';
      case PaymentMethod.bankTransfer: return 'Интиқоли бонкӣ';
      case PaymentMethod.check: return 'Чек';
      case PaymentMethod.other: return 'Дигар';
    }
  }

  Future<void> _savePayment() async {
    if (_formKey.currentState!.validate()) {
      try {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.makeDetailedPayment(
          debt: widget.debt,
          amount: double.parse(_amountController.text),
          paymentDateTime: _paymentDateTime,
          paymentMethod: _paymentMethod,
          receiptNumber: _receiptController.text.isNotEmpty ? _receiptController.text : null,
          payerName: _payerController.text.isNotEmpty ? _payerController.text : null,
          location: _locationController.text.isNotEmpty ? _locationController.text : null,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Пардохт бо муваффақият сабт шуд')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хатогӣ: $e')),
        );
      }
    }
  }
}

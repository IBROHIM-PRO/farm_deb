import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/debt.dart';
import '../../models/person.dart';
import '../../models/payment.dart';

/// Comprehensive transaction history showing all debt and payment entries
class DebtTransactionHistoryScreen extends StatefulWidget {
  final Debt debt;

  const DebtTransactionHistoryScreen({super.key, required this.debt});

  @override
  State<DebtTransactionHistoryScreen> createState() => _DebtTransactionHistoryScreenState();
}

class _DebtTransactionHistoryScreenState extends State<DebtTransactionHistoryScreen> {
  late Person _person;
  List<Payment> _payments = [];
  List<_TransactionEntry> _timeline = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    
    // Get person details
    _person = provider.getPersonById(widget.debt.personId)!;
    
    // Load all payments for this debt
    _payments = await provider.getPaymentsByDebtId(widget.debt.id!);
    
    // Build comprehensive timeline
    _buildTimeline();
    
    setState(() {});
  }

  void _buildTimeline() {
    _timeline.clear();
    
    // Add initial debt creation
    _timeline.add(_TransactionEntry(
      type: _TransactionType.debtCreated,
      date: widget.debt.date,
      amount: widget.debt.totalAmount,
      currency: widget.debt.currency,
      description: widget.debt.type == DebtType.given 
          ? 'Қарз дода шуд ба ${_person.fullName}'
          : 'Қарз гирифта шуд аз ${_person.fullName}',
      runningBalance: widget.debt.totalAmount,
      debtType: widget.debt.type,
    ));
    
    // Add all payments
    double runningBalance = widget.debt.totalAmount;
    for (final payment in _payments.reversed) { // Oldest first
      runningBalance -= payment.amount;
      
      _timeline.add(_TransactionEntry(
        type: _TransactionType.payment,
        date: payment.date,
        amount: payment.amount,
        currency: widget.debt.currency,
        description: widget.debt.type == DebtType.given
            ? 'Пардохт дарёфт шуд аз ${_person.fullName}'
            : 'Пардохт ба ${_person.fullName}',
        runningBalance: runningBalance,
        debtType: widget.debt.type,
        note: payment.note,
        isPayment: true,
      ));
    }
    
    // Sort by date (newest first for display)
    _timeline.sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Таърихи муомилот'),
        centerTitle: true,
        backgroundColor: widget.debt.type == DebtType.given ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildPersonCard(),
          _buildDebtSummary(),
          Expanded(child: _buildTimelineView()),
        ],
      ),
    );
  }

  Widget _buildPersonCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: widget.debt.type == DebtType.given ? Colors.green[100] : Colors.blue[100],
            child: Icon(
              Icons.person,
              color: widget.debt.type == DebtType.given ? Colors.green : Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _person.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_person.phone != null && _person.phone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _person.phone!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (widget.debt.type == DebtType.given ? Colors.green : Colors.blue)[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.debt.type == DebtType.given ? 'Додашуда' : 'Гирифташуда',
              style: TextStyle(
                color: widget.debt.type == DebtType.given ? Colors.green[800] : Colors.blue[800],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.debt.type == DebtType.given 
              ? [Colors.green[600]!, Colors.green[400]!]
              : [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Маблағи умумӣ',
              '${widget.debt.totalAmount.toStringAsFixed(2)} ${widget.debt.currency}',
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildSummaryItem(
              'Боқимонда',
              '${widget.debt.remainingAmount.toStringAsFixed(2)} ${widget.debt.currency}',
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildSummaryItem(
              'Пардохт шуда',
              '${(widget.debt.totalAmount - widget.debt.remainingAmount).toStringAsFixed(2)} ${widget.debt.currency}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTimelineView() {
    if (_timeline.isEmpty) {
      return const Center(
        child: Text('Таърих мавҷуд нест'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _timeline.length,
      itemBuilder: (context, index) {
        final entry = _timeline[index];
        final isLast = index == _timeline.length - 1;
        
        return _buildTimelineEntry(entry, isLast);
      },
    );
  }

  Widget _buildTimelineEntry(_TransactionEntry entry, bool isLast) {
    final isDebtCreated = entry.type == _TransactionType.debtCreated;
    final color = isDebtCreated 
        ? (entry.debtType == DebtType.given ? Colors.green : Colors.blue)
        : Colors.orange;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line and dot
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: Colors.grey[300],
              ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Transaction details
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDebtCreated 
                              ? (entry.debtType == DebtType.given ? Icons.call_made : Icons.call_received)
                              : Icons.payment,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDebtCreated ? 'Қарз сабт шуд' : 'Пардохт',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm', 'en_US').format(entry.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  entry.description,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Маблаҳ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${entry.isPayment ? "-" : "+"}${entry.amount.toStringAsFixed(2)} ${entry.currency}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: entry.isPayment ? Colors.red : color,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Боқимонда',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${entry.runningBalance.toStringAsFixed(2)} ${entry.currency}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: entry.runningBalance <= 0 ? Colors.green : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.note!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Helper classes
enum _TransactionType { debtCreated, payment }

class _TransactionEntry {
  final _TransactionType type;
  final DateTime date;
  final double amount;
  final String currency;
  final String description;
  final double runningBalance;
  final DebtType debtType;
  final String? note;
  final bool isPayment;

  _TransactionEntry({
    required this.type,
    required this.date,
    required this.amount,
    required this.currency,
    required this.description,
    required this.runningBalance,
    required this.debtType,
    this.note,
    this.isPayment = false,
  });
}

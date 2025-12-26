enum PaymentMethod { cash, bankTransfer, check, other }
enum PaymentType { fullPayment, partialPayment, interestPayment }

class Payment {
  final int? id;
  final int debtId;
  final double amount;
  final DateTime paymentDateTime;  // Full date and time when payment was received
  final DateTime recordedDateTime; // When the payment was recorded in system
  final PaymentMethod paymentMethod;
  final PaymentType paymentType;
  final String? receiptNumber;     // Receipt or transaction reference
  final String? payerName;         // Who actually made the payment (if different from debtor)
  final String? bankDetails;       // Bank transfer details if applicable
  final double? remainingBalance;  // Remaining debt balance after this payment
  final String? note;
  final String? location;          // Where payment was received

  Payment({
    this.id,
    required this.debtId,
    required this.amount,
    required this.paymentDateTime,
    DateTime? recordedDateTime,
    this.paymentMethod = PaymentMethod.cash,
    this.paymentType = PaymentType.partialPayment,
    this.receiptNumber,
    this.payerName,
    this.bankDetails,
    this.remainingBalance,
    this.note,
    this.location,
  }) : recordedDateTime = recordedDateTime ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debtId': debtId,
      'amount': amount,
      'paymentDateTime': paymentDateTime.toIso8601String(),
      'recordedDateTime': recordedDateTime.toIso8601String(),
      'paymentMethod': paymentMethod.name,
      'paymentType': paymentType.name,
      'receiptNumber': receiptNumber,
      'payerName': payerName,
      'bankDetails': bankDetails,
      'remainingBalance': remainingBalance,
      'note': note,
      'location': location,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      debtId: (map['debtId'] as num?)?.toInt() ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDateTime: map['paymentDateTime'] != null 
          ? DateTime.parse(map['paymentDateTime'] as String) 
          : (map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now()), // Backward compatibility
      recordedDateTime: map['recordedDateTime'] != null 
          ? DateTime.parse(map['recordedDateTime'] as String) 
          : DateTime.now(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      paymentType: PaymentType.values.firstWhere(
        (e) => e.name == map['paymentType'],
        orElse: () => PaymentType.partialPayment,
      ),
      receiptNumber: map['receiptNumber'] as String?,
      payerName: map['payerName'] as String?,
      bankDetails: map['bankDetails'] as String?,
      remainingBalance: (map['remainingBalance'] as num?)?.toDouble(),
      note: map['note'] as String?,
      location: map['location'] as String?,
    );
  }

  Payment copyWith({
    int? id,
    int? debtId,
    double? amount,
    DateTime? paymentDateTime,
    DateTime? recordedDateTime,
    PaymentMethod? paymentMethod,
    PaymentType? paymentType,
    String? receiptNumber,
    String? payerName,
    String? bankDetails,
    double? remainingBalance,
    String? note,
    String? location,
  }) {
    return Payment(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amount: amount ?? this.amount,
      paymentDateTime: paymentDateTime ?? this.paymentDateTime,
      recordedDateTime: recordedDateTime ?? this.recordedDateTime,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentType: paymentType ?? this.paymentType,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      payerName: payerName ?? this.payerName,
      bankDetails: bankDetails ?? this.bankDetails,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      note: note ?? this.note,
      location: location ?? this.location,
    );
  }

  /// Payment method display name in Tajik
  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case PaymentMethod.cash: return 'Нақдӣ';
      case PaymentMethod.bankTransfer: return 'Интиқоли бонкӣ';
      case PaymentMethod.check: return 'Чек';
      case PaymentMethod.other: return 'Дигар';
    }
  }

  /// Payment type display name in Tajik
  String get paymentTypeDisplay {
    switch (paymentType) {
      case PaymentType.fullPayment: return 'Пардохти пурра';
      case PaymentType.partialPayment: return 'Пардохти қисмӣ';
      case PaymentType.interestPayment: return 'Пардохти фоида';
    }
  }

  /// Get formatted payment date and time
  String get formattedPaymentDateTime {
    return '${paymentDateTime.day}/${paymentDateTime.month}/${paymentDateTime.year} соат ${paymentDateTime.hour}:${paymentDateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted recorded date and time
  String get formattedRecordedDateTime {
    return '${recordedDateTime.day}/${recordedDateTime.month}/${recordedDateTime.year} соат ${recordedDateTime.hour}:${recordedDateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Check if payment was recorded on the same day it was received
  bool get isRecordedSameDay {
    return paymentDateTime.year == recordedDateTime.year &&
           paymentDateTime.month == recordedDateTime.month &&
           paymentDateTime.day == recordedDateTime.day;
  }

  /// Get time difference between payment and recording
  Duration get recordingDelay {
    return recordedDateTime.difference(paymentDateTime);
  }

  /// Get a comprehensive description of the payment
  String get paymentSummary {
    final buffer = StringBuffer();
    buffer.write('${paymentTypeDisplay}: ${amount.toStringAsFixed(2)} ');
    buffer.write('(${paymentMethodDisplay})');
    if (receiptNumber != null) {
      buffer.write(' - Расиди №${receiptNumber}');
    }
    if (payerName != null && payerName!.isNotEmpty) {
      buffer.write(' - Аз ${payerName}');
    }
    return buffer.toString();
  }

  /// Validates payment data
  static String? validate({
    required double amount,
    required DateTime paymentDateTime,
    String? receiptNumber,
  }) {
    if (amount <= 0) return 'Маблағи пардохт бояд аз сифр зиёд бошад';
    if (paymentDateTime.isAfter(DateTime.now().add(Duration(hours: 1)))) {
      return 'Санаи пардохт наметавонад дар оянда бошад';
    }
    if (receiptNumber != null && receiptNumber.trim().isEmpty) {
      return 'Рақами расид набояд холӣ бошад';
    }
    return null;
  }

  /// Create a payment record with automatic remaining balance calculation
  static Payment create({
    required int debtId,
    required double amount,
    required double currentDebtBalance,
    DateTime? paymentDateTime,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? receiptNumber,
    String? payerName,
    String? bankDetails,
    String? note,
    String? location,
  }) {
    final actualPaymentTime = paymentDateTime ?? DateTime.now();
    final remainingAfterPayment = (currentDebtBalance - amount).clamp(0.0, double.infinity);
    
    return Payment(
      debtId: debtId,
      amount: amount,
      paymentDateTime: actualPaymentTime,
      paymentMethod: paymentMethod,
      paymentType: remainingAfterPayment <= 0 ? PaymentType.fullPayment : PaymentType.partialPayment,
      receiptNumber: receiptNumber,
      payerName: payerName,
      bankDetails: bankDetails,
      remainingBalance: remainingAfterPayment,
      note: note,
      location: location,
    );
  }
}

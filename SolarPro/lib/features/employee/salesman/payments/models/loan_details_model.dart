import 'package:intl/intl.dart';

/// Single loan installment schedule entry.
class LoanInstallment {
  final String id;

  /// Installment amount in integer paise
  final int amountPaise;

  /// Expected payment / disbursement date
  final DateTime expectedDate;

  /// Received or pending status
  final bool isReceived;

  final String? notes;

  const LoanInstallment({
    required this.id,
    required this.amountPaise,
    required this.expectedDate,
    this.isReceived = false,
    this.notes,
  });

  int get amountRupees => amountPaise ~/ 100;

  String get formattedAmount {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(amountRupees);
  }

  String get formattedExpectedDate {
    return DateFormat('dd MMM yyyy').format(expectedDate);
  }

  LoanInstallment copyWith({
    String? id,
    int? amountPaise,
    DateTime? expectedDate,
    bool? isReceived,
    String? notes,
  }) {
    return LoanInstallment(
      id: id ?? this.id,
      amountPaise: amountPaise ?? this.amountPaise,
      expectedDate: expectedDate ?? this.expectedDate,
      isReceived: isReceived ?? this.isReceived,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amountPaise': amountPaise,
      'expectedDate': expectedDate.toIso8601String(),
      'isReceived': isReceived,
      'notes': notes,
    };
  }

  factory LoanInstallment.fromJson(Map<String, dynamic> json) {
    return LoanInstallment(
      id: json['id']?.toString() ?? '',
      amountPaise: (json['amountPaise'] is num) ? (json['amountPaise'] as num).toInt() : 0,
      expectedDate: json['expectedDate'] != null
          ? DateTime.tryParse(json['expectedDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isReceived: json['isReceived'] is bool ? json['isReceived'] as bool : false,
      notes: json['notes']?.toString(),
    );
  }
}

/// Customer loan details and flexible installment schedule.
class LoanDetailsModel {
  final String customerId;
  final bool hasLoan;
  final String bankName;

  /// Sanctioned loan amount in integer paise
  final int loanAmountPaise;

  /// Installments of ANY length
  final List<LoanInstallment> installments;

  const LoanDetailsModel({
    required this.customerId,
    this.hasLoan = false,
    this.bankName = '',
    this.loanAmountPaise = 0,
    this.installments = const [],
  });

  int get loanAmountRupees => loanAmountPaise ~/ 100;

  String get formattedLoanAmount {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(loanAmountRupees);
  }

  /// Sum of all installments in integer paise
  int get totalInstallmentsPaise {
    return installments.fold(0, (sum, i) => sum + i.amountPaise);
  }

  int get totalInstallmentsRupees => totalInstallmentsPaise ~/ 100;

  String get formattedTotalInstallments {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(totalInstallmentsRupees);
  }

  /// Business Rule: Installment total must not exceed the loan amount
  bool get isExceedingLoanAmount => totalInstallmentsPaise > loanAmountPaise;

  int get receivedInstallmentsPaise {
    return installments.where((i) => i.isReceived).fold(0, (sum, i) => sum + i.amountPaise);
  }

  String get formattedReceivedInstallments {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(receivedInstallmentsPaise ~/ 100);
  }

  LoanDetailsModel copyWith({
    String? customerId,
    bool? hasLoan,
    String? bankName,
    int? loanAmountPaise,
    List<LoanInstallment>? installments,
  }) {
    return LoanDetailsModel(
      customerId: customerId ?? this.customerId,
      hasLoan: hasLoan ?? this.hasLoan,
      bankName: bankName ?? this.bankName,
      loanAmountPaise: loanAmountPaise ?? this.loanAmountPaise,
      installments: installments ?? this.installments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'hasLoan': hasLoan,
      'bankName': bankName,
      'loanAmountPaise': loanAmountPaise,
      'installments': installments.map((i) => i.toJson()).toList(),
    };
  }

  factory LoanDetailsModel.fromJson(Map<String, dynamic> json) {
    return LoanDetailsModel(
      customerId: json['customerId']?.toString() ?? '',
      hasLoan: json['hasLoan'] is bool ? json['hasLoan'] as bool : false,
      bankName: json['bankName']?.toString() ?? '',
      loanAmountPaise: (json['loanAmountPaise'] is num) ? (json['loanAmountPaise'] as num).toInt() : 0,
      installments: (json['installments'] is List)
          ? (json['installments'] as List)
              .map((e) => LoanInstallment.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solar_pro/core/theme/app_theme.dart';

/// Single customer payment record matching backend `PaymentRead` schema.
///
/// NOTE on Money: All monetary amounts (`amount`) are stored in strict integer
/// paise (1 Rupee = 100 paise) as required by project architecture rules.
class PaymentModel {
  final String id;
  final String customerId;
  final int stageNo;

  /// Amount in integer paise (e.g. 5000000 = ₹50,000)
  final int amount;

  /// Mode: "cash", "upi", "bank_transfer", "cheque", "other"
  final String mode;

  final String? referenceNo;
  final DateTime paidOn;
  final String? proofKey;
  final String? proofUrl;

  /// Status: "pending", "sales_approved", "verified", "rejected"
  final String status;

  final String submittedBy;
  final String submittedByRole;
  final String? salesApprovedBy;
  final DateTime? salesApprovedAt;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentModel({
    required this.id,
    required this.customerId,
    this.stageNo = 1,
    required this.amount,
    required this.mode,
    this.referenceNo,
    required this.paidOn,
    this.proofKey,
    this.proofUrl,
    required this.status,
    required this.submittedBy,
    required this.submittedByRole,
    this.salesApprovedBy,
    this.salesApprovedAt,
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionReason,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Rupee amount computed via integer division
  int get amountInRupees => amount ~/ 100;

  /// Formatted price in Indian Rupees (e.g., ₹50,000)
  String get formattedAmountRupees {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(amountInRupees);
  }

  /// Formatted date string (e.g., 12 Oct 2026)
  String get formattedPaidDate {
    return DateFormat('dd MMM yyyy').format(paidOn);
  }

  /// Human-readable UI status label
  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending Approval';
      case 'sales_approved':
        return 'Waiting for Admin';
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  /// Theme color for status badges
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.gold500;
      case 'sales_approved':
        return AppColors.info;
      case 'verified':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }

  /// Human-readable payment mode label
  String get modeLabel {
    switch (mode.toLowerCase()) {
      case 'upi':
        return 'UPI / QR Code';
      case 'bank_transfer':
        return 'NEFT / RTGS Transfer';
      case 'cheque':
        return 'Bank Cheque';
      case 'cash':
        return 'Cash Payment';
      default:
        return mode.toUpperCase();
    }
  }

  IconData get modeIcon {
    switch (mode.toLowerCase()) {
      case 'upi':
        return Icons.qr_code_scanner_rounded;
      case 'bank_transfer':
        return Icons.account_balance_rounded;
      case 'cheque':
        return Icons.receipt_long_rounded;
      case 'cash':
        return Icons.payments_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      stageNo: (json['stage_no'] is num) ? (json['stage_no'] as num).toInt() : 1,
      amount: (json['amount'] is num) ? (json['amount'] as num).toInt() : 0,
      mode: json['mode']?.toString() ?? 'upi',
      referenceNo: json['reference_no']?.toString(),
      paidOn: json['paid_on'] != null
          ? DateTime.tryParse(json['paid_on'].toString()) ?? DateTime.now()
          : DateTime.now(),
      proofKey: json['proof_key']?.toString(),
      proofUrl: json['proof_url']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      submittedBy: json['submitted_by']?.toString() ?? '',
      submittedByRole: json['submitted_by_role']?.toString() ?? 'client',
      salesApprovedBy: json['sales_approved_by']?.toString(),
      salesApprovedAt: json['sales_approved_at'] != null
          ? DateTime.tryParse(json['sales_approved_at'].toString())
          : null,
      verifiedBy: json['verified_by']?.toString(),
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'].toString())
          : null,
      rejectionReason: json['rejection_reason']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'stage_no': stageNo,
      'amount': amount,
      'mode': mode,
      'reference_no': referenceNo,
      'paid_on': paidOn.toIso8601String(),
      'proof_key': proofKey,
      'proof_url': proofUrl,
      'status': status,
      'submitted_by': submittedBy,
      'submitted_by_role': submittedByRole,
      'sales_approved_by': salesApprovedBy,
      'sales_approved_at': salesApprovedAt?.toIso8601String(),
      'verified_by': verifiedBy,
      'verified_at': verifiedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'remarks': remarks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Overall financial summary matching backend `PaymentSummary` schema.
/// All monetary fields are in integer paise.
class PaymentSummaryModel {
  final int finalPrice;
  final int totalVerified;
  final int totalPending;
  final int balance;
  final String status; // "pending", "partially_paid", "fully_paid"

  const PaymentSummaryModel({
    required this.finalPrice,
    required this.totalVerified,
    required this.totalPending,
    required this.balance,
    required this.status,
  });

  int get finalPriceInRupees => finalPrice ~/ 100;
  int get totalVerifiedInRupees => totalVerified ~/ 100;
  int get totalPendingInRupees => totalPending ~/ 100;
  int get balanceInRupees => balance ~/ 100;

  String get formattedFinalPrice {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(finalPriceInRupees);
  }

  String get formattedVerified {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(totalVerifiedInRupees);
  }

  String get formattedPending {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(totalPendingInRupees);
  }

  String get formattedBalance {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(balanceInRupees);
  }

  /// Percentage of contract verified (0.0 to 1.0)
  double get verifiedProgress {
    if (finalPrice <= 0) return 0.0;
    return (totalVerified / finalPrice).clamp(0.0, 1.0);
  }

  factory PaymentSummaryModel.fromJson(Map<String, dynamic> json) {
    return PaymentSummaryModel(
      finalPrice: (json['final_price'] is num) ? (json['final_price'] as num).toInt() : 0,
      totalVerified: (json['total_verified'] is num) ? (json['total_verified'] as num).toInt() : 0,
      totalPending: (json['total_pending'] is num) ? (json['total_pending'] as num).toInt() : 0,
      balance: (json['balance'] is num) ? (json['balance'] as num).toInt() : 0,
      status: json['status']?.toString() ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'final_price': finalPrice,
      'total_verified': totalVerified,
      'total_pending': totalPending,
      'balance': balance,
      'status': status,
    };
  }
}

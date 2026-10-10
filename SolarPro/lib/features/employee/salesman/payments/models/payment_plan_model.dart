import 'package:intl/intl.dart';

/// Single milestone in a salesman-defined payment plan.
/// Supports free-text title, toggle between percentage or fixed amount, and due condition.
class PaymentMilestone {
  final String id;
  final String title;
  final bool isPercentage;
  final double percentage;
  final int fixedAmountPaise;
  final String? dueCondition;

  const PaymentMilestone({
    required this.id,
    required this.title,
    this.isPercentage = true,
    this.percentage = 0.0,
    this.fixedAmountPaise = 0,
    this.dueCondition,
  });

  /// Compute actual amount in paise given the customer's total contract price
  int computedAmountPaise(int finalPricePaise) {
    if (isPercentage) {
      return (finalPricePaise * (percentage / 100.0)).round();
    }
    return fixedAmountPaise;
  }

  /// Rupee representation of computed or fixed amount
  int computedAmountRupees(int finalPricePaise) {
    return computedAmountPaise(finalPricePaise) ~/ 100;
  }

  String formattedAmount(int finalPricePaise) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(computedAmountRupees(finalPricePaise));
  }

  PaymentMilestone copyWith({
    String? id,
    String? title,
    bool? isPercentage,
    double? percentage,
    int? fixedAmountPaise,
    String? dueCondition,
  }) {
    return PaymentMilestone(
      id: id ?? this.id,
      title: title ?? this.title,
      isPercentage: isPercentage ?? this.isPercentage,
      percentage: percentage ?? this.percentage,
      fixedAmountPaise: fixedAmountPaise ?? this.fixedAmountPaise,
      dueCondition: dueCondition ?? this.dueCondition,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isPercentage': isPercentage,
      'percentage': percentage,
      'fixedAmountPaise': fixedAmountPaise,
      'dueCondition': dueCondition,
    };
  }

  factory PaymentMilestone.fromJson(Map<String, dynamic> json) {
    return PaymentMilestone(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      isPercentage: json['isPercentage'] is bool ? json['isPercentage'] as bool : true,
      percentage: (json['percentage'] is num) ? (json['percentage'] as num).toDouble() : 0.0,
      fixedAmountPaise: (json['fixedAmountPaise'] is num) ? (json['fixedAmountPaise'] as num).toInt() : 0,
      dueCondition: json['dueCondition']?.toString(),
    );
  }
}

/// Bespoke payment plan defined per customer by the salesman.
///
/// BUSINESS RULE: There are NO fixed or predefined payment terms. Never hard-code
/// percentages or stages. The salesman defines the payment plan for every customer.
class PaymentPlanModel {
  final String customerId;
  final List<PaymentMilestone> milestones;

  /// Once the first customer payment is approved, the plan is locked for the salesman.
  final bool isLocked;

  const PaymentPlanModel({
    required this.customerId,
    this.milestones = const [],
    this.isLocked = false,
  });

  /// Total sum of percentage milestones
  double get totalPercentage {
    return milestones
        .where((m) => m.isPercentage)
        .fold(0.0, (sum, m) => sum + m.percentage);
  }

  /// Total sum of all milestones in paise
  int totalPaise(int finalPricePaise) {
    return milestones.fold(0, (sum, m) => sum + m.computedAmountPaise(finalPricePaise));
  }

  /// Check whether all milestones sum to exactly 100% (or equal final price)
  bool isFullyAllocated(int finalPricePaise) {
    if (milestones.isEmpty) return false;

    final allPercentage = milestones.every((m) => m.isPercentage);
    if (allPercentage) {
      return (totalPercentage - 100.0).abs() < 0.01;
    }

    return totalPaise(finalPricePaise) == finalPricePaise;
  }

  PaymentPlanModel copyWith({
    String? customerId,
    List<PaymentMilestone>? milestones,
    bool? isLocked,
  }) {
    return PaymentPlanModel(
      customerId: customerId ?? this.customerId,
      milestones: milestones ?? this.milestones,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'isLocked': isLocked,
      'milestones': milestones.map((m) => m.toJson()).toList(),
    };
  }

  factory PaymentPlanModel.fromJson(Map<String, dynamic> json) {
    return PaymentPlanModel(
      customerId: json['customerId']?.toString() ?? '',
      isLocked: json['isLocked'] is bool ? json['isLocked'] as bool : false,
      milestones: (json['milestones'] is List)
          ? (json['milestones'] as List)
              .map((e) => PaymentMilestone.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
    );
  }
}

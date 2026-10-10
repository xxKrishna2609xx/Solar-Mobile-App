import 'package:flutter_test/flutter_test.dart';
import 'package:solar_pro/features/employee/salesman/payments/models/loan_details_model.dart';
import 'package:solar_pro/features/employee/salesman/payments/models/payment_plan_model.dart';
import 'package:solar_pro/features/payments/data/models/payment_model.dart';

void main() {
  group('Prompt 5: Salesman Payments, Payment Plan, and Loan Tests', () {
    const finalPricePaise = 25000000; // ₹2,50,000 in integer paise

    test('Bespoke Payment Plan: Different customers can have different plans', () {
      // Customer A: 3 milestones
      const planA = PaymentPlanModel(
        customerId: 'cust-a',
        milestones: [
          PaymentMilestone(id: '1', title: 'Advance', isPercentage: true, percentage: 20.0),
          PaymentMilestone(id: '2', title: 'Material', isPercentage: true, percentage: 60.0),
          PaymentMilestone(id: '3', title: 'Handover', isPercentage: true, percentage: 20.0),
        ],
      );

      // Customer B: 5 milestones
      const planB = PaymentPlanModel(
        customerId: 'cust-b',
        milestones: [
          PaymentMilestone(id: '1', title: 'Token', isPercentage: true, percentage: 10.0),
          PaymentMilestone(id: '2', title: 'Structure Ready', isPercentage: true, percentage: 30.0),
          PaymentMilestone(id: '3', title: 'Panels Delivery', isPercentage: true, percentage: 30.0),
          PaymentMilestone(id: '4', title: 'Inverter & Wiring', isPercentage: true, percentage: 20.0),
          PaymentMilestone(id: '5', title: 'Commissioning', isPercentage: true, percentage: 10.0),
        ],
      );

      expect(planA.milestones.length, equals(3));
      expect(planA.totalPercentage, equals(100.0));
      expect(planA.isFullyAllocated(finalPricePaise), isTrue);

      expect(planB.milestones.length, equals(5));
      expect(planB.totalPercentage, equals(100.0));
      expect(planB.isFullyAllocated(finalPricePaise), isTrue);
    });

    test('Payment Plan allocation validation: 100% vs unbalanced', () {
      const unbalancedPlan = PaymentPlanModel(
        customerId: 'cust-c',
        milestones: [
          PaymentMilestone(id: '1', title: 'Advance', isPercentage: true, percentage: 25.0),
          PaymentMilestone(id: '2', title: 'Delivery', isPercentage: true, percentage: 50.0),
        ],
      );

      expect(unbalancedPlan.totalPercentage, equals(75.0));
      expect(unbalancedPlan.isFullyAllocated(finalPricePaise), isFalse);

      const fixedAmountPlan = PaymentPlanModel(
        customerId: 'cust-d',
        milestones: [
          PaymentMilestone(id: '1', title: 'Part 1', isPercentage: false, fixedAmountPaise: 10000000), // ₹1,00,000
          PaymentMilestone(id: '2', title: 'Part 2', isPercentage: false, fixedAmountPaise: 15000000), // ₹1,50,000
        ],
      );

      expect(fixedAmountPlan.totalPaise(finalPricePaise), equals(25000000));
      expect(fixedAmountPlan.isFullyAllocated(finalPricePaise), isTrue);
    });

    test('Plan lock enforcement once first payment is approved', () {
      const activePlan = PaymentPlanModel(
        customerId: 'cust-lock-test',
        isLocked: false,
      );
      expect(activePlan.isLocked, isFalse);

      final lockedPlan = activePlan.copyWith(isLocked: true);
      expect(lockedPlan.isLocked, isTrue);
    });

    test('Loan Details: Installment total must not exceed sanctioned loan amount', () {
      final validLoan = LoanDetailsModel(
        customerId: 'cust-loan-1',
        hasLoan: true,
        bankName: 'State Bank of India',
        loanAmountPaise: 20000000, // ₹2,00,000
        installments: [
          LoanInstallment(id: 'i1', amountPaise: 10000000, expectedDate: DateTime.now()), // ₹1,00,000
          LoanInstallment(id: 'i2', amountPaise: 10000000, expectedDate: DateTime.now()), // ₹1,00,000
        ],
      );

      expect(validLoan.totalInstallmentsPaise, equals(20000000));
      expect(validLoan.isExceedingLoanAmount, isFalse);

      final exceedingLoan = validLoan.copyWith(
        installments: [
          ...validLoan.installments,
          LoanInstallment(id: 'i3', amountPaise: 5000000, expectedDate: DateTime.now()), // +₹50,000
        ],
      );

      expect(exceedingLoan.totalInstallmentsPaise, equals(25000000));
      expect(exceedingLoan.isExceedingLoanAmount, isTrue);
    });

    test('Money figures strictly use integer paise', () {
      final payment = PaymentModel(
        id: 'pay-1',
        customerId: 'cust-1',
        amount: 7500000, // ₹75,000
        mode: 'upi',
        paidOn: DateTime.now(),
        status: 'pending',
        submittedBy: 'user-1',
        submittedByRole: 'client',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(payment.amount, equals(7500000));
      expect(payment.amountInRupees, equals(75000));
      expect(payment.formattedAmountRupees, contains('75,000'));
      expect(payment.statusLabel, equals('Pending Approval'));
    });

    test('Sales approval moves status to "Waiting for Admin"', () {
      final payment = PaymentModel(
        id: 'pay-2',
        customerId: 'cust-2',
        amount: 5000000,
        mode: 'bank_transfer',
        paidOn: DateTime.now(),
        status: 'sales_approved',
        submittedBy: 'user-2',
        submittedByRole: 'client',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(payment.statusLabel, equals('Waiting for Admin'));
    });

    test('PaymentSummaryModel handles verified, pending and balance totals in paise', () {
      const summary = PaymentSummaryModel(
        finalPrice: 25000000, // ₹2,50,000
        totalVerified: 10000000, // ₹1,00,000
        totalPending: 5000000, // ₹50,000
        balance: 15000000, // ₹1,50,000
        status: 'partially_paid',
      );

      expect(summary.finalPriceInRupees, equals(250000));
      expect(summary.totalVerifiedInRupees, equals(100000));
      expect(summary.totalPendingInRupees, equals(50000));
      expect(summary.balanceInRupees, equals(150000));
      expect(summary.verifiedProgress, equals(0.4)); // 40% verified
      expect(summary.formattedBalance, contains('1,50,000'));
    });
  });
}

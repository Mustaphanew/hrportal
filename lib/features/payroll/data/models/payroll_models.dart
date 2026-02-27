// ⚠️ API CONTRACT v1.0.0 — Fields match §10.7 exactly.

import 'package:equatable/equatable.dart';

import '../../../../core/network/pagination.dart';

/// A single line item within a payslip.
///
/// Represents one earning or deduction row.
class PayslipLine extends Equatable {
  final String? ruleCode;
  final String? ruleName;
  final String type;      // earning|deduction
  final double amount;
  final double quantity;
  final double rate;

  const PayslipLine({
    this.ruleCode,
    this.ruleName,
    required this.type,
    required this.amount,
    required this.quantity,
    required this.rate,
  });

  factory PayslipLine.fromJson(Map<String, dynamic> json) {
    return PayslipLine(
      ruleCode: json['rule_code'] as String?,
      ruleName: json['rule_name'] as String?,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'rule_code': ruleCode,
        'rule_name': ruleName,
        'type': type,
        'amount': amount,
        'quantity': quantity,
        'rate': rate,
      };

  bool get isEarning => type == 'earning';
  bool get isDeduction => type == 'deduction';

  @override
  List<Object?> get props => [ruleCode, type, amount];
}

/// Employee payslip for a specific pay period.
///
/// Contract: §10.7 Payslip
class Payslip extends Equatable {
  // ── Non-nullable ──
  final int id;
  final String status;
  final double totalGross;
  final double totalDeductions;
  final double totalNet;

  // ── Nullable ──
  final String? runNo;
  final String? periodStart;     // Y-m-d
  final String? periodEnd;       // Y-m-d
  final String? frequency;
  final String? currency;
  final List<PayslipLine>? lines; // Only in detail view
  final String? paymentMethod;
  final String? paidAt;          // Y-m-d H:i:s

  const Payslip({
    required this.id,
    required this.status,
    required this.totalGross,
    required this.totalDeductions,
    required this.totalNet,
    this.runNo,
    this.periodStart,
    this.periodEnd,
    this.frequency,
    this.currency,
    this.lines,
    this.paymentMethod,
    this.paidAt,
  });

  factory Payslip.fromJson(Map<String, dynamic> json) {
    return Payslip(
      id: json['id'] as int,
      status: json['status'] as String,
      totalGross: (json['total_gross'] as num).toDouble(),
      totalDeductions: (json['total_deductions'] as num).toDouble(),
      totalNet: (json['total_net'] as num).toDouble(),
      runNo: json['run_no'] as String?,
      periodStart: json['period_start'] as String?,
      periodEnd: json['period_end'] as String?,
      frequency: json['frequency'] as String?,
      currency: json['currency'] as String?,
      lines: json['lines'] != null
          ? (json['lines'] as List)
              .map((e) => PayslipLine.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      paymentMethod: json['payment_method'] as String?,
      paidAt: json['paid_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'total_gross': totalGross,
        'total_deductions': totalDeductions,
        'total_net': totalNet,
        'run_no': runNo,
        'period_start': periodStart,
        'period_end': periodEnd,
        'frequency': frequency,
        'currency': currency,
        'lines': lines?.map((l) => l.toJson()).toList(),
        'payment_method': paymentMethod,
        'paid_at': paidAt,
      };

  @override
  List<Object?> get props => [id];
}

/// Parsed data from GET /payroll.
///
/// Contract: §7.1 — `{payslips, pagination}`
class PayrollData {
  final List<Payslip> payslips;
  final Pagination pagination;

  const PayrollData({
    required this.payslips,
    required this.pagination,
  });

  factory PayrollData.fromJson(Map<String, dynamic> json) {
    return PayrollData(
      payslips: (json['payslips'] as List)
          .map((e) => Payslip.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

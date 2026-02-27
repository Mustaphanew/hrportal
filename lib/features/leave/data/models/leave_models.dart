// ⚠️ API CONTRACT v1.0.0 — Fields match §10.4, §10.5, §6.1 exactly.

import 'package:equatable/equatable.dart';

import '../../../../core/network/pagination.dart';

// ═══════════════════════════════════════════════════════════════════
// Shared: LeaveType (used in balance, request, and leave_types list)
// ═══════════════════════════════════════════════════════════════════

/// Leave type info embedded in balances and requests.
///
/// Also returned as standalone items in `leave_types[]` array.
class LeaveType extends Equatable {
  final int? id;
  final String code;
  final String name;
  final String? nameEn;
  final String? color;
  final bool isPaid;

  // ── Only present in leave_types[] list (§6.1) ──
  final bool? allowsHalfDay;
  final bool? allowsHourly;
  final bool? requiresAttachment;
  final int? minNoticeDays;
  final int? maxConsecutiveDays;

  const LeaveType({
    required this.id,
    required this.code,
    required this.name,
    this.nameEn,
    this.color,
    required this.isPaid,
    this.allowsHalfDay,
    this.allowsHourly,
    this.requiresAttachment,
    this.minNoticeDays,
    this.maxConsecutiveDays,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: json['id']?? 0,
      code: json['code'] as String,
      name: json['name'] as String,
      nameEn: json['name_en'] as String?,
      color: json['color'] as String?,
      isPaid: json['is_paid'] as bool,
      allowsHalfDay: json['allows_half_day'] as bool?,
      allowsHourly: json['allows_hourly'] as bool?,
      requiresAttachment: json['requires_attachment'] as bool?,
      minNoticeDays: json['min_notice_days'] as int?,
      maxConsecutiveDays: json['max_consecutive_days'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'name_en': nameEn,
        'color': color,
        'is_paid': isPaid,
        if (allowsHalfDay != null) 'allows_half_day': allowsHalfDay,
        if (allowsHourly != null) 'allows_hourly': allowsHourly,
        if (requiresAttachment != null)
          'requires_attachment': requiresAttachment,
        if (minNoticeDays != null) 'min_notice_days': minNoticeDays,
        if (maxConsecutiveDays != null)
          'max_consecutive_days': maxConsecutiveDays,
      };

  @override
  List<Object?> get props => [id, code];
}

// ═══════════════════════════════════════════════════════════════════
// §10.4 LeaveBalance
// ═══════════════════════════════════════════════════════════════════

/// Employee leave balance for a specific year and type.
///
/// Contract: §10.4 LeaveBalance
class LeaveBalance extends Equatable {
  final int? id;
  final int? year;
  final LeaveType? leaveType;
  final double totalEntitlement;
  final double used;
  final double pending;
  final double available;
  final double carriedForward;

  const LeaveBalance({
    required this.id,
    required this.year,
    this.leaveType,
    required this.totalEntitlement,
    required this.used,
    required this.pending,
    required this.available,
    required this.carriedForward,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      id: json['id'] ?? 0,
      year: json['year'] ?? 0,
      leaveType: json['leave_type'] != null
          ? LeaveType.fromJson(json['leave_type'] as Map<String, dynamic>)
          : null,
      totalEntitlement: (json['total_entitlement'] as num).toDouble(),
      used: (json['used'] as num).toDouble(),
      pending: (json['pending'] as num).toDouble(),
      available: (json['available'] as num).toDouble(),
      carriedForward: (json['carried_forward'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'year': year,
        'leave_type': leaveType?.toJson(),
        'total_entitlement': totalEntitlement,
        'used': used,
        'pending': pending,
        'available': available,
        'carried_forward': carriedForward,
      };

  @override
  List<Object?> get props => [id, year];
}

// ═══════════════════════════════════════════════════════════════════
// §10.5 LeaveRequest + LeaveDay
// ═══════════════════════════════════════════════════════════════════

/// A single day entry within a leave request's `days` array.
class LeaveDay extends Equatable {
  final String date;       // Y-m-d
  final String dayPart;    // full|first_half|second_half
  final double dayValue;
  final bool isHoliday;
  final bool isWeekend;

  const LeaveDay({
    required this.date,
    required this.dayPart,
    required this.dayValue,
    required this.isHoliday,
    required this.isWeekend,
  });

  factory LeaveDay.fromJson(Map<String, dynamic> json) {
    return LeaveDay(
      date: json['date'] as String,
      dayPart: json['day_part'] as String,
      dayValue: (json['day_value'] as num).toDouble(),
      isHoliday: json['is_holiday'] as bool,
      isWeekend: json['is_weekend'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'day_part': dayPart,
        'day_value': dayValue,
        'is_holiday': isHoliday,
        'is_weekend': isWeekend,
      };

  @override
  List<Object?> get props => [date];
}

/// Employee leave request.
///
/// Contract: §10.5 LeaveRequest
class LeaveRequest extends Equatable {
  // ── Non-nullable ──
  final int? id;
  final String startDate;     // Y-m-d
  final String endDate;       // Y-m-d
  final double totalDays;
  final String dayPart;       // full|first_half|second_half
  final String status;        // draft|pending|approved|rejected|cancelled
  final String createdAt;     // Y-m-d H:i:s

  // ── Nullable ──
  final LeaveType? leaveType;
  final String? reason;
  final String? rejectionReason;
  final int? approvedBy;
  final String? approvedAt;   // Y-m-d H:i:s
  final List<LeaveDay>? days; // Only in detail view

  const LeaveRequest({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.dayPart,
    required this.status,
    required this.createdAt,
    this.leaveType,
    this.reason,
    this.rejectionReason,
    this.approvedBy,
    this.approvedAt,
    this.days,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] ?? 0,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      totalDays: (json['total_days'] as num).toDouble(),
      dayPart: json['day_part'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      leaveType: json['leave_type'] != null
          ? LeaveType.fromJson(json['leave_type'] as Map<String, dynamic>)
          : null,
      reason: json['reason'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      approvedBy: json['approved_by'] as int?,
      approvedAt: json['approved_at'] as String?,
      days: json['days'] != null
          ? (json['days'] as List)
              .map((e) => LeaveDay.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'start_date': startDate,
        'end_date': endDate,
        'total_days': totalDays,
        'day_part': dayPart,
        'status': status,
        'created_at': createdAt,
        'leave_type': leaveType?.toJson(),
        'reason': reason,
        'rejection_reason': rejectionReason,
        'approved_by': approvedBy,
        'approved_at': approvedAt,
        'days': days?.map((d) => d.toJson()).toList(),
      };

  @override
  List<Object?> get props => [id];
}

// ═══════════════════════════════════════════════════════════════════
// Composite: LeavesData (from GET /leaves)
// ═══════════════════════════════════════════════════════════════════

/// Parsed data from GET /leaves.
///
/// Contract: §6.1 — `{balances, requests, leave_types, pagination}`
class LeavesData {
  final List<LeaveBalance> balances;
  final List<LeaveRequest> requests;
  final List<LeaveType> leaveTypes;
  final Pagination pagination;

  const LeavesData({
    required this.balances,
    required this.requests,
    required this.leaveTypes,
    required this.pagination,
  });

  factory LeavesData.fromJson(Map<String, dynamic> json) {
    return LeavesData(
      balances: (json['balances'] as List)
          .map((e) => LeaveBalance.fromJson(e as Map<String, dynamic>))
          .toList(),
      requests: (json['requests'] as List)
          .map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      leaveTypes: (json['leave_types'] as List)
          .map((e) => LeaveType.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

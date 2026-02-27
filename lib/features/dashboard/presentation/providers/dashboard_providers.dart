import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../attendance/data/models/attendance_models.dart';
import '../../../profile/data/models/employee_profile_model.dart';
import '../../../../core/providers/core_providers.dart';

/// Loads the employee profile for display on the dashboard.
final profileProvider = FutureProvider<EmployeeProfile>((ref) async {
  final repo = ref.read(profileRepositoryProvider);
  return repo.getProfile();
});

/// Loads current-month attendance summary for the dashboard card.
final dashboardAttendanceProvider = FutureProvider<AttendanceSummary>((ref) async {
  final repo = ref.read(attendanceRepositoryProvider);

  final now = DateTime.now();
  final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

  final history = await repo.getHistory(month: month, page: 1, perPage: 31);
  return history.summary;
});

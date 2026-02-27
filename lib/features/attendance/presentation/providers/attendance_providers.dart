import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/models/attendance_models.dart';
import '../../../../shared/controllers/paginated_controller.dart';
import '../../../../shared/controllers/global_error_handler.dart';

// ═══════════════════════════════════════════════════════════════════
// Check-In / Check-Out Actions
// ═══════════════════════════════════════════════════════════════════

class CheckActionState {
  final bool isLoading;
  final AttendanceRecord? record;
  final UiError? error;

  const CheckActionState({
    this.isLoading = false,
    this.record,
    this.error,
  });
}

class CheckActionNotifier extends StateNotifier<CheckActionState> {
  final Ref _ref;
  CheckActionNotifier(this._ref) : super(const CheckActionState());

  Future<void> checkIn({double? lat, double? lng, String? notes}) async {
    if (state.isLoading) return;
    state = const CheckActionState(isLoading: true);
    try {
      final repo = _ref.read(attendanceRepositoryProvider);
      final record = await repo.checkIn(
        latitude: lat,
        longitude: lng,
        notes: notes,
      );
      state = CheckActionState(record: record);
      // Refresh history.
      _ref.read(attendanceHistoryProvider.notifier).refresh();
    } catch (e) {
      state = CheckActionState(error: GlobalErrorHandler.handle(e));
    }
  }

  Future<void> checkOut({double? lat, double? lng, String? notes}) async {
    if (state.isLoading) return;
    state = const CheckActionState(isLoading: true);
    try {
      final repo = _ref.read(attendanceRepositoryProvider);
      final record = await repo.checkOut(
        latitude: lat,
        longitude: lng,
        notes: notes,
      );
      state = CheckActionState(record: record);
      _ref.read(attendanceHistoryProvider.notifier).refresh();
    } catch (e) {
      state = CheckActionState(error: GlobalErrorHandler.handle(e));
    }
  }

  void clearError() => state = const CheckActionState();
}

final checkActionProvider =
    StateNotifierProvider<CheckActionNotifier, CheckActionState>(
  (ref) => CheckActionNotifier(ref),
);

// ═══════════════════════════════════════════════════════════════════
// Paginated Attendance History
// ═══════════════════════════════════════════════════════════════════

class AttendanceHistoryController
    extends PaginatedController<AttendanceRecord> {
  final Ref _ref;
  String? _month;
  AttendanceSummary? _summary;

  AttendanceSummary? get summary => _summary;

  AttendanceHistoryController(this._ref) : super(_ref);

  void setMonth(String? month) {
    _month = month;
    loadInitial();
  }

  @override
  Future<PaginatedResult<AttendanceRecord>> fetchPage(int page) async {
    final repo = _ref.read(attendanceRepositoryProvider);
    final data = await repo.getHistory(
      month: _month,
      page: page,
      perPage: 31,
    );
    _summary = data.summary;
    return PaginatedResult(
      items: data.records,
      pagination: data.pagination,
    );
  }
}

final attendanceHistoryProvider = StateNotifierProvider<
    AttendanceHistoryController, PaginatedState<AttendanceRecord>>(
  (ref) {
    final controller = AttendanceHistoryController(ref);
    controller.loadInitial();
    return controller;
  },
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/network/pagination.dart';
import '../controllers/global_error_handler.dart';

/// State for a paginated list of items.
///
/// Used by attendance history, leaves, payroll, and requests.
class PaginatedState<T> {
  final List<T> items;
  final Pagination? pagination;
  final bool isLoading;
  final bool isLoadingMore;
  final UiError? error;

  const PaginatedState({
    this.items = const [],
    this.pagination,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasData => items.isNotEmpty;
  bool get hasMore => pagination?.hasNextPage ?? false;
  bool get isEmpty => !isLoading && items.isEmpty && error == null;
  int get currentPage => pagination?.currentPage ?? 1;
  int get total => pagination?.total ?? 0;

  PaginatedState<T> copyWith({
    List<T>? items,
    Pagination? pagination,
    bool? isLoading,
    bool? isLoadingMore,
    UiError? error,
    bool clearError = false,
  }) {
    return PaginatedState(
      items: items ?? this.items,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Result from a paginated fetch — the controller needs items + pagination.
class PaginatedResult<T> {
  final List<T> items;
  final Pagination pagination;

  const PaginatedResult({required this.items, required this.pagination});
}

/// Generic paginated list controller.
///
/// Subclass this for each feature and implement [fetchPage].
///
/// Example:
/// ```dart
/// class AttendanceListController extends PaginatedController<AttendanceRecord> {
///   final AttendanceRepository _repo;
///   AttendanceListController(this._repo);
///
///   @override
///   Future<PaginatedResult<AttendanceRecord>> fetchPage(int page) async {
///     final data = await _repo.getHistory(perPage: 31);
///     return PaginatedResult(items: data.records, pagination: data.pagination);
///   }
/// }
/// ```
abstract class PaginatedController<T>
    extends StateNotifier<PaginatedState<T>> {
  PaginatedController(Ref ref) : super(const PaginatedState());

  /// Implement this: fetch items for the given [page].
  Future<PaginatedResult<T>> fetchPage(int page);

  /// Load the first page (or refresh).
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await fetchPage(1);
      state = PaginatedState(
        items: result.items,
        pagination: result.pagination,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: GlobalErrorHandler.handle(e),
      );
    }
  }

  /// Load next page and append items.
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await fetchPage(nextPage);
      state = PaginatedState(
        items: [...state.items, ...result.items],
        pagination: result.pagination,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: GlobalErrorHandler.handle(e),
      );
    }
  }

  /// Pull-to-refresh: reload from page 1.
  Future<void> refresh() => loadInitial();
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:hr_portal/core/services/notifications_bus.dart';

import '../../../../core/services/db/db_helper.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (_) => NotificationsRepositoryImpl(DbHelper()),
);

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
      final repo = ref.read(notificationsRepositoryProvider);
      return NotificationsNotifier(repo);
    });

final notificationsUnreadCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).unreadCount,
);

class NotificationsState {
  final List<NotificationModel> all;
  final List<NotificationModel> visible;

  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;

  final int unreadCount;

  final String searchText;
  final bool isSearchMode;

  const NotificationsState({
    this.all = const [],
    this.visible = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.unreadCount = 0,
    this.searchText = '',
    this.isSearchMode = false,
  });

  NotificationsState copyWith({
    List<NotificationModel>? all,
    List<NotificationModel>? visible,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? unreadCount,
    String? searchText,
    bool? isSearchMode,
  }) {
    return NotificationsState(
      all: all ?? this.all,
      visible: visible ?? this.visible,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      unreadCount: unreadCount ?? this.unreadCount,
      searchText: searchText ?? this.searchText,
      isSearchMode: isSearchMode ?? this.isSearchMode,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repo;

  Timer? _debounce;
  final Duration _debounceDuration;

  final int pageSize;
  int _offset = 0;

  late final StreamSubscription<void> _busSub;

  NotificationsNotifier(
    this._repo, {
    this.pageSize = 30,
    Duration debounceDuration = const Duration(milliseconds: 350),
  }) : _debounceDuration = debounceDuration,
       super(const NotificationsState()) {
    _busSub = NotificationsBus.stream.listen((_) {
      // ✅ تجنّب إعادة التحميل أثناء تحميل قائم (يقلل flicker)
      if (state.isLoading || state.isLoadingMore) return;
      unawaited(fetchFirstPage());
    });

    // Lazy-load initial page.
    unawaited(fetchFirstPage());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busSub.cancel();
    super.dispose();
  }

  // -------------------- Search UI state --------------------

  void openSearch() {
    if (state.isSearchMode) return;
    state = state.copyWith(isSearchMode: true);
  }

  void closeSearch() {
    if (!state.isSearchMode) return;
    state = state.copyWith(isSearchMode: false);
    clearSearch();
  }

  void clearSearch() {
    _debounce?.cancel();
    _applySearchNow('');
  }

  void onSearchChanged(String value) {
    state = state.copyWith(searchText: value);

    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      _applySearchNow(state.searchText);
    });
  }

  void _applySearchNow(String query) {
    final q = query.trim().toLowerCase();

    final visible = q.isEmpty
        ? state.all
        : state.all.where((n) {
            final tAr = n.titleAr.toLowerCase();
            final tEn = n.titleEn.toLowerCase();
            final bAr = n.bodyAr.toLowerCase();
            final bEn = n.bodyEn.toLowerCase();
            return tAr.contains(q) ||
                tEn.contains(q) ||
                bAr.contains(q) ||
                bEn.contains(q);
          }).toList();

    state = state.copyWith(searchText: query, visible: visible);
  }

  // -------------------- Fetch from DB --------------------

  Future<void> fetchFirstPage() async {
    _offset = 0;

    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
    );

    try {
      final items = await _repo.fetchPage(limit: pageSize, offset: _offset);

      _offset += items.length;
      final hasMore = items.length == pageSize;

      final unreadCount = await _repo.countUnread();

      final next = state.copyWith(
        all: items,
        hasMore: hasMore,
        unreadCount: unreadCount,
        isLoading: false,
      );

      state = next;
      _applySearchNow(next.searchText);
    } catch (_) {
      // Keep UI usable even if DB fails.
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    await fetchFirstPage();
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final items = await _repo.fetchPage(limit: pageSize, offset: _offset);

      _offset += items.length;
      final hasMore = items.length == pageSize;

      final unreadCount = await _repo.countUnread();

      final all = [...state.all, ...items];

      final next = state.copyWith(
        all: all,
        hasMore: hasMore,
        unreadCount: unreadCount,
        isLoadingMore: false,
      );

      state = next;
      _applySearchNow(next.searchText);
    } finally {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  // -------------------- Actions --------------------

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);

    final all = state.all
        .map((n) => n.id == id ? _copyWithRead(n, true) : n)
        .toList();
    final visible = state.visible
        .map((n) => n.id == id ? _copyWithRead(n, true) : n)
        .toList();

    final unreadCount = await _repo.countUnread();

    state = state.copyWith(
      all: all,
      visible: visible,
      unreadCount: unreadCount,
    );
  }

  Future<void> deleteById(String id) async {
    await _repo.deleteById(id);

    final all = [...state.all]..removeWhere((n) => n.id == id);
    final visible = [...state.visible]..removeWhere((n) => n.id == id);

    final unreadCount = await _repo.countUnread();

    state = state.copyWith(
      all: all,
      visible: visible,
      unreadCount: unreadCount,
    );
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    state = const NotificationsState(hasMore: false);
  }

  NotificationModel _copyWithRead(NotificationModel n, bool read) {
    return NotificationModel(
      id: n.id,
      titleAr: n.titleAr,
      bodyAr: n.bodyAr,
      titleEn: n.titleEn,
      bodyEn: n.bodyEn,
      img: n.img,
      url: n.url,
      route: n.route,
      payload: n.payload,
      isRead: read,
      createdAt: n.createdAt,
    );
  }
}

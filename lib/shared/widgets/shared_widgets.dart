import 'package:flutter/material.dart';

import '../controllers/global_error_handler.dart';
import '../controllers/paginated_controller.dart';

// ═══════════════════════════════════════════════════════════════════
// Loading
// ═══════════════════════════════════════════════════════════════════

class LoadingIndicator extends StatelessWidget {
  final String? message;
  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Error Full Screen
// ═══════════════════════════════════════════════════════════════════

class ErrorFullScreen extends StatelessWidget {
  final UiError error;
  final VoidCallback? onRetry;

  const ErrorFullScreen({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isOffline = error.action == ErrorAction.showFullScreen &&
        error.title == 'لا يوجد اتصال';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              error.title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (error.traceId != null) ...[
              const SizedBox(height: 4),
              Text(
                'Trace: ${error.traceId}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Empty State
// ═══════════════════════════════════════════════════════════════════

class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Paginated List Builder
// ═══════════════════════════════════════════════════════════════════

/// Generic widget that renders a paginated list with pull-to-refresh
/// and load-more-on-scroll.
///
/// Usage:
/// ```dart
/// PaginatedListView<AttendanceRecord>(
///   state: ref.watch(attendanceListProvider),
///   onRefresh: () => ref.read(attendanceListProvider.notifier).refresh(),
///   onLoadMore: () => ref.read(attendanceListProvider.notifier).loadMore(),
///   itemBuilder: (context, record) => AttendanceTile(record),
///   emptyIcon: Icons.event_available,
///   emptyTitle: 'لا توجد سجلات حضور',
/// )
/// ```
class PaginatedListView<T> extends StatefulWidget {
  final PaginatedState<T> state;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final IconData? emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;
  final Widget? header;

  const PaginatedListView({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.itemBuilder,
    this.emptyIcon,
    required this.emptyTitle,
    this.emptySubtitle,
    this.header,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;

    if (s.isLoading) {
      return const LoadingIndicator();
    }

    if (s.error != null && !s.hasData) {
      return ErrorFullScreen(
        error: s.error!,
        onRetry: () => widget.onRefresh(),
      );
    }

    if (s.isEmpty) {
      return EmptyState(
        icon: widget.emptyIcon,
        title: widget.emptyTitle,
        subtitle: widget.emptySubtitle,
      );
    }

    final itemCount =
        s.items.length + (widget.header != null ? 1 : 0) + (s.isLoadingMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // Header
          if (widget.header != null && index == 0) {
            return widget.header!;
          }

          final dataIndex = index - (widget.header != null ? 1 : 0);

          // Loading more indicator
          if (dataIndex >= s.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return widget.itemBuilder(context, s.items[dataIndex]);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Session Expired Dialog
// ═══════════════════════════════════════════════════════════════════

class SessionExpiredDialog extends StatelessWidget {
  const SessionExpiredDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SessionExpiredDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.lock_clock, size: 48),
      title: const Text('انتهت الجلسة'),
      content: const Text(
        'انتهت صلاحية جلستك. يرجى تسجيل الدخول مرة أخرى.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('تسجيل الدخول'),
        ),
      ],
    );
  }
}

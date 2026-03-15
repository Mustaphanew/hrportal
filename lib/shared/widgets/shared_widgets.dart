import 'package:flutter/material.dart';
import 'package:hr_portal/core/localization/app_localizations.dart';
import 'package:hr_portal/core/theme/app_spacing.dart';

import '../controllers/global_error_handler.dart';
import '../controllers/paginated_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
            AppSpacing.verticalMd,
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
    final isOffline =
        error.action == ErrorAction.showFullScreen &&
        error.title == 'No connection';

    return Center(
      child: Padding(
        padding: AppSpacing.paddingAllXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            AppSpacing.verticalMd,
            Text(
              error.title.tr(context),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSm,
            Text(
              error.message.tr(context),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (error.traceId != null) ...[
              AppSpacing.verticalXs,
              Text(
                'Trace: ${error.traceId}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onRetry != null) ...[
              AppSpacing.verticalLg,
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text('Retry'.tr(context)),
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

  const EmptyState({super.key, this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingAllXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            AppSpacing.verticalMd,
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              AppSpacing.verticalSm,
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        s.items.length +
        (widget.header != null ? 1 : 0) +
        (s.isLoadingMore ? 1 : 0);

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
              padding: AppSpacing.paddingAllMd,
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
      title: Text('Session expired'.tr(context)),
      content: Text('Your session has expired. Please sign in again.'.tr(context)),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Sign in'.tr(context)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Cached Network Image
// ═══════════════════════════════════════════════════════════════════

class CacheImg extends StatelessWidget {
  final String url;
  final BoxFit? boxFit;
  final double? imgWidth;
  final double sizeCircleLoading;
  const CacheImg({
    super.key,
    required this.url,
    this.boxFit,
    this.imgWidth,
    this.sizeCircleLoading = 40,
  });

  @override
  Widget build(BuildContext context) {
    String imageUrl = "";

    if (url.trim().isEmpty) {
      imageUrl = "";
    } else if (url.startsWith("http")) {
      imageUrl = url;
    } else {
      imageUrl = "https://$url";
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: boxFit,
      width: imgWidth,
      placeholder: (context, url) {
        return Container(
          padding: EdgeInsets.all(4),
          // height: sizeCircleLoading + 10.0,
          // width: sizeCircleLoading + 10.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: sizeCircleLoading,
                width: sizeCircleLoading,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        );
      },
      errorWidget: (context, url, error) {
        return Icon(
          Icons.error_outline,
          size: sizeCircleLoading,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
      },
    );
  }
}

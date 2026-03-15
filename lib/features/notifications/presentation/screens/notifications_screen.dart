import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/core/localization/app_localizations.dart';
import 'package:hr_portal/core/theme/app_spacing.dart';
import 'package:hr_portal/core/utils/app_funs.dart';
import 'package:hr_portal/shared/widgets/shared_widgets.dart';
import '../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late final TextEditingController _searchCtrl;
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _scrollCtrl = ScrollController()..addListener(_onScroll);

    // ✅ كل مرة تُفتح فيها الشاشة (Widget جديد) سيتم جلب أحدث بيانات من DB
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;

    const threshold = 220.0;
    final pos = _scrollCtrl.position;

    if (pos.pixels >= pos.maxScrollExtent - threshold) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete all notifications'.tr(context)),
        content: Text("Are you sure? This action can't be undone.".tr(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'.tr(context)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete'.tr(context)),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      await ref.read(notificationsProvider.notifier).clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return PopScope(
      canPop: !state.isSearchMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _searchCtrl.clear();
          notifier.closeSearch();
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        appBar: state.isSearchMode
            ? _SearchAppBar(
                controller: _searchCtrl,
                onBack: () {
                  _searchCtrl.clear();
                  notifier.closeSearch();
                  FocusScope.of(context).unfocus();
                },
                onClear: () {
                  _searchCtrl.clear();
                  notifier.clearSearch();
                },
                onChanged: notifier.onSearchChanged,
              )
            : _NormalAppBar(
                unreadCount: state.unreadCount,
                onSearch: () {
                  _searchCtrl.text = state.searchText;
                  _searchCtrl.selection = TextSelection.collapsed(offset: _searchCtrl.text.length);
                  notifier.openSearch();
                },
                onRefresh: notifier.refresh,
                onClearAll: () => _confirmClearAll(context),
              ),
        body: _buildBody(context, state, notifier),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationsState state, NotificationsNotifier notifier) {
    Future<void> onPullRefresh() async {
      await notifier.refresh();
    }

    // Initial loading
    if (state.isLoading && state.visible.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Empty (still scrollable so RefreshIndicator works)
    if (state.visible.isEmpty) {
      final isSearch = state.searchText.trim().isNotEmpty;
      return RefreshIndicator(
        onRefresh: onPullRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: _EmptyNotificationsView(
                title: isSearch
                    ? 'No results'.tr(context)
                    : 'No notifications'.tr(context),
                subtitle: isSearch
                    ? 'Try different keywords'.tr(context)
                    : 'Notifications will appear here when they arrive.'.tr(
                        context,
                      ),
              ),
            ),
          ],
        ),
      );
    }

    final itemCount = state.visible.length + (state.isLoadingMore ? 1 : 0);
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();

    return RefreshIndicator(
      onRefresh: onPullRefresh,
      child: ListView.separated(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 0, bottom: 8),
        itemCount: itemCount,
        separatorBuilder: (_, __) => Divider(thickness: 0.5, color: Theme.of(context).dividerColor, height: 0.5),
        itemBuilder: (context, index) {
          if (state.isLoadingMore && index == state.visible.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(child: SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))),
            );
          }

          final n = state.visible[index];
          final titleText = n.titleByLang(lang);
          final bodyText = n.bodyByLang(lang);
          final dateText = AppFuns.formatDateTime(n.createdAtDate);

          final route = (n.route ?? '').trim();
          final url = (n.url ?? '').trim();
          final showActionIcon = route.isNotEmpty || url.isNotEmpty;

          Future<void> onTap() async {
            if (!n.isRead) {
              await notifier.markAsRead(n.id);
            }

            if (route.isNotEmpty) {
              final path = route.startsWith('/') ? route : '/$route';
              if (context.mounted) {
                context.push(path, extra: n.payload ?? const {});
              }
              return;
            }

            if (url.isNotEmpty && url.startsWith('http')) {
              await AppFuns.openUrl(url);
            }
          }

          return Slidable(
            key: ValueKey(n.id),

            // سحب من اليمين لليسار
            endActionPane: ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.25,

              // ✅ سحب للنهاية = محاولة حذف + تأكيد قبل الإخفاء
              dismissible: DismissiblePane(
                motion: const BehindMotion(),
                closeOnCancel: true, // ✅ لو ضغط "إلغاء" يرجع العنصر مكانه بدون اختفاء/خطأ
                confirmDismiss: () async {
                  final ok =
                      await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: Text('Delete notification'.tr(context)),
                          content: Text(
                            'Do you want to delete this notification?'.tr(
                              context,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, false),
                              child: Text('Cancel'.tr(context)),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: Text('Delete'.tr(context)),
                            ),
                          ],
                        ),
                      ) ??
                      false;

                  return ok; // ✅ true يكمل الحذف، false يلغي السحب ويرجع
                },
                onDismissed: () {
                  // ✅ هنا الحذف فقط (بدون Dialog)
                  notifier.deleteById(n.id);
                },
              ),

              // ✅ زر حذف ثابت (الأيقونة لا تتحرك أثناء السحب)
              children: [
                CustomSlidableAction(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                  autoClose: false,
                  onPressed: (ctx) async {
                    final ok =
                        await showDialog<bool>(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            title: Text('Delete notification'.tr(context)),
                            content: Text(
                              'Do you want to delete this notification?'.tr(
                                context,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx, false),
                                child: Text('Cancel'.tr(context)),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(dCtx, true),
                                child: Text('Delete'.tr(context)),
                              ),
                            ],
                          ),
                        ) ??
                        false;

                    if (!ok) {
                      // ✅ رجّع السلايد لو مفتوح
                      if (ctx.mounted) Slidable.of(ctx)?.close();
                      return;
                    }

                    if (ctx.mounted) Slidable.of(ctx)?.close();
                    notifier.deleteById(n.id);
                  },

                  child: Align(
                    alignment: AlignmentDirectional.centerEnd, // ✅ تثبيت يمين
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 24),
                      child: Icon(Icons.delete_outline, size: 24, color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ),
                ),
              ],
            ),

            child: _NotificationTile(
              titleText: titleText,
              bodyText: bodyText,
              dateText: dateText,
              img: n.img,
              isRead: n.isRead,
              showActionIcon: showActionIcon,
              onActionTap: showActionIcon ? onTap : null,
              onTap: onTap,
            ),
          );
        },
      ),
    );
  }
}

/// AppBar العادي (عنوان + تحديث + بحث + حذف الكل)
class _NormalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _NormalAppBar({required this.onRefresh, required this.onSearch, required this.onClearAll, required this.unreadCount});

  final VoidCallback onRefresh;
  final VoidCallback onSearch;
  final VoidCallback onClearAll;
  final int unreadCount;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppBar(
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Text('Notifications'.tr(context)),
          AppSpacing.horizontalSm,
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(999)),
              child: Text(
                unreadCount.toString(),
                style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Search'.tr(context),
          onPressed: onSearch,
          icon: const Icon(Icons.search_rounded),
        ),
        _RefreshChip(onTap: onRefresh),
        IconButton(
          tooltip: 'Delete all'.tr(context),
          onPressed: onClearAll,
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
        AppSpacing.horizontalSm,
      ],
    );
  }
}

/// زر تحديث بشكل كبسولة
class _RefreshChip extends StatelessWidget {
  const _RefreshChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8, end: 4),
      child: Material(
        borderRadius: radius,
        color: cs.surfaceContainerHighest,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Refresh'.tr(context)),
                const SizedBox(width: 8),
                const Icon(Icons.refresh_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// AppBar البحث (Back داخل الشريط + TextField + X Clear)
class _SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SearchAppBar({required this.controller, required this.onBack, required this.onClear, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onBack;
  final VoidCallback onClear;
  final ValueChanged<String> onChanged;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
        child: TextField(
          controller: controller,
          autofocus: true,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: IconButton(
              tooltip: 'Back'.tr(context),
              onPressed: onBack,
              icon: const BackButtonIcon(),
            ),
            suffixIcon: IconButton(
              tooltip: 'Clear'.tr(context),
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            ),
            hintText: 'Search'.tr(context),
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
    );
  }
}

/// عنصر إشعار واحد
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.titleText,
    required this.bodyText,
    required this.dateText,
    required this.img,
    required this.isRead,
    required this.showActionIcon,
    this.onActionTap,
    this.onTap,
  });

  final String titleText;
  final String bodyText;
  final String dateText;
  final String? img;
  final bool isRead;
  final bool showActionIcon;
  final VoidCallback? onActionTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: isRead ? FontWeight.w600 : FontWeight.w800);

    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final dateStyle = Theme.of(context).textTheme.bodySmall;

    return Material(
      color: isRead ? cs.secondary.withValues(alpha: 0.1) : cs.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (img != null && img!.trim().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CacheImg(url: img ?? '', imgWidth: 80, boxFit: BoxFit.fill, sizeCircleLoading: 30),
                )
              else
                _CircleTypeIcon(isRead: isRead),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(titleText, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                          ),
                        ],
                      ],
                    ),
                    AppSpacing.verticalSm,
                    Text(bodyText, style: bodyStyle, maxLines: 3, overflow: TextOverflow.ellipsis),
                    AppSpacing.verticalSm,
                    Text(dateText, style: dateStyle),
                  ],
                ),
              ),
              AppSpacing.horizontalMd,
              if (showActionIcon)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 44),
                  child: IconButton(
                    onPressed: onActionTap,
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'Open'.tr(context),
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleTypeIcon extends StatelessWidget {
  const _CircleTypeIcon({required this.isRead});
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: const AlwaysStoppedAnimation(0.1),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.notifications_none_rounded,
          color: isRead ? Theme.of(context).iconTheme.color : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// شاشة “لا يوجد إشعارات”
class _EmptyNotificationsView extends StatelessWidget {
  const _EmptyNotificationsView({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingHorizontalLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded, size: 56, color: Theme.of(context).iconTheme.color),
            AppSpacing.verticalMd,
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSm,
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

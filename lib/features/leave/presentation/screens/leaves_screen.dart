import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/core/localization/app_localizations.dart';
import 'package:hr_portal/core/theme/app_spacing.dart';
import 'package:hr_portal/shared/widgets/app_components.dart';

import '../../../../shared/widgets/shared_widgets.dart';
import '../providers/leave_providers.dart';

class LeavesScreen extends ConsumerWidget {
  const LeavesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leavesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Leaves'.tr(context)),
        actions: [
          IconButton(
            onPressed: () => context.go('/leaves/create'),
            icon: const Icon(Icons.add),
            tooltip: 'Request leave'.tr(context),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: LoadingIndicator())
          : state.error != null
          ? ErrorFullScreen(
              error: state.error!,
              onRetry: () => ref.read(leavesListProvider.notifier).refresh(),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(leavesListProvider.notifier).refresh(),
              child: ListView(
                padding: AppSpacing.paddingAllMd,
                children: [
                  SectionHeader(title: 'Balance'.tr(context)),
                  if (state.balances.isEmpty)
                    EmptyState(
                      icon: Icons.emoji_events,
                      title: 'No available balance'.tr(context),
                    )
                  else
                    ...state.balances.map(
                      (b) => Card(
                        child: ListTile(
                          title: Text(b.leaveType?.name ?? ''),
                          subtitle: Text(
                            '${'Code'.tr(context)}: ${b.leaveType?.code ?? ''}',
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${'Available'.tr(context)}: ${b.available.toStringAsFixed(1)}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                '${'Used'.tr(context)}: ${b.used.toStringAsFixed(1)}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  AppSpacing.verticalMd,
                  SectionHeader(title: 'Requests'.tr(context)),
                  if (state.requests.isEmpty)
                    EmptyState(
                      icon: Icons.emoji_events,
                      title: 'No leave requests'.tr(context),
                    )
                  else
                    ...state.requests.map(
                      (r) => Card(
                        child: ListTile(
                          title: Text(
                            '${r.leaveType?.name} • ${r.status}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${r.startDate} → ${r.endDate}'
                            ' (${r.totalDays.toStringAsFixed(1)} ${'day'.tr(context)})',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Future: navigate to detail screen.
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

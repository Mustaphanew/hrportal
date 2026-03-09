import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/core/localization/app_localizations.dart';

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
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Balance'.tr(context),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                              ),
                              Text(
                                '${'Used'.tr(context)}: ${b.used.toStringAsFixed(1)}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                  Text(
                    'Requests'.tr(context),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (state.requests.isEmpty)
                    EmptyState(
                      icon: Icons.emoji_events,
                      title: 'No leave requests'.tr(context),
                    )
                  else
                    ...state.requests.map(
                      (r) => Card(
                        child: ListTile(
                          title: Text('${r.leaveType?.name} • ${r.status}'),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/shared_widgets.dart';
import '../providers/leave_providers.dart';

class LeavesScreen extends ConsumerWidget {
  const LeavesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leavesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإجازات'),
        actions: [
          IconButton(
            onPressed: () => context.go('/leaves/create'),
            icon: const Icon(Icons.add),
            tooltip: 'طلب إجازة',
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
                        'الرصيد',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (state.balances.isEmpty)
                        const EmptyState(icon: Icons.emoji_events, title: 'لا يوجد رصيد متاح',)
                      else
                        ...state.balances.map(
                          (b) => Card(
                            child: ListTile(
                              title: Text(b.leaveType?.name ?? ''),
                              subtitle: Text('الكود: ${b.leaveType?.code}'),
                              trailing: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('متاح: ${b.available.toStringAsFixed(1)}'),
                                  Text('مستخدم: ${b.used.toStringAsFixed(1)}'),
                                ],
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),
                      Text(
                        'الطلبات',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (state.requests.isEmpty)
                        const EmptyState(icon: Icons.emoji_events, title: 'لا توجد طلبات إجازة')
                      else
                        ...state.requests.map(
                          (r) => Card(
                            child: ListTile(
                              title: Text(
                                '${r.leaveType?.name} • ${r.status}',
                              ),
                              subtitle: Text(
                                '${r.startDate} → ${r.endDate}'
                                ' (${r.totalDays.toStringAsFixed(1)} يوم)',
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

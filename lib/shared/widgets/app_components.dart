import 'package:flutter/material.dart';
import 'package:hr_portal/core/theme/app_spacing.dart';

// ── SectionHeader ─────────────────────────────────────────────────────────────

/// A section title row with an optional trailing action widget.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (trailing != null) ...[
            AppSpacing.horizontalSm,
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ── StatItem & StatCard ────────────────────────────────────────────────────────

/// A label/value pair used by [StatCard].
class StatItem {
  const StatItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

/// Displays a list of [StatItem]s inside a [Card].
///
/// On wide screens the items are arranged in a [Row] with [MainAxisAlignment.spaceAround].
/// On narrow screens (below [AppBreakpoints.mobile]) a [Wrap] is used so items
/// flow naturally without overflowing.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.items,
  });

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    Widget buildStatCell(StatItem item) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.value,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            AppSpacing.verticalXs,
            Text(
              item.label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      );
    }

    Widget content;
    if (isMobile) {
      content = Wrap(
        alignment: WrapAlignment.spaceAround,
        runSpacing: AppSpacing.sm,
        children: items.map(buildStatCell).toList(),
      );
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map(buildStatCell).toList(),
      );
    }

    return Card(
      child: Padding(
        padding: AppSpacing.paddingAllMd,
        child: content,
      ),
    );
  }
}

// ── StatusChip ────────────────────────────────────────────────────────────────

/// A small colored [Chip] used to display a status label.
///
/// The [color] is used for the border; the background is the same color at
/// 10 % opacity so the chip remains legible on any surface.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Chip(
      label: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: color,
          overflow: TextOverflow.ellipsis,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ── ResponsiveCenter ──────────────────────────────────────────────────────────

/// Constrains [child] to [maxWidth] and centers it horizontally.
///
/// An optional [padding] is applied around the constrained child.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.tablet,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );

    if (padding != null) {
      content = Padding(
        padding: padding!,
        child: content,
      );
    }

    return Center(child: content);
  }
}

// ── AppLoadingButton ──────────────────────────────────────────────────────────

/// A [FilledButton] that replaces its label with a [CircularProgressIndicator]
/// while [isLoading] is `true`.
///
/// The button is also disabled when [enabled] is `false` or when [isLoading]
/// is `true`.
class AppLoadingButton extends StatelessWidget {
  const AppLoadingButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isInteractive = enabled && !isLoading;

    return FilledButton(
      onPressed: isInteractive ? onPressed : null,
      child: isLoading
          ? SizedBox(
              width: AppSpacing.md,
              height: AppSpacing.md,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            )
          : Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
    );
  }
}

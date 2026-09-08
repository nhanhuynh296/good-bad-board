import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';

/// A single recurring session entry displayed on the Schedule tab.
class _ScheduleItem {
  final String day;
  final String timeWindow;
  final String note;

  const _ScheduleItem({
    required this.day,
    required this.timeWindow,
    required this.note,
  });
}

/// The Schedule tab — read-only list of recurring sessions.
///
/// Implements SCHED-01 from the UAT spec.
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  /// Hardcoded recurring sessions for this build.
  static const List<_ScheduleItem> _items = [
    _ScheduleItem(
      day: 'Monday',
      timeWindow: '6:00 PM - 8:00 PM',
      note: 'Open play — all levels welcome',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.desktopPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Title ──────────────────────────────
          const Text('Recurring sessions', style: AppTypography.cardTitle),

          const SizedBox(height: AppSpacing.lg),

          // ── Session Cards or Empty State ─────────────
          if (_items.isNotEmpty)
            ..._items.map((item) => _SessionCard(item: item))
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: _EmptyState(),
            ),

          const SizedBox(height: AppSpacing.lg),

          // ── Footer ─────────────────────────────────────
          Text(
            'Public calendar view and reminder scheduling live under Settings.',
            style: AppTypography.body.copyWith(color: AppColors.textSubtle),
          ),
        ],
      ),
    );
  }
}

/// A card representing a single recurring session.
class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.item});

  final _ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.day,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.timeWindow,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: AppRadii.fullRadius,
                  ),
                  child: Text(
                    'Auto check-in opens 30 min prior',
                    style: AppTypography.buttonSm.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.note,
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state message.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No recurring sessions',
        style: AppTypography.body.copyWith(
          fontStyle: FontStyle.italic,
          color: AppColors.textSubtle,
        ),
      ),
    );
  }
}

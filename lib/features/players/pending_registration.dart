import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/courts/courts_button.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/l10n/skill_tier_l10n.dart';
import 'package:good_bad_board/model/pending_registration.dart';

/// Card shown at the top of the Players page when there are pending
/// self-registrations waiting for organiser approval.
///
/// Each pending entry shows: name + estimated level + contact info, plus
/// [Approve] (success green) and [Reject] (muted outline) action buttons.
class PendingRegistrationCard extends StatelessWidget {
  const PendingRegistrationCard({
    super.key,
    required this.pendingRegistrations,
    this.processingIds = const {},
    this.onApprove,
    this.onReject,
    this.desktop = false,
  });

  /// The desktop look (R2-Q19): one 44 px line per registration in a card
  /// with a 1 px `#8f826e` border, and outline Reject / Approve buttons.
  /// Phone and tablet keep the PR 45 card (R6-Q7).
  final bool desktop;

  /// The list of pending registrations to display.
  final List<PendingRegistration> pendingRegistrations;

  /// Ids of registrations currently being approved/rejected — their action
  /// pills render disabled while in flight.
  final Set<String> processingIds;

  /// Called with the index of the approved registration.
  final void Function(int index)? onApprove;

  /// Called with the index of the rejected registration.
  final void Function(int index)? onReject;

  @override
  Widget build(BuildContext context) {
    final count = pendingRegistrations.length;
    if (desktop) return _buildDesktop(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Title ──────────────────────────────────────
          Text(
            AppLocalizations.of(
              context,
            )!.players_pending_registrations_title(count),
            style: const TextStyle(
              fontFamily: AppTypography.family,
              fontSize: AppTypography.sizeCaption,
              fontWeight: AppTypography.semibold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Registrations ──────────────────────────────
          ...pendingRegistrations.asMap().entries.map((entry) {
            final index = entry.key;
            final reg = entry.value;
            final isProcessing = processingIds.contains(reg.id);
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < count - 1 ? AppSpacing.sm : 0,
              ),
              child: _PendingRow(
                registration: reg,
                onApprove: onApprove != null && !isProcessing
                    ? () => onApprove!(index)
                    : null,
                onReject: onReject != null && !isProcessing
                    ? () => onReject!(index)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}

extension on PendingRegistrationCard {
  Widget _buildDesktop(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count = pendingRegistrations.length;
    final title = Text(
      l10n.players_pending_registrations_title(count),
      style: AppTypography.md,
    );
    Widget line(int index) {
      final reg = pendingRegistrations[index];
      final busy = processingIds.contains(reg.id);
      return SizedBox(
        height: 44,
        child: Row(
          children: [
            if (index == 0) ...[title, const SizedBox(width: AppSpacing.md)],
            Expanded(
              child: Text(
                [
                  reg.name,
                  reg.tier.localizedLabel(l10n),
                  if (reg.contact.trim().isNotEmpty) reg.contact.trim(),
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _DesktopAction(
              label: l10n.players_reject,
              foreground: AppColors.textPrimary,
              border: AppColors.controlBorder,
              onTap: onReject != null && !busy ? () => onReject!(index) : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            _DesktopAction(
              label: l10n.players_approve,
              foreground: AppColors.successText,
              border: AppColors.success,
              onTap: onApprove != null && !busy
                  ? () => onApprove!(index)
                  : null,
            ),
          ],
        ),
      );
    }

    return Container(
      key: const Key('pending-registrations-card'),
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadii.lgRadius,
        border: Border.all(color: AppColors.controlBorderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 0; i < count; i++) line(i)],
      ),
    );
  }
}

/// A 32 px outline button of the desktop card, with a 40 px tall hit area
/// (F27).
class _DesktopAction extends StatelessWidget {
  const _DesktopAction({
    required this.label,
    required this.foreground,
    required this.border,
    this.onTap,
  });

  final String label;
  final Color foreground;
  final Color border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      // The margin above and below the button takes the tap too.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        excludeFromSemantics: true,
        child: SizedBox(
          height: 40,
          child: Center(
            child: CourtsButton(
              label: label,
              onPressed: onTap,
              height: 32,
              background: AppColors.pageBg,
              foreground: foreground,
              borderColor: border,
              ringColor: AppColors.focusOnLight,
              horizontalPadding: 12,
            ),
          ),
        ),
      ),
    );
  }
}

/// A single row within [PendingRegistrationCard].
class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.registration,
    this.onApprove,
    this.onReject,
  });

  final PendingRegistration registration;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: AppRadii.mdRadius,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // ── Info ────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(registration.name, style: AppTypography.md),
                const SizedBox(height: 2),
                Text(
                  '${registration.tier.localizedLabel(AppLocalizations.of(context)!)} '
                  '· ${registration.contact}',
                  style: AppTypography.sm,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // ── Reject ──────────────────────────────────────
          _ActionPill(
            label: AppLocalizations.of(context)!.players_reject,
            backgroundColor: AppColors.pillBg,
            textColor: AppColors.textMuted,
            onTap: onReject,
          ),
          const SizedBox(width: AppSpacing.sm),

          // ── Approve ─────────────────────────────────────
          _ActionPill(
            label: AppLocalizations.of(context)!.players_approve,
            backgroundColor: AppColors.success,
            textColor: AppColors.white,
            onTap: onApprove,
          ),
        ],
      ),
    );
  }
}

/// A small pill-shaped action button for Approve/Reject.
class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: backgroundColor,
        borderRadius: AppRadii.smRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.smRadius,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              label,
              style: AppTypography.buttonSm.copyWith(color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}

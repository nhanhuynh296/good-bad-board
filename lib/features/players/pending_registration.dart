import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
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
  });

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

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Title ──────────────────────────────────────
          Text(
            'Pending self-registrations ($count)',
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 12,
              fontWeight: FontWeight.w800,
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
                  '${registration.tier.label} · ${registration.contact}',
                  style: AppTypography.sm,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // ── Reject ──────────────────────────────────────
          _ActionPill(
            label: 'Reject',
            backgroundColor: AppColors.pillBg,
            textColor: AppColors.textMuted,
            onTap: onReject,
          ),
          const SizedBox(width: AppSpacing.sm),

          // ── Approve ─────────────────────────────────────
          _ActionPill(
            label: 'Approve',
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

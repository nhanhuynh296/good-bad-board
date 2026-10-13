import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/membership_l10n.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';

/// Summary statistics for a player's expandable profile card.
///
/// Callers compute these from persisted history (see
/// `computePlayerProfileStats`) and pass them in as a snapshot — the profile card itself is a pure presentational widget.
class PlayerProfileStats {
  const PlayerProfileStats({
    required this.matchCount,
    required this.diversityPercent,
    required this.levelHistory,
    required this.topPartners,
    required this.attendanceSummary,
  });

  /// Total number of games the player has participated in.
  final int matchCount;

  /// Distinct partners played with, as a whole percent of the other players
  /// on the roster (0–100).
  final int diversityPercent;

  /// Recent level trend ordered chronologically (oldest first). Each entry
  /// is the [Elo] value the player held at that point.
  final List<Elo> levelHistory;

  /// Up to 3 most frequent partners, sorted by count descending.
  final List<PartnerEntry> topPartners;

  /// Human-readable attendance summary, e.g. "Attended 12 of last 20 sessions".
  final String attendanceSummary;
}

/// A single partner name + game-count pair for the profile card.
class PartnerEntry {
  const PartnerEntry(this.name, this.count);
  final String name;
  final int count;
}

/// Expandable profile card displayed below a [PlayerRow].
///
/// Shows:
/// - Membership label + close button
/// - Stat trio: Current Level | Matches | Diversity
/// - Sign-in ID field with a Save button
/// - Most frequent partners list
/// - Attendance history text
///
/// Has no card chrome of its own: the Players page shows it inside the same
/// rounded panel as its [PlayerRow], so the row and the profile read as one
/// accordion item.
class PlayerProfileCard extends StatelessWidget {
  const PlayerProfileCard({
    super.key,
    required this.player,
    required this.stats,
    this.membership = MembershipStatus.member,
    this.onClose,
    this.onDelete,
    this.onSaveSignInId,
  });

  final Player player;
  final PlayerProfileStats stats;
  final MembershipStatus membership;
  final VoidCallback? onClose;

  /// Called when the delete ("remove from club") action is tapped.
  final VoidCallback? onDelete;

  /// Called with the typed text when the sign-in ID is saved. Returns an
  /// error message to show, or null when saved. Without it the profile shows
  /// no sign-in ID field.
  final String? Function(String text)? onSaveSignInId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row ──────────────────────────────────
          Row(
            children: [
              // Membership badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: switch (membership) {
                    MembershipStatus.member => AppColors.pillBg,
                    MembershipStatus.casual => AppColors.warningBg,
                    MembershipStatus.disabled => AppColors.toggleOff,
                  },
                  borderRadius: AppRadii.fullRadius,
                ),
                child: Text(
                  membership.localizedLabel(l10n),
                  style: AppTypography.chip.copyWith(
                    color: switch (membership) {
                      MembershipStatus.member => AppColors.success,
                      MembershipStatus.casual => AppColors.warningText,
                      MembershipStatus.disabled => AppColors.toggleOffText,
                    },
                  ),
                ),
              ),
              const Spacer(),
              // Delete button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: AppRadii.smRadius,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              // Close button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onClose,
                  borderRadius: AppRadii.smRadius,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Stat Trio ───────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatTrioCell(
                  label: l10n.players_current_level,
                  value: player.elo.toDisplayName(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTrioCell(
                  label: l10n.players_matches,
                  value: '${stats.matchCount}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTrioCell(
                  label: l10n.players_diversity,
                  value: '${stats.diversityPercent}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Sign-in ID (PLY-15) ─────────────────────────
          if (onSaveSignInId != null) ...[
            _SignInIdEditor(
              // A new key when the saved ID changes, so the field shows it.
              key: ValueKey('${player.id}:${player.signInId}'),
              initialValue: player.signInId ?? '',
              onSave: onSaveSignInId!,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Partners + Attendance ───────────────────────
          if (stats.topPartners.isNotEmpty) ...[
            _SectionLabel(l10n.players_most_frequent_partners),
            const SizedBox(height: AppSpacing.sm),
            ...stats.topPartners.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(p.name, style: AppTypography.body)),
                    Text('${p.count}', style: AppTypography.helperBold),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Attendance ───────────────────────────────────
          if (stats.attendanceSummary.isNotEmpty) ...[
            _SectionLabel(l10n.players_attendance),
            const SizedBox(height: AppSpacing.sm),
            Text(stats.attendanceSummary, style: AppTypography.body),
          ],
        ],
      ),
    );
  }
}

/// A label/value pair within the stat trio section of [PlayerProfileCard].
///
/// Value: 18–20px, 800. Label: 10px, 700, uppercase, muted.
class _StatTrioCell extends StatelessWidget {
  const _StatTrioCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: AppRadii.mdRadius,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.statLabel),
        ],
      ),
    );
  }
}

/// Text field and Save button for the sign-in ID of a player (PLY-15).
///
/// [onSave] gets the typed text and returns an error message to show under
/// the field, or null when the ID was saved.
class _SignInIdEditor extends StatefulWidget {
  const _SignInIdEditor({
    super.key,
    required this.initialValue,
    required this.onSave,
  });

  final String initialValue;
  final String? Function(String text) onSave;

  @override
  State<_SignInIdEditor> createState() => _SignInIdEditorState();
}

class _SignInIdEditorState extends State<_SignInIdEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => setState(() => _error = widget.onSave(_controller.text));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            key: const Key('player-sign-in-id-field'),
            controller: _controller,
            style: AppTypography.input,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: l10n.sign_in_id,
              errorText: _error,
              errorMaxLines: 2,
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: AppButton.secondary(
            key: const Key('player-sign-in-id-save'),
            label: l10n.save,
            onPressed: _save,
          ),
        ),
      ],
    );
  }
}

/// Small uppercase section label used within [PlayerProfileCard].
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(), style: AppTypography.statLabel);
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/persistent_setting.dart';

/// The Settings tab — language, membership summary, signup preview and
/// level calibration note.
///
/// Implements SET-02, SET-04 and SET-05 from the UAT spec.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.showSignupPreview = false});

  /// SET-03 is hidden for this release: the signup page has no way back on
  /// the desktop build. The /register route stays; tests turn this on.
  final bool showSignupPreview;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.desktopPadding,
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _LanguageCard(),
              const SizedBox(height: AppSpacing.lg),
              ListenableBuilder(
                listenable: PlayerRepository.instance.listenable,
                builder: (context, _) => _MembershipCard(
                  showSignupPreview: showSignupPreview,
                  totalMembers: PlayerRepository.instance
                      .listedPlayers()
                      .length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lets the user select the app language (SET-05). Each language shows
/// its own native name, so a user can find it in any current language.
class _LanguageCard extends StatelessWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context) {
    final setting = PersistentSetting.instance;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.language,
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          ListenableBuilder(
            listenable: setting,
            builder: (context, _) {
              final current = setting.getLanguage();
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final locale in AppLocalizations.supportedLocales)
                    AppChip(
                      label: lookupAppLocalizations(locale).language_name,
                      isSelected: locale == current,
                      compact: false,
                      onTap: () => setting.setLanguage(locale),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({
    required this.totalMembers,
    required this.showSignupPreview,
  });

  final int totalMembers;
  final bool showSignupPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settings_membership_title, style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.lg),

          // ── Membership count (SET-02) ───────────────
          Text(l10n.settings_total_members, style: AppTypography.statLabel),
          const SizedBox(height: AppSpacing.xs),
          Text('$totalMembers', style: AppTypography.statValue),
          const SizedBox(height: AppSpacing.xl),

          if (showSignupPreview) ...[
            GestureDetector(
              onTap: () => context.push('/register'),
              child: Text(
                l10n.settings_preview_signup,
                style: AppTypography.body.copyWith(
                  color: AppColors.accentPrimary,
                  fontWeight: AppTypography.semibold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // ── Level calibration note (SET-04) ─────────
          Text(
            l10n.settings_level_calibration_note,
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

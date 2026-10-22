import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/state/persistent_setting.dart';

/// The Settings tab — the language (SET-05).
///
/// The "Membership & self-registration" card is removed (R13-Q2, Nathan
/// 2026-10-22): SET-02, SET-03 and SET-04 have no control here now. The
/// /register route stays.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.desktopPadding,
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_LanguageCard()],
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

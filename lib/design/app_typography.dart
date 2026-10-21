import 'package:flutter/material.dart';
import 'package:good_bad_board/design/app_colors.dart';

/// Design tokens for typography.
///
/// Reference: ARCHITECTURE.md Section 1.2.
///
/// One family: Source Sans 3 (bundled variable font, `wght` axis). Hierarchy
/// comes from 6 sizes and 3 weights, not from a second family (UX-25, R3-Q6).
abstract class AppTypography {
  /// The only bundled font family — Source Sans 3.
  static const String family = 'SourceSans3';

  // ── Sizes (R2-Q20) ─────────────────────────────────────

  /// `text.timer` — round bar time.
  static const double sizeTimer = 50;

  /// `text.display` — page titles, check-in count, KPI values.
  static const double sizeDisplay = 28;

  /// `text.title` — scan field text, result box name, session bar time.
  static const double sizeTitle = 20;

  /// `text.subtitle` — court titles, row names, panel titles, result text.
  static const double sizeSubtitle = 16;

  /// `text.body` — body and data, slot names, buttons, tabs.
  static const double sizeBody = 14;

  /// `text.caption` — secondary lines, caps labels, chips, tags.
  static const double sizeCaption = 12;

  /// The 6 sizes of the type scale, largest first.
  static const List<double> scale = [
    sizeTimer,
    sizeDisplay,
    sizeTitle,
    sizeSubtitle,
    sizeBody,
    sizeCaption,
  ];

  // ── Weights ────────────────────────────────────────────

  /// Body and data: levels, IDs, helper text, result text.
  static const FontWeight regular = FontWeight.w400;

  /// Names, buttons, titles, timers, counts, caps labels, tags, chips.
  static const FontWeight semibold = FontWeight.w600;

  /// Page titles only.
  static const FontWeight extraBold = FontWeight.w800;

  /// Letter spacing of caps labels, chips and tags (0.08em at 12px).
  static const double capsLetterSpacing = 0.08 * sizeCaption;

  /// Letter spacing of court titles (0.04em at 16px).
  static const double courtTitleLetterSpacing = 0.04 * sizeSubtitle;

  // ── Locale fallback (R3-Q6) ────────────────────────────

  /// The Windows system font for Chinese text. Source Sans 3 has no Chinese
  /// glyphs, and nothing is bundled for Chinese.
  static List<String> fallbackFor(Locale? locale) {
    if (locale == null || locale.languageCode != 'zh') return const [];
    return locale.countryCode == 'HK'
        ? const ['Microsoft JhengHei']
        : const ['Microsoft YaHei'];
  }

  // ── Scale styles (ARCHITECTURE.md §1.2) ────────────────

  /// `text.timer` — 50px, 600, tabular figures.
  static const TextStyle timer = TextStyle(
    fontFamily: family,
    fontSize: sizeTimer,
    fontWeight: semibold,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.headerText,
  );

  /// `text.display` page title — 28px, 800.
  static const TextStyle pageTitle = TextStyle(
    fontFamily: family,
    fontSize: sizeDisplay,
    fontWeight: extraBold,
    color: AppColors.textPrimary,
  );

  /// `text.display` number — 28px, 600.
  static const TextStyle display = TextStyle(
    fontFamily: family,
    fontSize: sizeDisplay,
    fontWeight: semibold,
    color: AppColors.textPrimary,
  );

  /// `text.title` — 20px, 600.
  static const TextStyle title = TextStyle(
    fontFamily: family,
    fontSize: sizeTitle,
    fontWeight: semibold,
    color: AppColors.textPrimary,
  );

  /// `text.subtitle` — 16px, 600.
  static const TextStyle subtitle = TextStyle(
    fontFamily: family,
    fontSize: sizeSubtitle,
    fontWeight: semibold,
    color: AppColors.textPrimary,
  );

  /// `text.body` — 14px, 400.
  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontSize: sizeBody,
    fontWeight: regular,
    color: AppColors.textPrimary,
  );

  /// `text.body` strong — 14px, 600. Player names, section titles.
  static const TextStyle md = TextStyle(
    fontFamily: family,
    fontSize: sizeBody,
    fontWeight: semibold,
    color: AppColors.textPrimary,
  );

  /// `text.caption` — 12px, 400, muted.
  static const TextStyle sm = TextStyle(
    fontFamily: family,
    fontSize: sizeCaption,
    fontWeight: regular,
    color: AppColors.textMuted,
  );

  /// `text.caption` strong — 12px, 600.
  static const TextStyle smBold = TextStyle(
    fontFamily: family,
    fontSize: sizeCaption,
    fontWeight: semibold,
    color: AppColors.textPrimary,
  );

  /// `text.caption` caps label — 12px, 600, letter-spacing 0.08em, muted.
  static const TextStyle statLabel = TextStyle(
    fontFamily: family,
    fontSize: sizeCaption,
    fontWeight: semibold,
    color: AppColors.textMuted,
    letterSpacing: capsLetterSpacing,
  );

  // ── Role styles (all on the scale) ─────────────────────

  /// Helper text, hints, table headers, chart labels — 12px, 400.
  static const TextStyle helper = TextStyle(
    fontFamily: family,
    fontSize: sizeCaption,
    fontWeight: regular,
    color: AppColors.textMuted,
  );

  /// Helper bold — 12px, 600.
  static const TextStyle helperBold = TextStyle(
    fontFamily: family,
    fontSize: sizeCaption,
    fontWeight: semibold,
    color: AppColors.textMuted,
  );

  /// Card / court titles — 16px, 600, letter-spacing 0.04em.
  static const TextStyle cardTitle = TextStyle(
    fontFamily: family,
    fontSize: sizeSubtitle,
    fontWeight: semibold,
    color: AppColors.textPrimary,
    letterSpacing: courtTitleLetterSpacing,
  );

  /// Tight card title variant — 14px, 600.
  static const TextStyle cardTitleTight = TextStyle(
    fontFamily: family,
    fontSize: sizeBody,
    fontWeight: semibold,
    color: AppColors.textPrimary,
  );

  /// Small stat values — 16px, 600.
  static const TextStyle statValueSm = TextStyle(
    fontFamily: family,
    fontSize: sizeSubtitle,
    fontWeight: semibold,
    color: AppColors.textPrimary,
  );

  /// Stat values — 20px, 600.
  static const TextStyle statValue = TextStyle(
    fontFamily: family,
    fontSize: sizeTitle,
    fontWeight: semibold,
    color: AppColors.textPrimary,
  );

  /// Large title — 20px, 600.
  static const TextStyle xl = TextStyle(
    fontFamily: family,
    fontSize: sizeTitle,
    fontWeight: semibold,
    color: AppColors.textPrimary,
  );

  /// KPI values (Analytics) — 28px, 600.
  static const TextStyle kpiValue = TextStyle(
    fontFamily: family,
    fontSize: sizeDisplay,
    fontWeight: semibold,
    color: AppColors.textPrimary,
  );

  /// Large KPI value — 28px, 600.
  static const TextStyle kpiValueLarge = TextStyle(
    fontFamily: family,
    fontSize: sizeDisplay,
    fontWeight: semibold,
    color: AppColors.textPrimary,
  );

  /// KPI card caps label — 12px, 600, letter-spacing 0.08em.
  static const TextStyle kpiLabel = TextStyle(
    fontFamily: family,
    fontSize: sizeCaption,
    fontWeight: semibold,
    color: AppColors.textMuted,
    letterSpacing: capsLetterSpacing,
  );

  /// Text input value and hint — 14px, 400.
  static const TextStyle input = TextStyle(
    fontFamily: family,
    fontSize: sizeBody,
    fontWeight: regular,
    color: AppColors.textPrimary,
  );

  /// KPI delta label — 12px, 600.
  static const TextStyle kpiDelta = TextStyle(
    fontFamily: family,
    fontSize: sizeCaption,
    fontWeight: semibold,
  );

  /// Chip text — 12px, 600.
  static const TextStyle chip = TextStyle(
    fontFamily: family,
    fontSize: sizeCaption,
    fontWeight: semibold,
    color: AppColors.textMuted,
  );

  /// Button text — 14px, 600 (ARCHITECTURE.md §2.6: all buttons 14/600).
  static const TextStyle button = TextStyle(
    fontFamily: family,
    fontSize: sizeBody,
    fontWeight: semibold,
  );

  /// Small toggle and chip-button text — 12px, 600.
  ///
  /// Kept at 12px until the Sessions and Players controls are redrawn to
  /// the §2.6 buttons (14/600); 14px overflows their current layouts.
  static const TextStyle buttonSm = TextStyle(
    fontFamily: family,
    fontSize: sizeCaption,
    fontWeight: semibold,
  );

  /// Tab button text — 14px, 600.
  static const TextStyle tab = TextStyle(
    fontFamily: family,
    fontSize: sizeBody,
    fontWeight: semibold,
  );

  /// Bottom tab label — 12px, 600.
  static const TextStyle bottomTabLabel = TextStyle(
    fontFamily: family,
    fontSize: sizeCaption,
    fontWeight: semibold,
  );

  /// Club name in header — 20px, 600, white.
  static const TextStyle clubName = TextStyle(
    fontFamily: family,
    fontSize: sizeTitle,
    fontWeight: semibold,
    color: AppColors.headerText,
  );

  /// Header subtitle — 12px, 400, headerSub colour.
  static const TextStyle headerSubtitle = TextStyle(
    fontFamily: family,
    fontSize: sizeCaption,
    fontWeight: regular,
    color: AppColors.headerSub,
  );

  /// Compact header club name — 16px, 600, white.
  static const TextStyle clubNameCompact = TextStyle(
    fontFamily: family,
    fontSize: sizeSubtitle,
    fontWeight: semibold,
    color: AppColors.headerText,
  );

  /// Compact header tab label — 12px, 400, headerSub colour.
  static const TextStyle headerTabLabel = TextStyle(
    fontFamily: family,
    fontSize: sizeCaption,
    fontWeight: regular,
    color: AppColors.headerSub,
  );
}

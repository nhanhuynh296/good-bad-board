import 'package:flutter/material.dart';
import 'package:good_bad_board/design/app_colors.dart';

/// Design tokens for typography.
///
/// Reference: ARCHITECTURE.md Section 1.2.
///
/// Display font: Space Grotesk (headings, KPI values, court labels)
/// Body font: OpenSans (body text, player names, buttons, labels)
abstract class AppTypography {
  /// Display font family — Space Grotesk
  static const String displayFont = 'SpaceGrotesk';

  /// Body font family — OpenSans
  static const String bodyFont = 'OpenSans';

  // ── Type Scale ──────────────────────────────────────────

  /// Stat strip labels, KPI labels — 10px, 700, uppercase, letter-spacing 0.05em
  static const TextStyle statLabel = TextStyle(
    fontFamily: bodyFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 0.05 * 10, // 0.05em at 10px
  );

  /// Helper text, hints, table headers, chart labels — 11px, 600
  static const TextStyle helper = TextStyle(
    fontFamily: bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );

  /// Helper bold — 11px, 700
  static const TextStyle helperBold = TextStyle(
    fontFamily: bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
  );

  /// Secondary info, tab buttons, chip text — 12px, 500
  static const TextStyle sm = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  /// Secondary info bold — 12px, 700
  static const TextStyle smBold = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Body text, list items, form labels — 13px, 500
  static const TextStyle body = TextStyle(
    fontFamily: bodyFont,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Player names, section titles — 14px, 600
  static const TextStyle md = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Card titles (Space Grotesk) — 15px, 700
  static const TextStyle cardTitle = TextStyle(
    fontFamily: displayFont,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Tight card title variant — 14px, 700
  static const TextStyle cardTitleTight = TextStyle(
    fontFamily: displayFont,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Stat values — 16px, 700
  static const TextStyle statValueSm = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Stat values, header titles — 19px, 800
  static const TextStyle statValue = TextStyle(
    fontFamily: bodyFont,
    fontSize: 19,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  /// Header title — 19px, 700
  static const TextStyle xl = TextStyle(
    fontFamily: displayFont,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// KPI values (dashboard), club name — 22px, 700
  static const TextStyle kpiValue = TextStyle(
    fontFamily: displayFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Page titles — 26px, 700
  static const TextStyle pageTitle = TextStyle(
    fontFamily: displayFont,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Large KPI value — 26px, 700
  static const TextStyle kpiValueLarge = TextStyle(
    fontFamily: displayFont,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// KPI card label — 10.5px, 800, uppercase
  static const TextStyle kpiLabel = TextStyle(
    fontFamily: bodyFont,
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    color: AppColors.textMuted,
    letterSpacing: 0.05 * 10,
  );

  /// Text input value and hint — 14px, 500
  static const TextStyle input = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // ── KPI delta ──────────────────────────────────────────

  /// KPI delta label — 11px, 700
  static const TextStyle kpiDelta = TextStyle(
    fontFamily: bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  // ── Chip / Pill ────────────────────────────────────────

  /// Chip text — 11px, 700
  static const TextStyle chip = TextStyle(
    fontFamily: bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
  );

  // ── Button ─────────────────────────────────────────────

  /// Primary button text — 12px, 700
  static const TextStyle button = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  /// Small button text — 11px, 700
  static const TextStyle buttonSm = TextStyle(
    fontFamily: bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  // ── Tab / Nav ──────────────────────────────────────────

  /// Tab button text — 12px
  static const TextStyle tab = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// Bottom tab label — 10px, 700
  static const TextStyle bottomTabLabel = TextStyle(
    fontFamily: bodyFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );

  // ── Header ─────────────────────────────────────────────

  /// Club name in header — 22px, Space Grotesk, 700, white
  static const TextStyle clubName = TextStyle(
    fontFamily: displayFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.headerText,
  );

  /// Header subtitle — 12px, headerSub color
  static const TextStyle headerSubtitle = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.headerSub,
  );

  /// Compact header club name — 16px, white
  static const TextStyle clubNameCompact = TextStyle(
    fontFamily: displayFont,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.headerText,
  );

  /// Compact header tab label — 11px, headerSub color
  static const TextStyle headerTabLabel = TextStyle(
    fontFamily: bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.headerSub,
  );
}

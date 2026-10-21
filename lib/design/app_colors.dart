import 'package:flutter/material.dart';

/// Design tokens for the Clubhouse color palette (light only).
///
/// Reference: ARCHITECTURE.md Section 1.1. Text needs 4.5:1; borders, icons,
/// focus rings and state fills need 3:1 (UX-22, R2-Q22). Card and row
/// separators may stay light. `test/design/contrast_test.dart` checks every
/// pair.
abstract class AppColors {
  // ── Surfaces ─────────────────────────────────────────────
  /// `color.page.bg` — page / scaffold background (#fffdfa)
  static const Color pageBg = Color(0xFFFFFDFA);

  /// `color.card.bg` — court card, waitlist panel, row not checked in,
  /// READY result box (#fbf6ee)
  static const Color cardBg = Color(0xFFFBF6EE);

  /// `color.card.border` — card and row **separator** only (#e4d8c4)
  static const Color cardBorder = Color(0xFFE4D8C4);

  /// `color.surface.hover` — slot hover, next-round strip fill (#f3eadb)
  static const Color surfaceHover = Color(0xFFF3EADB);

  /// `color.surface.next` — court card fill in edit mode (#fffaf2)
  static const Color surfaceNext = Color(0xFFFFFAF2);

  /// `color.header.bg` — top nav (#221d18)
  static const Color headerBg = Color(0xFF221D18);

  /// `color.bar.bg` — round bar, session bar (#2b241e)
  static const Color barBg = Color(0xFF2B241E);

  /// `color.bar.track` — round progress track, READY chip fill, separators
  /// on the dark surfaces (#4a4038)
  static const Color barTrack = Color(0xFF4A4038);

  // ── Text ─────────────────────────────────────────────────
  /// `color.text.primary` — all body text, names (#221d18)
  static const Color textPrimary = Color(0xFF221D18);

  /// `color.text.muted` — labels, levels, helper text, caps labels, and the
  /// name, ID and level of a Disabled player (F13) (#6f6352). Fails on the
  /// checked-in row: use [textMutedOnCheckedIn] there.
  static const Color textMuted = Color(0xFF6F6352);

  /// Muted text on the checked-in row fill [checkedInBg] (#5f5446)
  static const Color textMutedOnCheckedIn = Color(0xFF5F5446);

  /// `color.header.text` — text on the top nav and bars (#ffffff)
  static const Color headerText = Color(0xFFFFFFFF);

  /// `color.header.sub` — inactive tabs, round label, counts, paused timer
  /// on the bars (#c9c2b8)
  static const Color headerSub = Color(0xFFC9C2B8);

  // ── Action and state ─────────────────────────────────────
  /// `color.accent.primary` — fill of the one primary button per view,
  /// active-tab underline, CHANGEOVER chip and timer (#ff6a2b). Never text
  /// on a light surface (2.81:1).
  static const Color accentPrimary = Color(0xFFFF6A2B);

  /// `color.accent.onPrimary` — text on orange (#221d18)
  static const Color accentOnPrimary = Color(0xFF221D18);

  /// `color.accent.strong` — selection outline, dashed edit-mode border,
  /// amber-state border (#c2410c)
  static const Color accentStrong = Color(0xFFC2410C);

  /// Focus ring on light surfaces: 3 px, 2 px offset (F07) (#c2410c)
  static const Color focusOnLight = accentStrong;

  /// `color.focus.onDark` — focus ring on [headerBg] and [barBg]: tabs, nav
  /// "⋯", round bar buttons and "⋯", session bar link (F07) (#ff6a2b)
  static const Color focusOnDark = Color(0xFFFF6A2B);

  /// `color.control.border` — inputs, "More", "Edit round" and other outline
  /// buttons (#6f6352)
  static const Color controlBorder = Color(0xFF6F6352);

  /// `color.control.borderSoft` — secondary outline button, e.g. "Re-roll"
  /// (#8f826e)
  static const Color controlBorderSoft = Color(0xFF8F826E);

  /// `color.checkedIn.bg` — checked-in row fill, CHECKED IN result box
  /// (#bfe5c8). The edge carries the state (1.36:1 vs page).
  static const Color checkedInBg = Color(0xFFBFE5C8);

  /// Checked-in player row on hover (#d8eddd)
  static const Color successBgHover = Color(0xFFD8EDDD);

  /// `color.success` — checked-in border and bar, RUNNING chip, IN icon,
  /// "Next in" tag, "Round n saved" (#1f7a3d)
  static const Color success = Color(0xFF1F7A3D);

  /// `color.success.text` — text in the CHECKED IN result box (#14532d)
  static const Color successText = Color(0xFF14532D);

  /// `color.warning.bg` — NEXT tag, PAUSED chip, edit strip, SCANNED TWICE /
  /// MANY / FULL / DUPLICATE ID boxes (#fde7c8)
  static const Color warningBg = Color(0xFFFDE7C8);

  /// `color.warning.text` — text on amber, "Round n not saved" (#9a3412)
  static const Color warningText = Color(0xFF9A3412);

  /// `color.error` — NOT FOUND / DISABLED border and icon, error text on
  /// the page, danger outline (#b91c1c)
  static const Color error = Color(0xFFB91C1C);

  /// `color.error.bg` — NOT FOUND, DISABLED result box (#fde2e2)
  static const Color errorBg = Color(0xFFFDE2E2);

  /// `color.error.text` — text on [errorBg] (#991b1b)
  static const Color errorText = Color(0xFF991B1B);

  /// `color.neutral.bg` — CHECKED OUT result box (#ece6dc)
  static const Color neutralBg = Color(0xFFECE6DC);

  /// `color.urgent.onDark` — time and progress fill on the bars at ≤60 s
  /// while RUNNING; the only ≤60 s amber (R4-Q6, R6-Q8, F26) (#ffb38a)
  static const Color urgentOnDark = Color(0xFFFFB38A);

  // ── Round state chips ────────────────────────────────────
  /// TIME UP chip fill (R11-Q5, F04) (#b91c1c)
  static const Color timeUpBg = error;

  /// TIME UP chip text (#ffffff)
  static const Color timeUpText = Color(0xFFFFFFFF);

  /// The time shown in the TIME UP state (#ff6a2b)
  static const Color timeUpTime = accentPrimary;

  // ── Pills & Chips ───────────────────────────────────────
  /// Chip/pill background, inactive toggle (#f0e6d6)
  static const Color pillBg = Color(0xFFF0E6D6);

  // ── Charts (stay until Analytics is drawn, R2-Q19) ──────
  /// Secondary chart bar color (dark) (#221d18)
  static const Color barSecondary = Color(0xFF221D18);

  /// Tertiary chart bar (light orange) (#ffb38a)
  static const Color barTertiary = Color(0xFFFFB38A);

  /// Chart neutral — light (#e8dcc8)
  static const Color chartNeutralLight = Color(0xFFE8DCC8);

  /// Chart neutral — mid (#d9c7a8)
  static const Color chartNeutralMid = Color(0xFFD9C7A8);

  // ── Misc ─────────────────────────────────────────────────
  /// Pure black
  static const Color black = Color(0xFF000000);

  /// Pure white
  static const Color white = Color(0xFFFFFFFF);

  /// Neutral grey (card shadow)
  static const Color grey = Color(0xFF9E9E9E);

  /// Toggle off-track (#e5e5e5)
  static const Color toggleOff = Color(0xFFE5E5E5);

  /// Toggle off text (#555555)
  static const Color toggleOffText = Color(0xFF555555);

  /// Delta positive green (#2e7d4f)
  static const Color deltaPositive = Color(0xFF2E7D4F);

  /// Delta negative red (#c2410c)
  static const Color deltaNegative = Color(0xFFC2410C);

  /// Overlay backdrop (rgba 20,16,12, 0.45)
  static const Color overlayBackdrop = Color(0x7314100C);

  /// Overlay backdrop lighter (rgba 20,16,12, 0.5)
  static const Color overlayBackdropLighter = Color(0x8014100C);

  /// Drag handle (#e2d8c8)
  static const Color dragHandle = Color(0xFFE2D8C8);
}

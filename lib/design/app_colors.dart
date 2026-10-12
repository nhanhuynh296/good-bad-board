import 'package:flutter/material.dart';

/// Design tokens for the Clubhouse color palette.
///
/// Reference: ARCHITECTURE.md Section 1.1
abstract class AppColors {
  // ── Surface ──────────────────────────────────────────────
  /// Page / scaffold background (#fffdfa)
  static const Color pageBg = Color(0xFFFFFDFA);

  /// Card, panel, modal surface (#fbf6ee)
  static const Color cardBg = Color(0xFFFBF6EE);

  /// Card border, divider lines (#eee4d8)
  static const Color cardBorder = Color(0xFFEEE4D8);

  // ── Header / Nav ────────────────────────────────────────
  /// Top nav, header bar (#221d18)
  static const Color headerBg = Color(0xFF221D18);

  /// Header title text (#ffffff)
  static const Color headerText = Color(0xFFFFFFFF);

  /// Header subtitle / inactive tab (#c9c2b8)
  static const Color headerSub = Color(0xFFC9C2B8);

  // ── Accent ───────────────────────────────────────────────
  /// Primary action, selected state, ELO value, waitlist count (#ff6a2b)
  static const Color accentPrimary = Color(0xFFFF6A2B);

  /// Text on accent background (#221d18)
  static const Color accentOnPrimary = Color(0xFF221D18);

  // ── Text ─────────────────────────────────────────────────
  /// Headings, body text (#221d18)
  static const Color textPrimary = Color(0xFF221D18);

  /// Secondary text, stat labels (#8a7c68)
  static const Color textMuted = Color(0xFF8A7C68);

  /// Placeholder, disabled, tertiary text (#b3a891)
  static const Color textSubtle = Color(0xFFB3A891);

  // ── Pills & Chips ───────────────────────────────────────
  /// Chip/pill background, inactive toggle (#f0e6d6)
  static const Color pillBg = Color(0xFFF0E6D6);

  // ── Success ──────────────────────────────────────────────
  /// Check-in confirmed, active status (#2ea043)
  static const Color success = Color(0xFF2EA043);

  /// Success chip background (#e6f4ea)
  static const Color successBg = Color(0xFFE6F4EA);

  // ── Warning ──────────────────────────────────────────────
  /// Warning / at-capacity text (#a8481a)
  static const Color warningText = Color(0xFFA8481A);

  /// Warning background (#fdeee4)
  static const Color warningBg = Color(0xFFFDEEE4);

  // ── Charts ───────────────────────────────────────────────
  /// Secondary chart bar color (dark) (#221d18)
  static const Color barSecondary = Color(0xFF221D18);

  /// Tertiary chart bar (light orange) (#ffb38a)
  static const Color barTertiary = Color(0xFFFFB38A);

  /// Chart neutral — light (#e8dcc8)
  static const Color chartNeutralLight = Color(0xFFE8DCC8);

  /// Chart neutral — mid (#d9c7a8)
  static const Color chartNeutralMid = Color(0xFFD9C7A8);

  // ── Dark Theme (Command Center) ─────────────────────────
  /// Dark page bg (#12141c)
  static const Color darkPageBg = Color(0xFF12141C);

  /// Dark card bg (#181b26)
  static const Color darkCardBg = Color(0xFF181B26);

  /// Dark card border (#262a38)
  static const Color darkCardBorder = Color(0xFF262A38);

  /// Dark accent — pink (#e94ff5)
  static const Color darkAccent = Color(0xFFE94FF5);

  /// Dark secondary accent — lime (#c4ff5c)
  static const Color darkSecondaryAccent = Color(0xFFC4FF5C);

  // ── Misc ─────────────────────────────────────────────────
  /// Pure black
  static const Color black = Color(0xFF000000);

  /// Pure white
  static const Color white = Color(0xFFFFFFFF);

  /// Neutral grey
  static const Color grey = Color(0xFF9E9E9E);

  /// Toggle off-track (#e5e5e5)
  static const Color toggleOff = Color(0xFFE5E5E5);

  /// Toggle off text (#555555)
  static const Color toggleOffText = Color(0xFF555555);

  /// Delta positive green (#2e7d4f)
  static const Color deltaPositive = Color(0xFF2E7D4F);

  /// Delta negative red (#c2410c)
  static const Color deltaNegative = Color(0xFFC2410C);

  /// Error / danger (#f44336)
  static const Color error = Color(0xFFF44336);

  /// Overlay backdrop (rgba 20,16,12, 0.45)
  static const Color overlayBackdrop = Color(0x7314100C);

  /// Overlay backdrop lighter (rgba 20,16,12, 0.5)
  static const Color overlayBackdropLighter = Color(0x8014100C);

  /// Drag handle (#e2d8c8)
  static const Color dragHandle = Color(0xFFE2D8C8);

  /// Input border (#e2d8c8)
  static const Color inputBorder = Color(0xFFE2D8C8);

  // ── Danger outline ──────────────────────────────────────
  /// Danger outline text (#a3a3a3)
  static const Color dangerOutline = Color(0xFFA3A3A3);
}

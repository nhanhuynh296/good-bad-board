import 'package:flutter/widgets.dart';

/// Design tokens for border radius.
///
/// Reference: ARCHITECTURE.md Section 1.4
abstract class AppRadii {
  /// Small buttons, bar ends (6px)
  static const double sm = 6;

  /// Buttons, inputs, tabs (8px)
  static const double md = 8;

  /// Compact cards, menu items (10px)
  static const double lg = 10;

  /// Cards, panels (12px)
  static const double xl = 12;

  /// Large cards, KPI cards (14px)
  static const double xl2 = 14;

  /// Chips, pills, badges (999px — fully round)
  static const double full = 999;

  // ── BorderRadius convenience getters ─────────────────

  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xl2Radius = BorderRadius.all(Radius.circular(xl2));
  static const BorderRadius fullRadius = BorderRadius.all(
    Radius.circular(full),
  );

  /// Top-only rounded corners for bottom sheets (18px top)
  static const BorderRadius sheetTopRadius = BorderRadius.vertical(
    top: Radius.circular(18),
  );
}

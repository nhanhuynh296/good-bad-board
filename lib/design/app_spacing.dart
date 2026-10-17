import 'package:flutter/widgets.dart';

/// Design tokens for spacing scale.
///
/// Reference: ARCHITECTURE.md Section 1.3.
/// Absorbs the previous `lib/spacing.dart` — old constant names are kept
/// as deprecated aliases for backward compatibility during migration.
abstract class AppSpacing {
  // ── Scale ────────────────────────────────────────────────
  /// Grid dividers, stat strip (1px)
  static const double space1 = 1;

  /// Tab button gaps, inline gaps (4px)
  static const double xs = 4;

  /// Small gaps, chart bar gaps, button gaps (6–8px)
  static const double sm = 8;

  /// List item gaps, card gaps — compact (10–12px)
  static const double md = 12;

  /// Standard card gaps, section gaps (16px)
  static const double lg = 16;

  /// Layout gaps — sidebar, main content (20–24px)
  static const double xl = 24;

  /// Content padding — desktop (32px)
  static const double xl2 = 32;

  // ── Content Padding (by breakpoint) ────────────────────

  /// Desktop content padding: 24px horizontal, 32px vertical
  static const EdgeInsets desktopPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 32,
  );

  /// Desktop compact padding: 16px horizontal, 22px vertical
  static const EdgeInsets desktopPaddingCompact = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 22,
  );

  /// Tablet content padding: 20px horizontal, 24px vertical
  static const EdgeInsets tabletPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 24,
  );

  /// Tablet compact padding: 14px horizontal, 18px vertical
  static const EdgeInsets tabletPaddingCompact = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 18,
  );

  /// Phone content padding: 14px horizontal, 12px vertical
  static const EdgeInsets phonePadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );

  // ── Component Padding ──────────────────────────────────

  /// Standard card padding (16px h, 18px v)
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 18,
  );

  /// Button padding (6px v, 12px h)
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );

  /// Tab button padding (8px v, 12px h)
  static const EdgeInsets tabButtonPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

  /// Chip/pill padding (4px v, 8px h)
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  );

  /// Waitlist chip padding (7px v, 11px h)
  static const EdgeInsets waitlistChipPadding = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 7,
  );

  // ── Legacy aliases (deprecated — prefer new names) ─────

  /// @Deprecated — use [sm] instead.
  @Deprecated('Use AppSpacing.sm')
  static const double space8 = sm;

  /// @Deprecated — use [lg] instead.
  @Deprecated('Use AppSpacing.lg')
  static const double space16 = lg;

  /// @Deprecated — use [xl2] instead.
  @Deprecated('Use AppSpacing.xl2')
  static const double space32 = xl2;

  /// @Deprecated — use a larger spacing token.
  @Deprecated('Use AppSpacing.xl2 * 2 or a custom value')
  static const double space64 = 64;

  /// @Deprecated — use [lg] instead.
  @Deprecated('Use AppSpacing.lg')
  static const double spacePageX = lg;

  /// @Deprecated — use [xl2] instead.
  @Deprecated('Use AppSpacing.xl2')
  static const double spacePageY = xl2;

  /// @Deprecated — use [md] instead.
  @Deprecated('Use AppSpacing.md')
  static const double spaceCard = md;

  /// @Deprecated — use [lg] instead.
  @Deprecated('Use AppSpacing.lg')
  static const double spaceDefault = lg;

  /// @Deprecated — use [sm] instead.
  @Deprecated('Use AppSpacing.sm')
  static const double spaceComponent = sm;

  /// @Deprecated — use [sm] instead.
  @Deprecated('Use AppSpacing.sm')
  static const double spaceXBetweenChip = sm;
}

// ── Top-level backward-compatible aliases ─────────────────
// Old code uses these without the AppSpacing. prefix.
// New code should use AppSpacing.sm, AppSpacing.lg, etc. directly.

/// @Deprecated — use [AppSpacing.sm]
@Deprecated('Use AppSpacing.sm')
const double space8 = AppSpacing.sm;

/// @Deprecated — use [AppSpacing.lg]
@Deprecated('Use AppSpacing.lg')
const double space16 = AppSpacing.lg;

/// @Deprecated — use [AppSpacing.xl2]
@Deprecated('Use AppSpacing.xl2')
const double space32 = AppSpacing.xl2;

/// @Deprecated — use a larger value
@Deprecated('Use AppSpacing.xl2 * 2 or a custom value')
const double space64 = 64;

/// @Deprecated — use [AppSpacing.lg]
@Deprecated('Use AppSpacing.lg')
const double spacePageX = AppSpacing.lg;

/// @Deprecated — use [AppSpacing.xl2]
@Deprecated('Use AppSpacing.xl2')
const double spacePageY = AppSpacing.xl2;

/// @Deprecated — use [AppSpacing.md]
@Deprecated('Use AppSpacing.md')
const double spaceCard = AppSpacing.md;

/// @Deprecated — use [AppSpacing.lg]
@Deprecated('Use AppSpacing.lg')
const double spaceDefault = AppSpacing.lg;

/// @Deprecated — use [AppSpacing.sm]
@Deprecated('Use AppSpacing.sm')
const double spaceComponent = AppSpacing.sm;

/// @Deprecated — use [AppSpacing.sm]
@Deprecated('Use AppSpacing.sm')
const double spaceXBetweenChip = AppSpacing.sm;

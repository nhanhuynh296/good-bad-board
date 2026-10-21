import 'dart:math';

import 'package:flutter/material.dart';
import 'package:good_bad_board/core/duration_extension.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/courts/courts_button.dart';
import 'package:good_bad_board/features/dashboard/courts/courts_confirm_dialog.dart';
import 'package:good_bad_board/features/dashboard/courts/courts_menu.dart';
import 'package:good_bad_board/features/dashboard/courts/round_status.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';

/// The round bar of the Courts tab (IMPLEMENTATION 8.5.2, ARCHITECTURE §2.3
/// RoundBar; UAT RND-01 … RND-20).
///
/// It reads [GameData.phase] and never derives the phase from the clock.
/// The time and the progress bar watch [TimerData] through their own
/// [Consumer], so a clock tick rebuilds only them (R45-03).
///
/// [compact] is the phone and tablet form: the same state, labels and
/// buttons in a wrapping card, in the place of the PR 45 rotation bar
/// (R2-Q23, R6-Q7).
class RoundBar extends StatelessWidget {
  const RoundBar({super.key, this.compact = false});

  final bool compact;

  static const double height = 80;

  @override
  Widget build(BuildContext context) {
    final gameData = context.watch<GameData>();
    final l10n = AppLocalizations.of(context)!;
    final view = _RoundBarView(gameData, l10n);
    return compact
        ? _CompactRoundBar(view: view)
        : _DesktopRoundBar(view: view);
  }
}

/// What the bar shows in the current state (ARCHITECTURE §2.3 table).
class _RoundBarView {
  _RoundBarView(this.gameData, this.l10n);

  final GameData gameData;
  final AppLocalizations l10n;

  RoundPhase get phase => gameData.phase;
  bool get editing => gameData.isEditingNext;
  int get round => gameData.displayRoundNumber;
  int get liveRound => gameData.roundNumber;
  bool get pausedChangeover =>
      phase == RoundPhase.paused &&
      gameData.pausedFrom == RoundPhase.changeover;

  String get roundLabel => l10n.dashboard_round_label(round);

  String? get subLabel => switch (phase) {
    RoundPhase.noLineup || RoundPhase.ready => l10n.courts_sub_not_started,
    RoundPhase.running => null,
    RoundPhase.paused =>
      pausedChangeover
          ? l10n.courts_sub_players_to_courts
          : l10n.courts_sub_paused,
    RoundPhase.timeUp => l10n.courts_sub_time_up,
    RoundPhase.changeover => l10n.courts_sub_players_to_courts,
  };

  RoundStatus get _status => RoundStatus(phase);

  String get chip => _status.chip(l10n);

  (Color, Color) get chipColours => _status.chipColours;

  bool get clockStopped => _status.clockStopped;

  String time(TimerData timer) => _status.time(timer);

  double progress(TimerData timer) => clockStopped ? 0 : timer.progress;

  /// The time colour, also the progress fill (RND-02, R6-Q8, R11-Q5).
  Color timeColour(TimerData timer) => _status.timeColour(timer);

  String get counts => l10n.courts_counts_in_waiting(
    gameData.checkedInCount,
    gameData.sessionCapacity,
    gameData.waitlistOrder.length,
  );

  /// The state buttons, left to right; the last one is the primary.
  List<_BarAction> actions({required bool shortDiscard}) {
    final next = liveRound + 1;
    final discard = _BarAction.outline(
      shortDiscard
          ? l10n.courts_discard_round_short(liveRound)
          : l10n.courts_discard_and_start_round(liveRound),
      _discard,
    );
    final pause = _BarAction.text(l10n.courts_pause, (_) => gameData.pause());
    switch (phase) {
      case RoundPhase.noLineup:
        return [_BarAction.primary(l10n.courts_generate_round_one, _generate)];
      case RoundPhase.ready:
        return [
          _BarAction.outline(
            l10n.courts_discard_and_regenerate,
            (_) => gameData.regenerateDraft(),
          ),
          _BarAction.primary(
            l10n.courts_start_round(1),
            (_) => gameData.startFirstRound(),
          ),
        ];
      case RoundPhase.running:
        if (editing) return [pause];
        return [
          pause,
          discard,
          _BarAction.primary(l10n.courts_start_round(next), _startNext),
        ];
      case RoundPhase.paused:
        if (pausedChangeover) {
          return [
            _BarAction.primary(
              l10n.courts_resume_changeover,
              (_) => gameData.resume(),
            ),
          ];
        }
        return [
          if (!editing) discard,
          _BarAction.outline(l10n.courts_start_round(next), _startNext),
          _BarAction.primary(
            l10n.courts_resume_round(liveRound),
            (_) => gameData.resume(),
          ),
        ];
      case RoundPhase.timeUp:
        if (editing) return const [];
        return [
          discard,
          _BarAction.primary(l10n.courts_start_round(next), _startNext),
        ];
      case RoundPhase.changeover:
        if (gameData.waitingForEdit) return const [];
        if (editing) return [pause];
        return [
          pause,
          _BarAction.primary(l10n.courts_start_round_now(round), _startNow),
        ];
    }
  }

  // ── Actions ──────────────────────────────────────────────

  void _generate(BuildContext context) {
    try {
      gameData.generateFirstRound();
    } on Exception catch (error) {
      showCourtsError(context, error);
    }
  }

  /// "Start round n+1": RUNNING with time left asks "End round n now?"
  /// first; PAUSED and TIME UP start at once (R12-Q1, F05).
  Future<void> _startNext(BuildContext context) async {
    if (gameData.startNeedsConfirm) {
      final confirmed = await showCourtsConfirm(
        context,
        title: l10n.courts_end_round_confirm_title(liveRound),
        body: l10n.courts_end_round_confirm_body(
          gameData.timeLeft.toDisplayString(),
        ),
        cancelLabel: l10n.cancel,
        actionLabel: l10n.courts_start_round(liveRound + 1),
      );
      if (!confirmed) return;
    }
    gameData.startNextRound();
  }

  /// "Discard round n and start again" asks first (R9-Q3).
  Future<void> _discard(BuildContext context) async {
    final confirmed = await showCourtsConfirm(
      context,
      title: l10n.courts_discard_confirm_title(liveRound),
      body: l10n.courts_discard_confirm_body(liveRound),
      cancelLabel: l10n.cancel,
      actionLabel: l10n.courts_discard_confirm_action,
    );
    if (confirmed) gameData.discardAndStartNext();
  }

  void _startNow(BuildContext context) => runRoundStart(gameData.startNextNow);

  /// "End session" (RND-20): the text names the round that is logged
  /// (F09). With no lineup the state layer has nothing to end, so the
  /// check-out of every player is done here.
  Future<void> endSession(BuildContext context) async {
    final logged = gameData.roundToLog;
    final first = logged == null
        ? l10n.courts_end_session_nothing_logged
        : l10n.courts_end_session_body_round(logged);
    final confirmed = await showCourtsConfirm(
      context,
      title: l10n.courts_end_session_title,
      body: '$first ${l10n.courts_end_session_checked_out}',
      cancelLabel: l10n.cancel,
      actionLabel: l10n.courts_end_session,
    );
    if (!confirmed || !context.mounted) return;
    if (gameData.phase == RoundPhase.noLineup) {
      for (final player in gameData.checkedInPlayers.values.toList()) {
        gameData.checkOutPlayer(player);
      }
      return;
    }
    await runCourtsAction(context, gameData.endSession);
  }
}

enum _BarKind { primary, outline, text }

class _BarAction {
  _BarAction.primary(this.label, this.run) : kind = _BarKind.primary;
  _BarAction.outline(this.label, this.run) : kind = _BarKind.outline;
  _BarAction.text(this.label, this.run) : kind = _BarKind.text;

  final String label;
  final _BarKind kind;

  /// Gets the context, so an action can show its confirm dialog.
  final void Function(BuildContext context) run;

  Widget build(BuildContext context) => switch (kind) {
    _BarKind.primary => RoundBarButton.primary(
      label: label,
      onPressed: () => run(context),
    ),
    _BarKind.outline => RoundBarButton.outline(
      label: label,
      onPressed: () => run(context),
    ),
    _BarKind.text => RoundBarButton.text(
      label: label,
      icon: Icons.pause_rounded,
      onPressed: () => run(context),
    ),
  };
}

// ── Shared parts ─────────────────────────────────────────────

class _RoundLabel extends StatelessWidget {
  const _RoundLabel({required this.view});

  final _RoundBarView view;

  @override
  Widget build(BuildContext context) {
    final sub = view.subLabel;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            view.roundLabel,
            style: AppTypography.statLabel.copyWith(color: AppColors.headerSub),
          ),
          if (sub != null)
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(color: AppColors.headerSub),
            ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.view});

  final _RoundBarView view;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = view.chipColours;
    // The chip is a polite live region; the time is not (F24).
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: const Key('round-bar-chip'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: Text(
          view.chip,
          style: AppTypography.statLabel.copyWith(color: foreground),
        ),
      ),
    );
  }
}

class _Time extends StatelessWidget {
  const _Time({required this.view, required this.style});

  final _RoundBarView view;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerData>(
      builder: (context, timer, _) => Text(
        view.time(timer),
        key: const Key('round-bar-time'),
        style: style.copyWith(
          color: view.timeColour(timer),
          fontFeatures: const [FontFeature.tabularFigures()],
          height: 1,
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.view});

  final _RoundBarView view;

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerData>(
      builder: (context, timer, _) => Container(
        height: 4,
        color: AppColors.barTrack,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          key: const Key('round-bar-progress'),
          widthFactor: view.progress(timer),
          heightFactor: 1,
          child: ColoredBox(color: view.timeColour(timer)),
        ),
      ),
    );
  }
}

class _RoundMenu extends StatelessWidget {
  const _RoundMenu({required this.view});

  final _RoundBarView view;

  @override
  Widget build(BuildContext context) {
    final l10n = view.l10n;
    return _CourtsMenu(
      items: [
        _CourtsMenuItem(
          label: l10n.courts_end_session,
          danger: true,
          onPressed: () => view.endSession(context),
        ),
      ],
      builder: (context, open, focusNode) => CourtsIconButton(
        key: const Key('round-menu-button'),
        icon: Icons.more_vert_rounded,
        tooltip: l10n.courts_round_menu,
        color: AppColors.headerSub,
        ringColor: AppColors.focusOnDark,
        size: 44,
        focusNode: focusNode,
        onPressed: open,
      ),
    );
  }
}

// ── Desktop ──────────────────────────────────────────────────

class _DesktopRoundBar extends StatelessWidget {
  const _DesktopRoundBar({required this.view});

  final _RoundBarView view;

  static const double _gap = 24;
  static const double _buttonGap = 12;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: RoundBar.height,
      child: ColoredBox(
        color: AppColors.barBg,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _gap),
                child: LayoutBuilder(
                  builder: (context, constraints) =>
                      _row(context, constraints.maxWidth),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _Progress(view: view),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, double width) {
    final actions = view.actions(
      shortDiscard: _needsShortDiscard(context, width),
    );
    return Row(
      children: [
        _RoundLabel(view: view),
        const SizedBox(width: _gap),
        _Time(view: view, style: AppTypography.timer),
        const SizedBox(width: _buttonGap),
        _StateChip(view: view),
        const SizedBox(width: _gap),
        Expanded(
          child: Text(
            view.counts,
            key: const Key('round-bar-counts'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(color: AppColors.headerSub),
          ),
        ),
        for (final action in actions) ...[
          const SizedBox(width: _buttonGap),
          action.build(context),
        ],
        const SizedBox(width: _buttonGap),
        _RoundMenu(view: view),
      ],
    );
  }

  /// F16: when the labels do not fit (fr, zh, zh_HK at 1280 px),
  /// "Discard round n and start again" becomes "Discard round n". The
  /// dialog keeps the full text. F16 names PAUSED; RUNNING has three
  /// buttons too, so the same check runs in every state with "Discard".
  bool _needsShortDiscard(BuildContext context, double width) {
    final scale = MediaQuery.textScalerOf(context);
    // Merged with the ambient style, so a Chinese glyph is measured in the
    // locale's fallback font (YaHei, JhengHei) that paints it.
    final ambient = DefaultTextStyle.of(context).style;
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: ambient.merge(style)),
        textDirection: Directionality.of(context),
        textScaler: scale,
        maxLines: 1,
      )..layout();
      final value = painter.width;
      painter.dispose();
      return value;
    }

    final buttons = view.actions(shortDiscard: false);
    var needed = 0.0;
    for (final action in buttons) {
      needed += measure(action.label, AppTypography.button) + 40 + _buttonGap;
    }
    needed += 44 + _buttonGap; // round menu
    final label = max(
      120.0,
      max(
        measure(view.roundLabel, AppTypography.statLabel),
        measure(view.subLabel ?? '', AppTypography.body),
      ),
    );
    final time = measure('00:00', AppTypography.timer);
    final chip = measure(view.chip, AppTypography.statLabel) + 16;
    // The counts show in full, so the short label is used before they are
    // cut (F16: fr "{in}/{capacity} présents · {n} en attente" in PAUSED).
    final counts = measure(view.counts, AppTypography.body);
    needed += label + _gap + time + _buttonGap + chip + _gap + counts;
    return needed > width;
  }
}

// ── Phone and tablet ─────────────────────────────────────────

class _CompactRoundBar extends StatelessWidget {
  const _CompactRoundBar({required this.view});

  final _RoundBarView view;

  @override
  Widget build(BuildContext context) {
    final actions = view.actions(shortDiscard: false);
    return ClipRRect(
      borderRadius: AppRadii.xlRadius,
      child: ColoredBox(
        color: AppColors.barBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _RoundLabel(view: view),
                  _Time(view: view, style: AppTypography.display),
                  _StateChip(view: view),
                  Text(
                    view.counts,
                    style: AppTypography.body.copyWith(
                      color: AppColors.headerSub,
                    ),
                  ),
                  for (final action in actions) action.build(context),
                  _RoundMenu(view: view),
                ],
              ),
            ),
            _Progress(view: view),
          ],
        ),
      ),
    );
  }
}

// ── Menu ─────────────────────────────────────────────────────

class _CourtsMenuItem {
  const _CourtsMenuItem({
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool danger;
}

/// A menu in the ARCHITECTURE §2.3 style: card fill, 1 px `#6f6352`
/// border, radius 8, 40 px items. Arrow keys move, Enter selects, Esc
/// closes, and the focus goes back to the button (F06).
class _CourtsMenu extends StatefulWidget {
  const _CourtsMenu({required this.items, required this.builder});

  final List<_CourtsMenuItem> items;
  final Widget Function(
    BuildContext context,
    VoidCallback open,
    FocusNode focusNode,
  )
  builder;

  @override
  State<_CourtsMenu> createState() => _CourtsMenuState();
}

class _CourtsMenuState extends State<_CourtsMenu> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => courtsMenuAnchor(
    focusNode: _focusNode,
    items: [
      for (final item in widget.items)
        (label: item.label, onPressed: item.onPressed, danger: item.danger),
    ],
    builder: (context, open) => widget.builder(context, open, _focusNode),
  );
}

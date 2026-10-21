import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/l10n/skill_tier_l10n.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:provider/provider.dart';

/// Court-count range, the same as on the Sessions tab.
const int _minCourts = 1;
const int _maxCourts = 8;

/// Shortest court card the PR 45 desktop grid (game-based mode) accepts.
const double _minLegacyCourtHeight = 134;

/// Shortest desktop court card: a 40 px header and 4 slots of 40 px, with
/// the card padding (IMPLEMENTATION 8.5.4).
const double _minDesktopCourtHeight = 216;

/// The Courts tab ("Dashboard" on tablet).
///
/// Time mode on desktop (≥1080 px) is the 2026-10-17 design
/// (IMPLEMENTATION 8.5): the [RoundBar], the [NextRoundStrip], a 2×2 grid
/// of [DesktopCourtCard]s and the [WaitlistPanel]. Phone and tablet keep
/// their PR 45 layout (R2-Q23, R6-Q7) with the same round state and labels
/// ([RoundBar] and [NextRoundStrip] in their compact form). Game-based mode
/// (hidden in the release build) keeps the PR 45 page.
///
/// A tap selects a player; a second tap places or swaps them
/// (ARCHITECTURE §4.1). A swap of two players shows the bottom message
/// "Swapped {A} and {B}. Undo" for 10 s (COURT-17).
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  /// The ID of the player selected to place or swap.
  String? _selectedPlayerId;

  /// The lineup the selection was made on. A new lineup on screen drops
  /// the selection.
  Object? _lineupKey;

  GameData? _gameData;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _swapMessage;
  Timer? _swapTimer;
  Object? _shownLogError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gameData = context.read<GameData>();
    if (!identical(gameData, _gameData)) {
      _gameData?.removeListener(_onGameData);
      _gameData = gameData..addListener(_onGameData);
    }
  }

  @override
  void dispose() {
    _gameData?.removeListener(_onGameData);
    _swapTimer?.cancel();
    super.dispose();
  }

  /// Closes the swap message when Undo is no longer possible (any other
  /// change, R6-Q6), and shows a round log that failed at the end of the
  /// changeover (RND-06, R45-01).
  void _onGameData() {
    final gameData = _gameData;
    if (gameData == null || !mounted) return;
    if (_swapMessage != null && !gameData.canUndoSwap) _closeSwapMessage();
    final error = gameData.roundLogError;
    if (error == null) {
      _shownLogError = null;
    } else if (!identical(error, _shownLogError)) {
      _shownLogError = error;
      showCourtsError(context, error);
    }
  }

  Player? get _selectedPlayer {
    final id = _selectedPlayerId;
    if (id == null) return null;
    return context.read<GameData>().checkedInPlayers[id];
  }

  void _selectPlayer(Player player) {
    setState(() {
      _selectedPlayerId = _selectedPlayerId == player.id ? null : player.id;
    });
  }

  void _clearSelection() => setState(() => _selectedPlayerId = null);

  // ── Time mode: swap, place, re-roll, slot menu ──────────────

  void _onSlotTap(int courtIndex, int slotIndex) {
    final gameData = context.read<GameData>();
    final lineup = gameData.visibleMatches;
    if (courtIndex >= lineup.length) return;
    final court = lineup[courtIndex];
    final occupant = slotIndex < court.players.length
        ? court.players[slotIndex]
        : null;
    final selected = _selectedPlayer;
    if (selected == null) {
      // COURT-09: an open slot does nothing with no selection.
      if (occupant != null) setState(() => _selectedPlayerId = occupant.id);
      return;
    }
    if (selected.id == occupant?.id) {
      _clearSelection();
      return;
    }
    if (occupant != null) {
      if (gameData.swapPlayers(selected, occupant)) _showSwapMessage();
    } else {
      // A move into an open slot is not a swap: no message (COURT-17).
      gameData.placePlayerInSlot(selected, courtIndex, slotIndex);
    }
    _clearSelection();
  }

  void _showSwapMessage() {
    final gameData = context.read<GameData>();
    final swap = gameData.lastSwap;
    final l10n = AppLocalizations.of(context)!;
    if (swap == null) return;
    final messenger = ScaffoldMessenger.of(context);
    _closeSwapMessage();
    messenger.hideCurrentSnackBar();
    final (a, b) = swap;
    // Bottom-centre, 360 × 48; it blocks the pointer only inside its box
    // (F15). No keyboard shortcut runs the Undo (R7-Q2).
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.courts_swapped_undo(a.name(), b.name()),
          style: AppTypography.body.copyWith(color: AppColors.headerText),
        ),
        backgroundColor: AppColors.headerBg,
        behavior: SnackBarBehavior.floating,
        width: 360,
        duration: GameData.swapUndoWindow,
        persist: false,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.lgRadius),
        action: SnackBarAction(
          label: l10n.common_undo,
          textColor: AppColors.accentPrimary,
          onPressed: gameData.undoSwap,
        ),
      ),
    );
    _swapMessage = controller;
    _swapTimer = Timer(GameData.swapUndoWindow, _closeSwapMessage);
    unawaited(
      controller.closed.then((_) {
        if (identical(_swapMessage, controller)) {
          _swapMessage = null;
          _swapTimer?.cancel();
        }
      }),
    );
  }

  void _closeSwapMessage() {
    _swapTimer?.cancel();
    _swapTimer = null;
    final message = _swapMessage;
    _swapMessage = null;
    message?.close();
  }

  void _onReroll(int courtIndex) {
    final gameData = context.read<GameData>();
    // COURT-03: nobody to rotate in, so it stays quiet.
    if (!gameData.canRerollCourt(courtIndex)) return;
    try {
      gameData.makeSingleCourt(courtIndex);
    } on Exception catch (error) {
      showCourtsError(context, error);
    }
    _clearSelection();
  }

  /// Whether the courts on screen take a tap, a swap, Re-roll and the full
  /// slot menu (COURT-14). With no lineup there is nothing to change.
  static bool _canEdit(GameData gameData) =>
      gameData.canEditCourts && gameData.phase != RoundPhase.noLineup;

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gameData = context.watch<GameData>();
    // Watched, not read statically: switching mode on the Sessions tab has to
    // rebuild this page.
    final settings = context.watch<PersistentSetting>();
    final isGameBased = settings.getGameType() == GameType.gameBased;
    final width = MediaQuery.sizeOf(context).width;

    final lineupKey = (
      gameData.phase,
      gameData.isEditingNext,
      identityHashCode(gameData.visibleMatches),
    );
    if (lineupKey != _lineupKey) {
      _lineupKey = lineupKey;
      _selectedPlayerId = null;
    }

    if (isGameBased) return _buildGameBased(gameData, isDesktop(width));
    if (isDesktop(width)) return _buildDesktop(gameData);
    return _buildStacked(gameData);
  }

  // ── Desktop, time mode (IMPLEMENTATION 8.5.1) ───────────────

  Widget _buildDesktop(GameData gameData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RoundBar(),
        if (NextRoundStrip.showsFor(gameData)) const NextRoundStrip(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildDesktopGrid(gameData)),
                const SizedBox(width: AppSpacing.lg),
                _buildWaitlistPanel(gameData),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopGrid(GameData gameData) {
    final lineup = gameData.visibleMatches;
    final count = gameData.numberOfCourt;
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = courtGridLayout(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          courtCount: count,
          gap: AppSpacing.lg,
          minCourtHeight: _minDesktopCourtHeight,
        );
        return GridView.builder(
          physics: layout.scrolls ? null : const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: layout.columns,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.lg,
            mainAxisExtent: layout.courtHeight,
          ),
          itemCount: count,
          itemBuilder: (context, index) => _buildDesktopCourt(
            gameData,
            index,
            index < lineup.length ? lineup[index] : null,
          ),
        );
      },
    );
  }

  Widget _buildDesktopCourt(GameData gameData, int index, Game? game) {
    final players = game?.players ?? const <Player>[];
    final canEdit = _canEdit(gameData);
    final selectionActive = _selectedPlayer != null;
    final slots = [
      for (var slot = 0; slot < Game.playerPerCourt; slot++)
        _slotData(
          gameData,
          index,
          slot,
          slot < players.length ? players[slot] : null,
          canEdit: canEdit,
          selectionActive: selectionActive,
        ),
    ];
    final timeUp =
        gameData.phase == RoundPhase.timeUp && !gameData.isEditingNext;
    return DesktopCourtCard(
      courtIndex: index,
      slots: slots,
      levelGap: game?.tierGap() ?? 0,
      isNextRound: gameData.isEditingNext,
      roundTag: timeUp ? gameData.roundNumber + 1 : null,
      onReroll: canEdit ? () => _onReroll(index) : null,
    );
  }

  CourtSlotData _slotData(
    GameData gameData,
    int court,
    int slot,
    Player? player, {
    required bool canEdit,
    required bool selectionActive,
  }) {
    final SlotMenu menu;
    if (player == null) {
      menu = SlotMenu.none;
    } else if (canEdit) {
      menu = SlotMenu.full;
    } else if (gameData.phase == RoundPhase.noLineup) {
      menu = SlotMenu.none;
    } else {
      // A live court while the clock runs: "Check out" only (R7-Q4), and
      // nothing for a player who is already checked out (R11-Q4).
      menu = gameData.isCheckedOutOnLiveCourt(player)
          ? SlotMenu.none
          : SlotMenu.checkOutOnly;
    }
    final tappable = canEdit && (player != null || selectionActive);
    return CourtSlotData(
      player: player,
      menu: menu,
      isSelected: player != null && player.id == _selectedPlayerId,
      onTap: tappable ? () => _onSlotTap(court, slot) : null,
      onMoveToWaitlist: player == null
          ? null
          : () {
              gameData.moveToWaitlist(player);
              _clearSelection();
            },
      onCheckOut: player == null
          ? null
          : () {
              // No bottom message on Courts (R7-Q5).
              gameData.checkOutPlayer(player);
              _clearSelection();
            },
    );
  }

  Widget _buildWaitlistPanel(GameData gameData) {
    final l10n = AppLocalizations.of(context)!;
    final canEdit = _canEdit(gameData);
    final noLineup = gameData.phase == RoundPhase.noLineup;
    final rounds = gameData.getCurrentPlayersHistory();
    final next = gameData.nextLineup;
    // "Next in": in the saved round n+1 while the courts show round n.
    final showsNext = identical(gameData.visibleMatches, next);
    final nextIds = gameData.isNextRoundSaved && !showsNext && next != null
        ? {for (final game in next) ...game.playerIds}
        : const <String>{};
    final entries = [
      for (final player in gameData.waitlistOrder)
        (
          player: player,
          roundsPlayed: (rounds[player] ?? 0).toInt(),
          nextIn: nextIds.contains(player.id),
        ),
    ];
    final selected = entries.firstWhereOrNull(
      (entry) => entry.player.id == _selectedPlayerId,
    );
    final String? hint;
    if (noLineup) {
      hint = null;
    } else if (!canEdit) {
      hint = l10n.courts_waitlist_hint_live;
    } else if (_selectedPlayer != null) {
      hint = l10n.dashboard_waitlist_hint_place(
        (selected?.player ?? _selectedPlayer!).name(),
      );
    } else {
      hint = l10n.dashboard_waitlist_hint_select;
    }
    return WaitlistPanel(
      entries: entries,
      hint: hint,
      selectedPlayerId: _selectedPlayerId,
      onSelect: canEdit ? _selectPlayer : null,
    );
  }

  // ── Phone and tablet, time mode (R2-Q23, R6-Q7) ─────────────

  Widget _buildStacked(GameData gameData) {
    final canEdit = _canEdit(gameData);
    final waitlisted = gameData.waitlistOrder;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatStrip(gameData, waitlisted),
          const SizedBox(height: AppSpacing.lg),
          const RoundBar(compact: true),
          if (NextRoundStrip.showsFor(gameData)) ...[
            const SizedBox(height: AppSpacing.md),
            const NextRoundStrip(compact: true),
          ],
          const SizedBox(height: AppSpacing.lg),
          WaitlistChips(
            players: waitlisted,
            selectedPlayerId: _selectedPlayerId,
            selectedPlayerName: _selectedPlayer?.name(),
            onPlayerSelect: canEdit ? _selectPlayer : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildLegacyCourtGrid(
            gameData,
            fitToHeight: false,
            canEdit: canEdit,
            isGameBased: false,
          ),
        ],
      ),
    );
  }

  // ── Game-based mode: the PR 45 page (hidden in the release) ──

  Future<void> _onMakeGame() async {
    final gameData = context.read<GameData>();
    try {
      await gameData.makeGame();
      if (mounted) _clearSelection();
    } on Exception catch (error) {
      if (mounted) showCourtsError(context, error);
    }
  }

  /// Saves one court's lineup (game-based mode): the match is logged and the
  /// court is marked PLAYING with its players still on it.
  Future<void> _onSaveCourt(int courtIndex) async {
    final gameData = context.read<GameData>();
    if (courtIndex >= gameData.stagingMatches.length) return;
    try {
      await gameData.saveSingleGame(gameData.stagingMatches[courtIndex]);
      if (mounted) _clearSelection();
    } on Exception catch (error) {
      if (mounted) showCourtsError(context, error);
    }
  }

  void _onLegacySlotTap(int courtIndex, int slotIndex) {
    final gameData = context.read<GameData>();
    final court = gameData.visibleMatches[courtIndex];
    final occupant = slotIndex < court.players.length
        ? court.players[slotIndex]
        : null;
    final player = _selectedPlayer;
    if (player == null) {
      setState(() => _selectedPlayerId = occupant?.id);
      return;
    }
    if (player.id == occupant?.id) {
      _clearSelection();
      return;
    }
    gameData.placePlayerInSlot(player, courtIndex, slotIndex);
    _clearSelection();
  }

  void _onRemovePlayer(int courtIndex, int slotIndex) {
    final gameData = context.read<GameData>();
    final court = gameData.visibleMatches[courtIndex];
    if (slotIndex >= court.players.length) return;
    final player = court.players[slotIndex];
    gameData.removePlayerFromCourt(player);
    if (_selectedPlayerId == player.id) _clearSelection();
  }

  void _onCourtCountChanged(int delta) {
    final gameData = context.read<GameData>();
    final target = gameData.numberOfCourt + delta;
    // Same range as the Sessions tab (1 to 8).
    if (target < _minCourts || target > _maxCourts) return;
    gameData.setNumberOfCourt(target);
    _clearSelection();
  }

  Widget _buildGameBased(GameData gameData, bool desktop) {
    final waitlisted = gameData.visibleWaitlistedPlayers.toList();
    final header = <Widget>[
      _buildStatStrip(gameData, waitlisted),
      const SizedBox(height: AppSpacing.lg),
      _ActionBar(
        numberOfCourt: gameData.numberOfCourt,
        // Game-based generates every court once, at the start of the
        // session; after that each court is driven on its own.
        showGenerate: !gameData.hasAnyCourtLineup,
        onMakeGame: _onMakeGame,
        onCourtCountChanged: _onCourtCountChanged,
      ),
      const SizedBox(height: AppSpacing.lg),
    ];

    if (desktop) {
      // The shell gives the Courts tab no padding on desktop.
      return Padding(
        padding: AppSpacing.desktopPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...header,
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildLegacyCourtGrid(
                      gameData,
                      fitToHeight: true,
                      canEdit: true,
                      isGameBased: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  WaitlistSidebar(
                    players: waitlisted,
                    selectedPlayerId: _selectedPlayerId,
                    selectedPlayerName: _selectedPlayer?.name(),
                    onPlayerSelect: _selectPlayer,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...header,
          WaitlistChips(
            players: waitlisted,
            selectedPlayerId: _selectedPlayerId,
            selectedPlayerName: _selectedPlayer?.name(),
            onPlayerSelect: _selectPlayer,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildLegacyCourtGrid(
            gameData,
            fitToHeight: false,
            canEdit: true,
            isGameBased: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatStrip(GameData gameData, List<Player> waitlisted) {
    final l10n = AppLocalizations.of(context)!;
    final visibleMatches = gameData.visibleMatches;
    final totalSlots = gameData.numberOfCourt * Game.playerPerCourt;
    final onCourt = visibleMatches.expand((g) => g.players).toList();
    var avgLevel = '—';
    if (onCourt.isNotEmpty) {
      final avg = onCourt.map((p) => p.elo.index).average;
      final closest = Elo.values[avg.round().clamp(0, Elo.values.length - 1)];
      avgLevel = closest.skillTier.localizedLabel(l10n);
    }
    final gaps = visibleMatches
        .where((g) => g.players.length >= 2)
        .map((g) => g.tierGap())
        .toList();
    return StatStrip(
      checkedIn: '${gameData.checkedInPlayers.length}',
      remainingSlots: '${totalSlots - onCourt.length}',
      waitlist: '${waitlisted.length}',
      avgLevel: avgLevel,
      avgLevelGap: gaps.isEmpty ? '—' : gaps.average.toStringAsFixed(1),
      rerolls: '${gameData.sessionRerollCount}',
    );
  }

  Widget _buildLegacyCourtGrid(
    GameData gameData, {
    required bool fitToHeight,
    required bool canEdit,
    required bool isGameBased,
  }) {
    final lineup = gameData.visibleMatches;
    final courtCount = gameData.numberOfCourt;
    final selectionActive = _selectedPlayer != null;

    if (courtCount == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sports_tennis_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context)!.dashboard_generate_hint,
              style: AppTypography.body.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // The stacked layout scrolls as a whole page, so its grid has no
        // height to fill: a height of 0 gives the minimum court proportion.
        final layout = courtGridLayout(
          width: constraints.maxWidth,
          height: fitToHeight ? constraints.maxHeight : 0,
          courtCount: courtCount,
          gap: AppSpacing.lg,
          minCourtHeight: fitToHeight ? _minLegacyCourtHeight : double.infinity,
          maxColumnCount: fitToHeight
              ? null
              : (isPhone(MediaQuery.sizeOf(context).width) ? 1 : 2),
        );

        return GridView.builder(
          shrinkWrap: !fitToHeight,
          physics: fitToHeight ? null : const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: layout.columns,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.lg,
            mainAxisExtent: layout.courtHeight,
          ),
          itemCount: courtCount,
          itemBuilder: (context, index) {
            final game = index < lineup.length ? lineup[index] : null;
            final players = game?.players ?? const <Player>[];
            final isPlaying = gameData.isCourtPlaying(index);
            final editable = canEdit && !isPlaying;
            return CourtCard(
              courtNumber: index + 1,
              players: players,
              spreadLevel: game?.tierGap() ?? 0,
              isSelectionActive: selectionActive && editable,
              isPlaying: isPlaying,
              isNextRound: !isGameBased && gameData.isEditingNext,
              onReroll: canEdit && players.isNotEmpty
                  ? () => _onReroll(index)
                  : null,
              // A saved lineup is locked — re-roll the court to end the game.
              onSlotTap: editable
                  ? (slot) => isGameBased
                        ? _onLegacySlotTap(index, slot)
                        : _onSlotTap(index, slot)
                  : null,
              selectedPlayerId: _selectedPlayerId,
              onRemovePlayer: canEdit
                  ? (slot) => _onRemovePlayer(index, slot)
                  : null,
              onSave: isGameBased ? () => _onSaveCourt(index) : null,
            );
          },
        );
      },
    );
  }
}

/// The game-based action bar: Generate Game and the court count stepper
/// (hidden in the release, R45-36).
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.numberOfCourt,
    required this.showGenerate,
    required this.onMakeGame,
    required this.onCourtCountChanged,
  });

  final int numberOfCourt;
  final bool showGenerate;
  final VoidCallback onMakeGame;
  final void Function(int delta) onCourtCountChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // A Wrap, so that long labels (e.g. French) move the court count to a
    // second line on a phone instead of overflowing.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (showGenerate)
          _ActionButton(
            label: l10n.generate_game,
            icon: Icons.casino_rounded,
            onTap: onMakeGame,
          ),
        if (CourtCount.editable)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.dashboard_courts_label,
                style: AppTypography.helperBold,
              ),
              const SizedBox(width: AppSpacing.sm),
              _CourtCountButton(
                icon: Icons.remove_rounded,
                onTap: () => onCourtCountChanged(-1),
              ),
              const SizedBox(width: 6),
              Text('$numberOfCourt', style: AppTypography.statValueSm),
              const SizedBox(width: 6),
              _CourtCountButton(
                icon: Icons.add_rounded,
                onTap: () => onCourtCountChanged(1),
              ),
            ],
          ),
      ],
    );
  }
}

/// The primary button in the game-based action bar.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.mdRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.accentPrimary,
            borderRadius: AppRadii.mdRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.accentOnPrimary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.button.copyWith(
                  color: AppColors.accentOnPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small square button for adjusting court count.
class _CourtCountButton extends StatelessWidget {
  const _CourtCountButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.smRadius,
        child: Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.pillBg,
            borderRadius: AppRadii.smRadius,
          ),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:good_bad_board/core/duration_extension.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';

/// The Dashboard tab — court grid, waitlist, stat strip, and all game
/// interactions (place/swap, re-roll, make game, save).
///
/// Implements the click-to-select-then-click-to-place interaction pattern
/// described in ARCHITECTURE.md Section 4.1.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  /// The ID of the currently selected waitlist/court player for placement.
  String? _selectedPlayerId;

  Player? get _selectedPlayer {
    if (_selectedPlayerId == null) return null;
    final gameData = context.read<GameData>();
    return gameData.checkedInPlayers[_selectedPlayerId];
  }

  void _selectPlayer(Player player) {
    setState(() {
      // Toggle selection if tapping the same player
      if (_selectedPlayerId == player.id) {
        _selectedPlayerId = null;
      } else {
        _selectedPlayerId = player.id;
      }
    });
  }

  void _onSlotTap(int courtIndex, int slotIndex) {
    final gameData = context.read<GameData>();
    final player = _selectedPlayer;
    if (player == null) {
      // Selection became stale (player was deleted); clear it.
      setState(() => _selectedPlayerId = null);
      return;
    }

    gameData.placePlayerInSlot(player, courtIndex, slotIndex);

    setState(() {
      _selectedPlayerId = null;
    });
  }

  void _onReroll(int courtIndex) {
    final gameData = context.read<GameData>();
    try {
      gameData.makeSingleCourt(courtIndex);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  /// Whether the session runs in game-based mode, where courts are saved and
  /// re-rolled by hand and no countdown runs.
  bool get _isGameBased =>
      context.read<PersistentSetting>().getGameType() == GameType.gameBased;

  Future<void> _onMakeGame() async {
    final gameData = context.read<GameData>();
    final timerData = context.read<TimerData>();
    final isGameBased = _isGameBased;
    try {
      await gameData.makeGame();
      if (!mounted) return;
      setState(() {
        _selectedPlayerId = null;
      });
      // Game-based rounds have no clock — the organizer drives each court.
      if (isGameBased) return;
      // Start (or restart) the countdown timer for the new game.
      timerData.duration = PersistentSetting.instance.getGameDuration();
      timerData.reset();
      timerData.start(onExpired: _onAutoRotate);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  /// Saves one court's lineup (game-based mode): the match is logged and the
  /// court is marked PLAYING with its players still on it.
  Future<void> _onSaveCourt(int courtIndex) async {
    final gameData = context.read<GameData>();
    if (courtIndex >= gameData.stagingMatches.length) return;
    try {
      await gameData.saveSingleGame(gameData.stagingMatches[courtIndex]);
      if (!mounted) return;
      setState(() {
        _selectedPlayerId = null;
      });
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _onSaveGame() async {
    final gameData = context.read<GameData>();
    final timerData = context.read<TimerData>();
    try {
      await gameData.saveCurrentGame();
      if (!mounted) return;
      timerData.reset();
      setState(() {
        _selectedPlayerId = null;
      });
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  /// Ends the current round and starts the next one.
  ///
  /// The finished round is logged by [GameData.rotateNow], so this awaits the
  /// write before restarting the clock.
  Future<void> _rotate() async {
    final gameData = context.read<GameData>();
    final timerData = context.read<TimerData>();
    try {
      await gameData.rotateNow();
      if (!mounted) return;
      setState(() {
        _selectedPlayerId = null;
      });
      timerData.reset();
      timerData.start(onExpired: _onAutoRotate);
    } catch (e) {
      // Deliberately catches Error as well as Exception: this also runs from
      // the countdown's expiry callback, and a rotation that dies there would
      // strand the session on a finished round with a stopped clock. Restart
      // the clock regardless so the round still turns over.
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      timerData.reset();
      timerData.start(onExpired: _onAutoRotate);
    }
  }

  void _onRotateNow() => unawaited(_rotate());

  void _onStageNext() {
    final gameData = context.read<GameData>();
    gameData.stageNextRound();
    // Staging selects the next round, so a player picked for the live round
    // must not carry over into the plan.
    setState(() {
      _selectedPlayerId = null;
    });
  }

  void _onCancelStaged() {
    final gameData = context.read<GameData>();
    gameData.cancelStagedRound();
    setState(() {
      _selectedPlayerId = null;
    });
  }

  /// Switches the court grid between the live round and the pre-made one.
  void _onSelectView(RoundView view) {
    final gameData = context.read<GameData>();
    gameData.setRoundView(view);
    // A player selected against one lineup must not be placed into the other.
    setState(() {
      _selectedPlayerId = null;
    });
  }

  void _onAutoRotate() => unawaited(_rotate());

  void _onCourtCountChanged(int delta) {
    final gameData = context.read<GameData>();
    gameData.setNumberOfCourt(gameData.numberOfCourt + delta);
  }

  @override
  Widget build(BuildContext context) {
    final gameData = context.watch<GameData>();
    // Watched, not read statically: switching mode on the Sessions tab has to
    // rebuild this page.
    final settings = context.watch<PersistentSetting>();
    final isGameBased = settings.getGameType() == GameType.gameBased;
    // The grid, the sidebar and the stat strip all describe the round on
    // screen — the live one, or the pre-made next one.
    final visibleMatches = gameData.visibleMatches;
    final isNextRound = gameData.roundView == RoundView.next;
    final waitlisted = gameData.visibleWaitlistedPlayers.toList();
    final hasActiveGame = gameData.hasAnyCourtLineup;
    final totalSlots = gameData.numberOfCourt * Game.playerPerCourt;
    final playersOnCourt = visibleMatches.fold<int>(
      0,
      (sum, g) => sum + g.players.length,
    );
    final remainingSlots = totalSlots - playersOnCourt;

    // Avg level across all players on courts
    String avgLevel;
    if (playersOnCourt > 0) {
      final allElos = visibleMatches
          .expand((g) => g.players)
          .map((p) => p.elo.index)
          .toList();
      final avg = allElos.reduce((a, b) => a + b) / allElos.length;
      // Map back to closest Elo name
      const eloValues = Elo.values;
      final closest = eloValues[(avg.round()).clamp(0, eloValues.length - 1)];
      avgLevel = closest.toDisplayName();
    } else {
      avgLevel = '—';
    }

    // Average level gap across courts
    String avgLevelGap;
    final gaps = visibleMatches
        .where((g) => g.players.length >= 2)
        .map((g) => g.eloGap())
        .toList();
    if (gaps.isNotEmpty) {
      final avgGap = gaps.reduce((a, b) => a + b) / gaps.length;
      avgLevelGap = avgGap.toStringAsFixed(1);
    } else {
      avgLevelGap = '—';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Stat Strip ────────────────────────────────────
        StatStrip(
          checkedIn: '${gameData.checkedInPlayers.length}',
          remainingSlots: '$remainingSlots',
          waitlist: '${waitlisted.length}',
          avgLevel: avgLevel,
          avgLevelGap: avgLevelGap,
          rerolls: '${gameData.sessionRerollCount}',
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Action Bar (Generate / Save / Courts) ─────────
        _ActionBar(
          hasActiveGame: hasActiveGame,
          numberOfCourt: gameData.numberOfCourt,
          // Game-based generates every court once, at the start of the
          // session; after that each court is driven on its own. Neither
          // button belongs to the pre-made round: it is not the round being
          // played, and "Cancel next" then "Pre-make next round" replaces it.
          showGenerate:
              !isNextRound && (!isGameBased || !gameData.hasAnyCourtLineup),
          // Game-based saves court by court, so there is no global save.
          showSave: !isGameBased && !isNextRound,
          onMakeGame: _onMakeGame,
          onSaveGame: _onSaveGame,
          onCourtCountChanged: _onCourtCountChanged,
        ),

        // ── Round Rotation Bar (time-based only) ──────────
        if (hasActiveGame && !isGameBased) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildRoundRotationBar(gameData),
        ],
        const SizedBox(height: AppSpacing.lg),

        // ── Main Content (responsive) ─────────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              if (isDesktop(width)) {
                return _buildDesktopLayout(
                  visibleMatches,
                  waitlisted,
                  gameData,
                  isGameBased,
                  isNextRound,
                );
              } else {
                return _buildStackedLayout(
                  visibleMatches,
                  waitlisted,
                  gameData,
                  isGameBased,
                  isNextRound,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // ── Round Rotation Bar Builder ─────────────────────────

  /// Builds the mode label for the round rotation bar per RND-09.
  ///
  /// Only reachable in time-based mode — game-based has no rotation bar.
  String _buildModeLabel(AppLocalizations l10n) {
    final duration = PersistentSetting.instance.getGameDuration();
    return l10n.dashboard_mode_time_based(duration.toDisplayString());
  }

  /// Describes the pre-made next round, e.g. "16 players across 4 courts".
  String _buildStagedSummary(AppLocalizations l10n, GameData gameData) {
    final staged = gameData.stagedLineup;
    if (staged == null) return '';
    final playerCount = staged.fold<int>(
      0,
      (sum, g) => sum + g.playerIds.length,
    );
    final courtCount = staged.where((g) => g.playerIds.isNotEmpty).length;
    return l10n.dashboard_staged_summary(
      l10n.dashboard_player_count(playerCount),
      l10n.dashboard_court_count(courtCount),
    );
  }

  Widget _buildRoundRotationBar(GameData gameData) {
    final timerData = context.watch<TimerData>();
    final l10n = AppLocalizations.of(context)!;
    return RoundRotationBar(
      roundNumber: gameData.roundNumber,
      modeLabel: _buildModeLabel(l10n),
      remainingLabel: timerData.remainingLabel,
      pct: timerData.pct,
      isUrgent: timerData.isUrgent,
      isStaged: gameData.isStaged,
      stagedSummary: _buildStagedSummary(l10n, gameData),
      stagedPct: 100.0 - timerData.pct, // fills up as main bar depletes
      selectedView: gameData.roundView,
      onSelectView: _onSelectView,
      onRotateNow: _onRotateNow,
      onStageNext: _onStageNext,
      onCancelStaged: _onCancelStaged,
    );
  }

  // ── Desktop: Court Grid + Waitlist Sidebar ──────────────

  Widget _buildDesktopLayout(
    List<Game> courts,
    List<Player> waitlisted,
    GameData gameData,
    bool isGameBased,
    bool isNextRound,
  ) {
    final selectionActive =
        _selectedPlayerId != null &&
        gameData.checkedInPlayers.containsKey(_selectedPlayerId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Court grid. The grid itself does not scroll (shrinkWrap +
        // NeverScrollableScrollPhysics), so past the first row of courts it
        // would overflow the bounded height with no way to reach the rest.
        Expanded(
          child: SingleChildScrollView(
            child: _buildCourtGrid(
              courts,
              selectionActive,
              gameData,
              isGameBased,
              isNextRound,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        // Waitlist sidebar
        WaitlistSidebar(
          players: waitlisted,
          selectedPlayerId: _selectedPlayerId,
          onPlayerSelect: _selectPlayer,
        ),
      ],
    );
  }

  // ── Tablet/Phone: Waitlist Chips + Court Grid ──────────

  Widget _buildStackedLayout(
    List<Game> courts,
    List<Player> waitlisted,
    GameData gameData,
    bool isGameBased,
    bool isNextRound,
  ) {
    final selectionActive =
        _selectedPlayerId != null &&
        gameData.checkedInPlayers.containsKey(_selectedPlayerId);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Waitlist chips
          WaitlistChips(
            players: waitlisted,
            selectedPlayerId: _selectedPlayerId,
            onPlayerSelect: _selectPlayer,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Court grid
          _buildCourtGrid(
            courts,
            selectionActive,
            gameData,
            isGameBased,
            isNextRound,
          ),
        ],
      ),
    );
  }

  // ── Court Grid ─────────────────────────────────────────

  Widget _buildCourtGrid(
    List<Game> lineup,
    bool selectionActive,
    GameData gameData,
    bool isGameBased,
    bool isNextRound,
  ) {
    // Show courts up to numberOfCourt (pad with empty if needed)
    final courtCount = gameData.numberOfCourt;
    final courts = <_CourtDisplay>[];

    for (var i = 0; i < courtCount; i++) {
      final game = i < lineup.length ? lineup[i] : Game.create([]);
      courts.add(
        _CourtDisplay(
          courtNumber: i + 1,
          players: game.players,
          spreadLevel: game.eloGap(),
        ),
      );
    }

    if (courts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sports_tennis_rounded,
              size: 48,
              color: AppColors.textSubtle,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context)!.dashboard_generate_hint,
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textSubtle,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = isPhone(width) ? 1 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.lg,
            childAspectRatio: 1.6,
          ),
          itemCount: courts.length,
          itemBuilder: (context, index) {
            final court = courts[index];
            final isPlaying = gameData.isCourtPlaying(index);
            return CourtCard(
              courtNumber: court.courtNumber,
              players: court.players,
              spreadLevel: court.spreadLevel,
              isSelectionActive: selectionActive && !isPlaying,
              isPlaying: isPlaying,
              isNextRound: isNextRound,
              onReroll: court.players.isNotEmpty
                  ? () => _onReroll(index)
                  : null,
              // A saved lineup is locked — re-roll the court to end the game.
              onSlotTap: selectionActive && !isPlaying
                  ? (slotIndex) => _onSlotTap(index, slotIndex)
                  : null,
              // A plan has nothing to save — it is logged when it is played.
              onSave: isGameBased && !isNextRound
                  ? () => _onSaveCourt(index)
                  : null,
            );
          },
        );
      },
    );
  }
}

/// Lightweight data class for court display info.
class _CourtDisplay {
  const _CourtDisplay({
    required this.courtNumber,
    required this.players,
    required this.spreadLevel,
  });

  final int courtNumber;
  final List<Player> players;
  final int spreadLevel;
}

/// The action bar below the stat strip: Generate Game, Save, and court
/// count adjuster.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.hasActiveGame,
    required this.numberOfCourt,
    required this.showGenerate,
    required this.showSave,
    required this.onMakeGame,
    required this.onSaveGame,
    required this.onCourtCountChanged,
  });

  final bool hasActiveGame;
  final int numberOfCourt;

  /// Whether the Generate / Regenerate button is offered.
  final bool showGenerate;

  /// Whether the global Save button is offered.
  final bool showSave;

  final VoidCallback onMakeGame;
  final VoidCallback onSaveGame;
  final void Function(int delta) onCourtCountChanged;

  @override
  Widget build(BuildContext context) {
    final saveVisible = showSave && hasActiveGame;
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        // Generate / Regenerate
        if (showGenerate) ...[
          _ActionButton(
            label: hasActiveGame ? l10n.regenerate : l10n.generate_game,
            icon: Icons.casino_rounded,
            isPrimary: !hasActiveGame,
            onTap: onMakeGame,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        // Save
        if (saveVisible) ...[
          _ActionButton(
            key: const Key('dashboard-save-all'),
            label: l10n.save,
            icon: Icons.save_rounded,
            isPrimary: true,
            onTap: onSaveGame,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        const Spacer(),
        // Court count
        Text(l10n.dashboard_courts_label, style: AppTypography.helperBold),
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
    );
  }
}

/// A button in the action bar.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
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
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.accentPrimary : AppColors.pillBg,
            borderRadius: AppRadii.mdRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isPrimary
                    ? AppColors.accentOnPrimary
                    : AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.button.copyWith(
                  color: isPrimary
                      ? AppColors.accentOnPrimary
                      : AppColors.textPrimary,
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

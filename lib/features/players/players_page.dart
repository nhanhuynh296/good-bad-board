import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:good_bad_board/core/importer.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/courts/courts_button.dart';
import 'package:good_bad_board/features/dashboard/courts/courts_confirm_dialog.dart';
import 'package:good_bad_board/features/players/capacity_bar.dart';
import 'package:good_bad_board/features/players/desktop_player_row.dart';
import 'package:good_bad_board/features/players/more_panel.dart';
import 'package:good_bad_board/features/players/player_profile_card.dart';
import 'package:good_bad_board/features/players/player_profile_stats.dart';
import 'package:good_bad_board/features/players/player_row.dart';
import 'package:good_bad_board/features/players/scan_field.dart';
import 'package:good_bad_board/features/players/scan_result.dart';
import 'package:good_bad_board/features/players/scan_result_box.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/l10n/skill_tier_l10n.dart';
import 'package:good_bad_board/features/players/pending_registration.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/pending_registration.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/pending_registration_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/repository/session_log_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/dialog/add_player.dart';
import 'package:good_bad_board/view/component/dialog/edit_player.dart';
import 'package:good_bad_board/view/component/dialog/toasts.dart';
import 'package:provider/provider.dart';

/// The Players tab — searchable player list, expandable profile cards,
/// level adjustment, membership cycling, check-in toggles, and capacity tracking.
///
/// Reads player data from [PlayerRepository] and session state from [GameData].
/// Check-in behavior is wired directly to [GameData] (CHK-01…06 acceptance criteria).
class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key, this.showImportButton = false});

  /// Shows the CSV "Import" button. Off for the current release; the import
  /// code stays so it can come back.
  final bool showImportButton;

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

/// Space at the right of the desktop list for the scroll bar.
const double _scrollBarGutter = 16;

class _PlayersPageState extends State<PlayersPage> {
  // ── Search & Filter ──────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  /// Whether this tab is the one on screen. The shell keeps hidden tabs
  /// alive, so a change of this value is how the page knows it was opened.
  bool _tabActive = false;

  /// The 8 Elo-code chips of phone and tablet: empty = all selected.
  Set<Elo> _eloFilters = {};

  /// The 4 tier chips of desktop (R6-Q13): the tiers whose chip is on;
  /// empty = no chip on, so every tier shows.
  final Set<SkillTier> _tierFilters = {};

  /// Whether the last build used the desktop layout (≥1080 px).
  bool _desktop = false;

  /// What the last scan did; the desktop result box shows it (8.7.2).
  ScanResult _scanResult = const ScanResult.ready();

  /// The player that the last scan checked in: the double-scan guard
  /// (8.7.4, R2-Q11, R6-Q15). Desktop only.
  String? _lastScanCheckInId;

  String get _query => _searchController.text.trim().toUpperCase();

  bool _matchesQuery(Player p) =>
      p.name().toUpperCase().contains(_query) ||
      (p.signInId ?? '').toUpperCase().contains(_query);

  // ── Profile Expansion ────────────────────────────────────
  String? _profileOpenId;

  // ── Pending Registrations ────────────────────────────────
  List<PendingRegistration> _pendingRegistrations = [];

  /// Registration ids currently being approved/rejected — guards against
  /// a double-tap (or a fast second call before the first's disk I/O
  /// resolves) processing the same registration twice.
  final Set<String> _processingRegistrationIds = {};

  @override
  void initState() {
    super.initState();
    // PlayersPage is a StatefulShellRoute branch, so this State survives tab
    // switches — without this listener, registrations submitted from the
    // separate `/register` route would never show up.
    PendingRegistrationRepository.instance.listenable.addListener(
      _reloadPendingRegistrations,
    );
    _pendingRegistrations = PendingRegistrationRepository.instance
        .getAll()
        .toList();
    // PLY-12: profile stats come from saved games and logs, so rebuild when
    // a round is saved.
    GameRepository.instance.listenable.addListener(_onHistoryChanged);
    SessionLogRepository.instance.listenable.addListener(_onHistoryChanged);
  }

  void _onHistoryChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The scanner types into the search field, so it takes focus when the
    // tab opens. It gives focus up when the tab is hidden, so keys typed on
    // another tab do not land here.
    final active = TickerMode.valuesOf(context).enabled;
    if (active == _tabActive) return;
    _tabActive = active;
    if (active) {
      _focusSearchOnOpen(tries: 2);
    } else {
      _searchFocus.unfocus();
    }
  }

  /// Focuses the search field after the frame. Asked again on the next frame
  /// [tries] times, since the tap that opened the tab can move focus after
  /// the first ask.
  void _focusSearchOnOpen({required int tries}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_tabActive) return;
      final primary = FocusManager.instance.primaryFocus;
      if (!_searchFocus.hasFocus && primary?.context?.widget is! EditableText) {
        _searchFocus.requestFocus();
      }
      if (tries > 1) _focusSearchOnOpen(tries: tries - 1);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Gives the search field focus again, so the next scan has somewhere to
  /// go. Runs after the frame, when a closed dialog or profile has given up
  /// its focus. It does nothing when the tab is hidden, when another text
  /// field (the Sign In ID field) has focus, or when a dialog has focus.
  void _refocusSearch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_tabActive || _searchFocus.hasFocus) return;
      final primary = FocusManager.instance.primaryFocus;
      if (primary?.context?.widget is EditableText) return;
      if (primary != null && !FocusScope.of(context).hasFocus) return;
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    GameRepository.instance.listenable.removeListener(_onHistoryChanged);
    SessionLogRepository.instance.listenable.removeListener(_onHistoryChanged);
    PendingRegistrationRepository.instance.listenable.removeListener(
      _reloadPendingRegistrations,
    );
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _reloadPendingRegistrations() {
    if (!mounted) return;
    setState(() {
      _pendingRegistrations = PendingRegistrationRepository.instance
          .getAll()
          .toList();
    });
  }

  // ── Helpers ──────────────────────────────────────────────

  bool _isCheckedIn(Player player, GameData gameData) =>
      gameData.isPlayerCheckedIn(player);

  /// Move [player] up or down one [Elo] tier, then persist the change.
  void _adjustLevel(Player player, bool up) {
    const eloValues = Elo.values;
    final currentIndex = player.elo.index;
    final newIndex = up ? currentIndex + 1 : currentIndex - 1;

    if (newIndex < 0 || newIndex >= eloValues.length) return;

    final updated = player.copyWith(elo: eloValues[newIndex]);
    context.read<GameData>().onUpdatePlayer(updated);
  }

  /// Advances [player] to the next [MembershipStatus] (PLY-06). Disabling a
  /// player who is currently checked in requires confirmation, since it
  /// immediately checks them out (removed from court/waitlist, triggering
  /// WL-02 auto-promotion).
  Future<void> _onCycleMembership(Player player, GameData gameData) async {
    final next = player.membership.next;
    if (next == MembershipStatus.disabled &&
        gameData.isPlayerCheckedIn(player)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => const _ConfirmDisableDialog(),
      );
      _refocusSearch();
      if (confirmed != true) return;
    }
    gameData.setMembership(player, next);
  }

  /// Permanently removes [player] from the club roster (PLY-07), after
  /// confirmation. If currently checked in, they are checked out first
  /// (triggering WL-02 auto-promotion) as part of [GameData.deletePlayer].
  Future<void> _onDeletePlayer(Player player, GameData gameData) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDeleteDialog(playerName: player.name()),
    );
    _refocusSearch();
    if (confirmed != true) return;

    await gameData.deletePlayer(player);
    if (!mounted) return;
    setState(() => _profileOpenId = null);
    _refocusSearch();
    context.showToast(
      AppLocalizations.of(context)!.players_deleted_toast(player.name()),
    );
  }

  void _toggleCheckedIn(Player player, GameData gameData) {
    // A half-typed query is stale once the organizer picks a row.
    if (_searchController.text.isNotEmpty) {
      setState(_searchController.clear);
    }
    if (gameData.isPlayerCheckedIn(player)) {
      gameData.checkOutPlayer(player);
      return;
    }
    final refusal = _refusalMessage(gameData.checkInPlayer(player), player);
    if (refusal != null) _showSnackBar(refusal);
  }

  /// The row tap on desktop: the check-in toggle, then focus goes back to
  /// the scan field (PLY-14). The result box does not change (R3-Q3).
  void _toggleCheckedInDesktop(Player player, GameData gameData) {
    _toggleCheckedIn(player, gameData);
    _refocusSearch();
  }

  /// Why a check-in was refused, or `null` when it was not (R45-38).
  String? _refusalMessage(CheckInResult result, Player player) {
    final l10n = AppLocalizations.of(context)!;
    return switch (result) {
      CheckInResult.checkedIn => null,
      CheckInResult.disabled => l10n.players_scan_disabled(player.name()),
      CheckInResult.sessionFull => l10n.players_session_full_cannot_check_in,
    };
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (!_desktop) {
      messenger.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
      return;
    }
    // The bottom message (ARCHITECTURE §2.8): bottom-centre, 360 px wide.
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.body.copyWith(color: AppColors.headerText),
        ),
        backgroundColor: AppColors.headerBg,
        behavior: SnackBarBehavior.floating,
        width: 360,
        duration: const Duration(seconds: 2),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.lgRadius),
      ),
    );
  }

  // ── Scanner ──────────────────────────────────────────────

  /// The search field got Enter. A barcode scanner types the sign-in ID and
  /// then sends Enter (PLY-14). The player whose sign-in ID equals the text
  /// is the target, looked for over all listed players (F01). With no such
  /// ID, the one player in the list is the target. With no or many players
  /// nobody changes. The text stays and is selected, so the list still
  /// shows the result and the next scan replaces it; after MANY MATCHES on
  /// desktop the caret goes to the end instead (F19).
  ///
  /// Desktop shows the result in the result box; phone and tablet show it
  /// in a bottom message, as before (R6-Q7).
  void _onSearchSubmitted() {
    final typed = _searchController.text.trim();
    if (typed.isEmpty) return;

    final result = _scan(typed);
    if (_desktop) {
      setState(() => _scanResult = result);
    } else {
      _showSnackBar(_scanMessage(result));
    }
    if (_desktop && result.kind == ScanKind.manyMatches) {
      _caretToEnd();
    } else {
      _selectSearchText();
    }
  }

  /// Finds the target of a scan of [typed] and toggles its check-in.
  ScanResult _scan(String typed) {
    final wanted = typed.toLowerCase();
    // F01: the exact ID match runs over all listed players, so a level chip
    // or the search text never hides the scanned card. The chips stay.
    final exact = PlayerRepository.instance
        .listedPlayers()
        .where((p) => p.signInId?.trim().toLowerCase() == wanted)
        .toList();
    if (exact.length > 1) return ScanResult.duplicateId(typed, exact.length);
    if (exact.length == 1) return _toggleByScan(exact.single);

    final listed = _listedPlayers();
    if (listed.isEmpty) return ScanResult.notFound(typed);
    if (listed.length > 1) return ScanResult.manyMatches(typed, listed.length);
    return _toggleByScan(listed.single);
  }

  /// Checks [player] in or out for a scan. On desktop a scan of the player
  /// that the last scan checked in changes nothing (PLY-19).
  ScanResult _toggleByScan(Player player) {
    final gameData = context.read<GameData>();
    if (gameData.isPlayerCheckedIn(player)) {
      if (_desktop && _lastScanCheckInId == player.id) {
        return ScanResult.scannedTwice(player);
      }
      return _checkOutByScan(player, gameData);
    }
    return switch (gameData.checkInPlayer(player)) {
      CheckInResult.disabled => ScanResult.disabled(player),
      CheckInResult.sessionFull => ScanResult.sessionFull(
        player,
        checkedIn: gameData.checkedInCount,
        capacity: gameData.sessionCapacity,
      ),
      CheckInResult.checkedIn => () {
        _lastScanCheckInId = player.id;
        return ScanResult.checkedIn(player, round: gameData.waitsForRound);
      }(),
    };
  }

  ScanResult _checkOutByScan(Player player, GameData gameData) {
    final fills = gameData.checkOutPlayer(player);
    return ScanResult.checkedOut(player, fill: ScanResult.firstFill(fills));
  }

  /// "Check out" in the SCANNED TWICE box: the box then shows CHECKED OUT
  /// for that player, not READY (PLY-19, F20).
  void _onResultCheckOut() {
    final player = _scanResult.player;
    if (player == null) return;
    final gameData = context.read<GameData>();
    _lastScanCheckInId = null;
    setState(() {
      _scanResult = gameData.isPlayerCheckedIn(player)
          ? _checkOutByScan(player, gameData)
          : ScanResult.checkedOut(player);
    });
    _selectSearchText();
  }

  /// The bottom message of a scan on phone and tablet.
  String _scanMessage(ScanResult result) {
    final l10n = AppLocalizations.of(context)!;
    final name = result.player?.name() ?? '';
    return switch (result.kind) {
      ScanKind.duplicateId => l10n.players_scan_duplicate_id(
        result.text,
        result.count,
      ),
      ScanKind.notFound => l10n.players_scan_no_match(result.text),
      ScanKind.manyMatches => l10n.players_scan_many_matches(result.count),
      ScanKind.checkedOut => l10n.players_scan_checked_out(name),
      ScanKind.checkedIn => l10n.players_scan_checked_in(name),
      ScanKind.disabled => l10n.players_scan_disabled(name),
      ScanKind.sessionFull => l10n.players_session_full_cannot_check_in,
      // Phone and tablet have no guard, so no SCANNED TWICE.
      ScanKind.scannedTwice || ScanKind.ready => '',
    };
  }

  /// Keeps focus in the search field with the caret at the end and nothing
  /// selected, so the organizer can type more (MANY MATCHES, F19).
  void _caretToEnd() {
    void toEnd() => _searchController.selection = TextSelection.collapsed(
      offset: _searchController.text.length,
    );
    toEnd();
    _searchFocus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) toEnd();
    });
  }

  /// Esc anywhere on the tab gives focus back to the scan field (F21).
  KeyEventResult _onPageKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }
    _selectSearchText();
    return KeyEventResult.handled;
  }

  /// Keeps focus in the search field and selects all its text. It is done
  /// again after the frame, since a focus change can move the selection.
  void _selectSearchText() {
    void selectAll() => _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
    selectAll();
    _searchFocus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) selectAll();
    });
  }

  /// Saves a new sign-in ID for [player] (PLY-15). Returns an error message
  /// when the ID is already used by another listed player, otherwise saves
  /// it and returns null. Empty text means no ID. No other field changes.
  String? _onSaveSignInId(Player player, String text) {
    final l10n = AppLocalizations.of(context)!;
    final desktop = _desktop;
    final id = text.trim();
    if (id.isNotEmpty) {
      final taken = PlayerRepository.instance.listedPlayers().firstWhereOrNull(
        (p) =>
            p.id != player.id &&
            p.signInId?.trim().toLowerCase() == id.toLowerCase(),
      );
      if (taken != null) {
        return l10n.players_id_used_by(id, taken.name());
      }
    }
    context.read<GameData>().onUpdatePlayer(
      player.copyWith(signInId: id.isEmpty ? null : id),
    );
    // Desktop says "Saved." under the field (canvas board "Players · More
    // panel"); a bottom message is only for a refused row tap (R4-Q1).
    if (!desktop) _showSnackBar(l10n.players_sign_in_id_saved);
    return null;
  }

  // ── Profile Stats ────────────────────────────────────────

  /// Stats from persisted games and session logs (PLY-12) — synchronous
  /// reads of the repository caches.
  PlayerProfileStats _computeStats(Player player) => computePlayerProfileStats(
    player: player,
    games: GameRepository.instance.getAll(),
    logs: SessionLogRepository.instance.getAll(),
    roster: PlayerRepository.instance.listedPlayers(),
    l10n: AppLocalizations.of(context)!,
  );

  /// The players the list shows: the level filters and the search text
  /// applied, sorted by name.
  List<Player> _listedPlayers() {
    final activeEloFilters = _eloFilters.isEmpty
        ? Elo.values.toSet()
        : _eloFilters;
    bool levelShown(Player p) => _desktop
        ? _tierFilters.isEmpty || _tierFilters.contains(p.elo.skillTier)
        : activeEloFilters.contains(p.elo);
    return PlayerRepository.instance
        .listedPlayers()
        .where((p) => levelShown(p) && _matchesQuery(p))
        .sortedBy<String>((p) => p.name())
        .toList();
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gameData = context.watch<GameData>();
    _desktop = isDesktop(MediaQuery.sizeOf(context).width);

    final filteredPlayers = _listedPlayers();

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onPageKey,
      child: _desktop
          ? _buildDesktop(gameData, filteredPlayers)
          : _buildCompact(gameData, filteredPlayers),
    );
  }

  /// Phone and tablet: the PR 45 layout (R2-Q23, R6-Q7).
  Widget _buildCompact(GameData gameData, List<Player> filteredPlayers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Capacity Bar (CHK-01, CHK-04) ──────────────────
        CapacityBar(
          checkedIn: gameData.checkedInCount,
          capacity: gameData.sessionCapacity,
          remaining: gameData.remainingCapacity,
        ),
        const SizedBox(height: AppSpacing.md),

        // ── At-Capacity Banner (CHK-04) ────────────────────
        if (gameData.isAtCapacity) ...[
          const AtCapacityBanner(),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Pending Registrations ─────────────────────────
        if (_pendingRegistrations.isNotEmpty) ...[
          PendingRegistrationCard(
            pendingRegistrations: _pendingRegistrations,
            processingIds: _processingRegistrationIds,
            onApprove: (i) => _onApproveRegistration(i),
            onReject: (i) => _onRejectRegistration(i),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── Search + Actions Bar ──────────────────────────
        _SearchAndActionsBar(
          searchController: _searchController,
          searchFocus: _searchFocus,
          onSearchSubmitted: _onSearchSubmitted,
          onTapOutside: _refocusSearch,
          showImport: widget.showImportButton,
          onSearchChanged: () => setState(() {}),
          eloFilters: _eloFilters,
          onEloFilterToggled: _onEloFilterToggled,
          onAddPlayer: _onAddPlayer,
          onImportCsv: _onImportCsv,
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Table Header (hidden on phone) ──────────────
        Builder(
          builder: (context) {
            if (isPhone(MediaQuery.sizeOf(context).width)) {
              return const SizedBox.shrink();
            }
            return _TableHeader();
          },
        ),
        const SizedBox(height: 4),

        // ── Player List ───────────────────────────────────
        Expanded(
          child: filteredPlayers.isEmpty
              ? Center(
                  child: Text(
                    _query.isEmpty
                        ? AppLocalizations.of(context)!.players_no_players_yet
                        : AppLocalizations.of(
                            context,
                          )!.players_no_players_matching(_query),
                    style: const TextStyle(
                      fontFamily: AppTypography.family,
                      fontSize: AppTypography.sizeBody,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredPlayers.length,
                  itemBuilder: (context, index) {
                    final player = filteredPlayers[index];
                    final isExpanded = _profileOpenId == player.id;
                    final item = Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlayerRow(
                          player: player,
                          isExpanded: isExpanded,
                          membership: player.membership,
                          isCheckedIn: _isCheckedIn(player, gameData),
                          onToggleProfile: () => _toggleProfile(player.id),
                          onLevelUp: () => _adjustLevel(player, true),
                          onLevelDown: () => _adjustLevel(player, false),
                          onCycleMembership: () =>
                              _onCycleMembership(player, gameData),
                          onToggleCheckin: () =>
                              _toggleCheckedIn(player, gameData),
                        ),
                        if (isExpanded)
                          PlayerProfileCard(
                            player: player,
                            stats: _computeStats(player),
                            membership: player.membership,
                            onClose: () => _toggleProfile(player.id),
                            onDelete: () => _onDeletePlayer(player, gameData),
                            onSaveSignInId: (text) =>
                                _onSaveSignInId(player, text),
                          ),
                      ],
                    );
                    if (!isExpanded) return item;

                    // An open row and its profile share one rounded panel,
                    // so the corners of the row match the profile.
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: AppCard(
                        key: const Key('player-accordion-panel'),
                        padding: EdgeInsets.zero,
                        borderRadius: AppRadii.lgRadius,
                        // The green bar of a checked-in row runs down the
                        // open profile too.
                        child: Stack(
                          children: [
                            item,
                            if (_isCheckedIn(player, gameData) &&
                                player.membership != MembershipStatus.disabled)
                              const Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: PlayerRow.barWidth,
                                child: ColoredBox(
                                  key: Key('player-panel-bar'),
                                  color: AppColors.deltaPositive,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Desktop (IMPLEMENTATION 8.7): the scan field, the result box, the
  /// banner and the pending card, the tier chips, the table.
  Widget _buildDesktop(GameData gameData, List<Player> players) {
    final l10n = AppLocalizations.of(context)!;
    const gap = SizedBox(height: 10);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopScanBar(
          controller: _searchController,
          focusNode: _searchFocus,
          onSubmitted: _onSearchSubmitted,
          onTapOutside: _refocusSearch,
          onChanged: () => setState(() {}),
          checkedIn: gameData.checkedInCount,
          capacity: gameData.sessionCapacity,
          remaining: gameData.remainingCapacity,
          onAddPlayer: _onAddPlayer,
          onImport: widget.showImportButton ? _onImportCsv : null,
        ),
        gap,
        ScanResultBox(result: _scanResult, onCheckOut: _onResultCheckOut),
        if (gameData.isAtCapacity) ...[gap, const AtCapacityBanner()],
        if (_pendingRegistrations.isNotEmpty) ...[
          gap,
          PendingRegistrationCard(
            desktop: true,
            pendingRegistrations: _pendingRegistrations,
            processingIds: _processingRegistrationIds,
            onApprove: (i) => _onApproveRegistration(i),
            onReject: (i) => _onRejectRegistration(i),
          ),
        ],
        gap,
        _TierChips(selected: _tierFilters, onToggle: _onTierToggled),
        gap,
        const Padding(
          padding: EdgeInsets.only(right: _scrollBarGutter),
          child: DesktopPlayerTableHeader(),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: players.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    _query.isEmpty
                        ? l10n.players_no_players_yet
                        : l10n.players_no_players_matching(
                            _searchController.text.trim(),
                          ),
                    style: AppTypography.body.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              : ListView.separated(
                  // The desktop scroll bar draws over the right edge of the
                  // list; the gutter keeps it off the rows.
                  padding: const EdgeInsets.only(right: _scrollBarGutter),
                  itemCount: players.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) =>
                      _desktopItem(players[index], gameData),
                ),
        ),
      ],
    );
  }

  Widget _desktopItem(Player player, GameData gameData) {
    final expanded = _profileOpenId == player.id;
    final checkedIn = _isCheckedIn(player, gameData);
    Widget row({bool inPanel = false}) => DesktopPlayerRow(
      player: player,
      isCheckedIn: checkedIn,
      isExpanded: expanded,
      inPanel: inPanel,
      onToggleCheckin: () => _toggleCheckedInDesktop(player, gameData),
      onToggleMore: () => _toggleProfile(player.id),
    );
    if (!expanded) return row();

    final green = checkedIn && player.membership != MembershipStatus.disabled;
    // The row and its panel sit in one rounded panel (PLY-09).
    return DecoratedBox(
      key: const Key('player-accordion-panel'),
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AppRadii.mdRadius,
        border: Border.all(
          color: green ? AppColors.success : AppColors.cardBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppRadii.mdRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            row(inPanel: true),
            MorePanel(
              player: player,
              stats: _computeStats(player),
              onLevelDown: () => _adjustLevel(player, false),
              onLevelUp: () => _adjustLevel(player, true),
              onMembership: (status) =>
                  _onPickMembership(player, status, gameData),
              onDelete: () => _onDeletePlayerDesktop(player, gameData),
              onClose: () => _toggleProfile(player.id),
              onSaveSignInId: (text) => _onSaveSignInId(player, text),
            ),
          ],
        ),
      ),
    );
  }

  void _onTierToggled(SkillTier tier) {
    setState(() {
      if (!_tierFilters.remove(tier)) _tierFilters.add(tier);
    });
    _refocusSearch();
  }

  /// A membership segment in the More panel (PLY-06). Disabled for a
  /// checked-in player asks first, then checks the player out (F23).
  Future<void> _onPickMembership(
    Player player,
    MembershipStatus status,
    GameData gameData,
  ) async {
    if (status == player.membership) return;
    if (status == MembershipStatus.disabled &&
        gameData.isPlayerCheckedIn(player)) {
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await showCourtsConfirm(
        context,
        title: l10n.players_disable_confirm_title(player.name()),
        body: l10n.players_disable_confirm_body(player.name()),
        cancelLabel: l10n.cancel,
        actionLabel: l10n.players_disable,
        closeOnPhaseChange: false,
      );
      _refocusSearch();
      if (!confirmed || !mounted) return;
    }
    gameData.setMembership(player, status);
    _refocusSearch();
  }

  /// Delete in the More panel (PLY-07), with the one confirm dialog of the
  /// desktop build (F14). No bottom message after it (R4-Q1).
  Future<void> _onDeletePlayerDesktop(Player player, GameData gameData) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showCourtsConfirm(
      context,
      title: l10n.players_delete_player_title,
      body: l10n.players_delete_player_body(player.name()),
      cancelLabel: l10n.cancel,
      actionLabel: l10n.delete,
      closeOnPhaseChange: false,
    );
    _refocusSearch();
    if (!confirmed) return;
    await gameData.deletePlayer(player);
    if (!mounted) return;
    setState(() => _profileOpenId = null);
    _refocusSearch();
  }

  // ── Actions ──────────────────────────────────────────────

  void _toggleProfile(String playerId) {
    setState(() {
      _profileOpenId = _profileOpenId == playerId ? null : playerId;
    });
    _refocusSearch();
  }

  void _onEloFilterToggled(Elo elo, bool selected) {
    setState(() {
      if (selected) {
        _eloFilters.add(elo);
        // When all filters are selected, treat as "show all" (empty set)
        if (_eloFilters.length == Elo.values.length) {
          _eloFilters = {};
        }
      } else {
        _eloFilters.remove(elo);
        // When all are removed from a "show all" state, add all except this one
        if (_eloFilters.isEmpty) {
          _eloFilters = Elo.values.toSet()..remove(elo);
        }
      }
    });
  }

  Future<void> _onAddPlayer() async {
    // The dialog closes itself and hands the new player back through this
    // future. Popping from here would target this tab's Navigator, not the
    // dialog's — see AddPlayerDialog.
    final result = await showDialog<Player>(
      context: context,
      builder: (_) => const AddPlayerDialog(),
    );
    _refocusSearch();
    if (result == null) return;

    await PlayerRepository.instance.add(result);
    if (!mounted) return;
    setState(() {
      // Refresh is handled by the repository cache; rebuild to show new player
    });
  }

  Future<void> _onImportCsv() async {
    final records = await importFromCsv(
      dialogTitle: AppLocalizations.of(context)!.players_select_import_file,
    );
    if (!mounted || records.isEmpty) return;

    final gameData = context.read<GameData>();
    final existingPlayersName = {
      for (final player in gameData.checkedInPlayers.values)
        player.name(): player,
    };
    final cachedPlayers = PlayerRepository.instance.listedPlayers();
    for (final p in cachedPlayers) {
      existingPlayersName[p.name()] = p;
    }

    final parsedNames = {
      for (final parsedName in records) parsedName.name(): parsedName,
    };
    if (parsedNames.length != records.length) {
      if (mounted) {
        context.showErrorToast(
          AppLocalizations.of(context)!.players_duplicate_name_in_file,
        );
      }
      return;
    }

    final duplicateNames = parsedNames.keys.toSet().intersection(
      existingPlayersName.keys.toSet(),
    );
    if (duplicateNames.isNotEmpty) {
      if (mounted) {
        context.showErrorToast(
          AppLocalizations.of(
            context,
          )!.players_conflict_existing_names(duplicateNames.join(', ')),
        );
      }
      return;
    }

    final newPlayers = parsedNames.keys
        .where((name) => !duplicateNames.contains(name))
        .map(
          (name) => Player.create(
            firstName: parsedNames[name]!.firstName,
            lastName: parsedNames[name]!.lastName,
            elo: parsedNames[name]!.elo ?? Elo.c2,
          ),
        );

    final bool? confirmedSelection = await showAdaptiveDialog<bool?>(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          PlayerBulkEdit(players: newPlayers.toList(growable: false)),
    );
    _refocusSearch();
    if (confirmedSelection != true) return;
    if (!mounted) return;

    try {
      await PlayerRepository.instance.addAll(newPlayers);
    } catch (_) {
      if (mounted) {
        context.showErrorToast(
          AppLocalizations.of(context)!.players_import_failed,
        );
      }
      return;
    }
    setState(() {});
  }

  Future<void> _onApproveRegistration(int index) async {
    if (index < 0 || index >= _pendingRegistrations.length) return;
    final reg = _pendingRegistrations[index];
    // Resolved by id (not index) below, and guarded against a second call
    // for the same registration racing in before this one finishes.
    if (!_processingRegistrationIds.add(reg.id)) return;
    setState(() {});

    try {
      // Split full name into parts — default lastName if single word.
      // Collapse repeated internal whitespace so e.g. "Jane  Doe" doesn't
      // produce a lastName with a stray leading space.
      final nameParts = reg.name.trim().split(RegExp(r'\s+'));
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';
      final fullName = '$firstName $lastName';

      final existingNames = {
        for (final p in PlayerRepository.instance.listedPlayers()) p.name(),
      };
      if (existingNames.contains(fullName)) {
        if (mounted) {
          context.showToast(
            AppLocalizations.of(context)!.players_already_exists(fullName),
          );
        }
        return;
      }

      final newPlayer = Player.create(
        firstName: firstName,
        lastName: lastName,
        elo: reg.tier.lowerBoundElo,
        membership: MembershipStatus.casual,
      );

      try {
        await PlayerRepository.instance.add(newPlayer);
        // Removes reg from _pendingRegistrations via _reloadPendingRegistrations.
        await PendingRegistrationRepository.instance.delete(reg.id);
      } catch (_) {
        if (mounted) {
          context.showToast(
            AppLocalizations.of(context)!.players_approve_failed(reg.name),
          );
        }
        return;
      }

      if (!mounted) return;
      context.showToast(
        AppLocalizations.of(context)!.players_approved_toast(reg.name),
      );
    } finally {
      _processingRegistrationIds.remove(reg.id);
    }
  }

  Future<void> _onRejectRegistration(int index) async {
    if (index < 0 || index >= _pendingRegistrations.length) return;
    final reg = _pendingRegistrations[index];
    if (!_processingRegistrationIds.add(reg.id)) return;
    setState(() {});

    try {
      // Removes reg from _pendingRegistrations via _reloadPendingRegistrations.
      await PendingRegistrationRepository.instance.delete(reg.id);
      if (!mounted) return;
      context.showToast(
        AppLocalizations.of(context)!.players_rejected_toast(reg.name),
      );
    } finally {
      _processingRegistrationIds.remove(reg.id);
    }
  }
}

// ── Sub-widgets ────────────────────────────────────────────

/// The 4 tier chips of desktop (R6-Q13): a chip that is on shows its tier;
/// with no chip on every tier shows. Chip border `#8f826e`.
class _TierChips extends StatelessWidget {
  const _TierChips({required this.selected, required this.onToggle});

  final Set<SkillTier> selected;
  final ValueChanged<SkillTier> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      label: l10n.players_filter_by_level,
      explicitChildNodes: true,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final tier in SkillTier.values)
            _TierChip(
              key: Key('tier-chip-${tier.name}'),
              label: tier.localizedLabel(l10n),
              on: selected.contains(tier),
              onTap: () => onToggle(tier),
            ),
        ],
      ),
    );
  }
}

class _TierChip extends StatefulWidget {
  const _TierChip({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  State<_TierChip> createState() => _TierChipState();
}

class _TierChipState extends State<_TierChip> {
  bool _focused = false;

  static const _shape = BorderRadius.all(Radius.circular(16));

  @override
  Widget build(BuildContext context) {
    final on = widget.on;
    return Semantics(
      container: true,
      button: true,
      toggled: on,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: FocusRing(
        focused: _focused,
        color: AppColors.focusOnLight,
        radius: 16,
        child: Material(
          color: on ? AppColors.textPrimary : AppColors.pageBg,
          shape: RoundedRectangleBorder(
            borderRadius: _shape,
            side: BorderSide(
              color: on ? AppColors.textPrimary : AppColors.controlBorderSoft,
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: _shape,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: AppTypography.button.copyWith(
                      color: on ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Search input + Elo filter chips + Add/Import buttons.
class _SearchAndActionsBar extends StatelessWidget {
  const _SearchAndActionsBar({
    required this.searchController,
    required this.searchFocus,
    required this.onSearchSubmitted,
    required this.onTapOutside,
    required this.showImport,
    required this.onSearchChanged,
    required this.eloFilters,
    required this.onEloFilterToggled,
    required this.onAddPlayer,
    required this.onImportCsv,
  });

  final TextEditingController searchController;
  final FocusNode searchFocus;
  final VoidCallback onSearchSubmitted;
  final VoidCallback onTapOutside;
  final bool showImport;
  final VoidCallback onSearchChanged;
  final Set<Elo> eloFilters;
  final void Function(Elo elo, bool selected) onEloFilterToggled;
  final VoidCallback onAddPlayer;
  final VoidCallback onImportCsv;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search + action buttons
        Row(
          children: [
            Expanded(
              // A scanner sends Enter after the ID. Some platforms deliver it
              // as the key, others as the done action; the page handles both.
              child: Focus(
                onKeyEvent: (_, event) {
                  // Enter confirms an IME composition; it is not a scan.
                  final composing = searchController.value.composing;
                  if (composing.isValid && !composing.isCollapsed) {
                    return KeyEventResult.ignored;
                  }
                  final isEnter =
                      event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.numpadEnter;
                  if (isEnter && event is KeyDownEvent) {
                    onSearchSubmitted();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: AppSearchInput(
                  controller: searchController,
                  focusNode: searchFocus,
                  onSubmitted: (_) => onSearchSubmitted(),
                  onTapOutside: (_) => onTapOutside(),
                  onChanged: (_) => onSearchChanged(),
                  placeholder: l10n.players_search_placeholder,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _ActionButton(
              label: l10n.add,
              icon: Icons.person_add_rounded,
              onTap: onAddPlayer,
            ),
            if (showImport) ...[
              const SizedBox(width: AppSpacing.xs),
              _ActionButton(
                label: l10n.players_import,
                icon: Icons.upload_file_rounded,
                onTap: onImportCsv,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Elo filter chips
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: Elo.values
              .map((elo) {
                final isSelected =
                    eloFilters.isEmpty || eloFilters.contains(elo);
                return AppChip(
                  label: elo.toDisplayName(),
                  isSelected: isSelected,
                  onTap: () => onEloFilterToggled(elo, !isSelected),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

/// Compact action button for the search bar row.
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.pillBg,
            borderRadius: AppRadii.mdRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.textPrimary),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.buttonSm.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fixed table header row matching the [PlayerRow] column layout.
class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      // Lines up with the row: its 1px border, accent bar and padding on
      // the left, its border and padding on the right.
      padding: const EdgeInsets.fromLTRB(1 + PlayerRow.nameInset, 6, 1 + 12, 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: _HeaderLabel(l10n.players_header_name_id)),
          const SizedBox(width: AppSpacing.md),
          SizedBox(width: 155, child: _HeaderLabel(l10n.players_level)),
          const SizedBox(width: AppSpacing.md),
          SizedBox(width: 88, child: _HeaderLabel(l10n.players_membership)),
          const SizedBox(width: AppSpacing.sm + PlayerRow.moreColumnWidth),
        ],
      ),
    );
  }
}

/// Uppercase table header cell — 11px, 700, subtle colour.
class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: AppTypography.family,
        fontSize: AppTypography.sizeCaption,
        fontWeight: AppTypography.semibold,
        color: AppColors.textMuted,
      ),
    );
  }
}

/// Confirms disabling a checked-in player (PLY-06), since it immediately
/// checks them out and removes them from their court/waitlist.
class _ConfirmDisableDialog extends StatelessWidget {
  const _ConfirmDisableDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        l10n.players_disable_player_title,
        style: AppTypography.cardTitle,
      ),
      content: Text(
        l10n.players_disable_player_body,
        style: AppTypography.body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.players_disable),
        ),
      ],
    );
  }
}

/// Confirms permanently deleting a player from the club roster (PLY-07).
class _ConfirmDeleteDialog extends StatelessWidget {
  const _ConfirmDeleteDialog({required this.playerName});

  final String playerName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        l10n.players_delete_player_title,
        style: AppTypography.cardTitle,
      ),
      content: Text(
        l10n.players_delete_player_body(playerName),
        style: AppTypography.body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.warningText),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}

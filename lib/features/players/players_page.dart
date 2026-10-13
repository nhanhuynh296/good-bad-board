import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:good_bad_board/core/importer.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/players/capacity_bar.dart';
import 'package:good_bad_board/features/players/player_profile_card.dart';
import 'package:good_bad_board/features/players/player_profile_stats.dart';
import 'package:good_bad_board/features/players/player_row.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
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

class _PlayersPageState extends State<PlayersPage> {
  // ── Search & Filter ──────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  /// Whether this tab is the one on screen. The shell keeps hidden tabs
  /// alive, so a change of this value is how the page knows it was opened.
  bool _tabActive = false;

  Set<Elo> _eloFilters = {};

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
    } else if (!gameData.checkInPlayer(player)) {
      _showSnackBar(
        AppLocalizations.of(context)!.players_session_full_cannot_check_in,
      );
    }
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // ── Scanner ──────────────────────────────────────────────

  /// The search field got Enter. A barcode scanner types the sign-in ID and
  /// then sends Enter. The one listed player is checked in or out (a player
  /// whose sign-in ID equals the text wins over longer IDs that contain
  /// it). With no or many listed players nobody changes. The text always
  /// stays and is selected, so the list still shows the result and the next
  /// scan replaces the text.
  void _onSearchSubmitted() {
    final typed = _searchController.text.trim();
    if (typed.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final listed = _listedPlayers();
    final wanted = typed.toLowerCase();
    final exact = listed
        .where((p) => p.signInId?.trim().toLowerCase() == wanted)
        .toList();

    final String message;
    if (exact.length > 1) {
      message = l10n.players_scan_duplicate_id(typed, exact.length);
    } else if (exact.isEmpty && listed.isEmpty) {
      message = l10n.players_scan_no_match(typed);
    } else if (exact.isEmpty && listed.length > 1) {
      message = l10n.players_scan_many_matches(listed.length);
    } else {
      message = _toggleByScan(exact.isEmpty ? listed.single : exact.single);
    }
    _showSnackBar(message);
    _selectSearchText();
  }

  /// Checks [player] in or out for a scan and returns the message to show.
  String _toggleByScan(Player player) {
    final l10n = AppLocalizations.of(context)!;
    final gameData = context.read<GameData>();
    if (player.membership == MembershipStatus.disabled) {
      return l10n.players_scan_disabled(player.name());
    }
    if (gameData.isPlayerCheckedIn(player)) {
      gameData.checkOutPlayer(player);
      return l10n.players_scan_checked_out(player.name());
    }
    if (gameData.checkInPlayer(player)) {
      return l10n.players_scan_checked_in(player.name());
    }
    return l10n.players_session_full_cannot_check_in;
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
    final id = text.trim();
    if (id.isNotEmpty) {
      final taken = PlayerRepository.instance.listedPlayers().firstWhereOrNull(
        (p) =>
            p.id != player.id &&
            p.signInId?.trim().toLowerCase() == id.toLowerCase(),
      );
      if (taken != null) {
        return l10n.players_sign_in_id_taken(id, taken.name());
      }
    }
    context.read<GameData>().onUpdatePlayer(
      player.copyWith(signInId: id.isEmpty ? null : id),
    );
    _showSnackBar(l10n.players_sign_in_id_saved);
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
    return PlayerRepository.instance
        .listedPlayers()
        .where((p) => activeEloFilters.contains(p.elo) && _matchesQuery(p))
        .sortedBy<String>((p) => p.name())
        .toList();
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gameData = context.watch<GameData>();

    final filteredPlayers = _listedPlayers();

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
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSubtle,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredPlayers.length,
                  itemBuilder: (context, index) {
                    final player = filteredPlayers[index];
                    final isExpanded = _profileOpenId == player.id;
                    final canCheckIn =
                        player.membership != MembershipStatus.disabled;

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
                          onToggleCheckin: canCheckIn
                              ? () => _toggleCheckedIn(player, gameData)
                              : null,
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
                            if (_isCheckedIn(player, gameData) && canCheckIn)
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
      padding: const EdgeInsets.fromLTRB(
        1 + PlayerRow.barWidth + 12 + PlayerRow.leadingWidth,
        6,
        1 + 12,
        6,
      ),
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
        fontFamily: AppTypography.bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSubtle,
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

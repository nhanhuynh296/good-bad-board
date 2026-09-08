import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/core/importer.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/players/capacity_bar.dart';
import 'package:good_bad_board/features/players/player_profile_card.dart';
import 'package:good_bad_board/features/players/player_row.dart';
import 'package:good_bad_board/features/players/pending_registration.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/pending_registration.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/pending_registration_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
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
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  // ── Search & Filter ──────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  Set<Elo> _eloFilters = {};

  String get _query => _searchController.text.toUpperCase();

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
  }

  @override
  void dispose() {
    PendingRegistrationRepository.instance.listenable.removeListener(
      _reloadPendingRegistrations,
    );
    _searchController.dispose();
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
    if (confirmed != true) return;

    await gameData.deletePlayer(player);
    if (!mounted) return;
    setState(() => _profileOpenId = null);
    context.showToast('${player.name()} deleted');
  }

  void _toggleCheckedIn(Player player, GameData gameData) {
    if (gameData.isPlayerCheckedIn(player)) {
      gameData.checkOutPlayer(player);
    } else {
      final success = gameData.checkInPlayer(player);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session at capacity — cannot check in'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ── Profile Stats ────────────────────────────────────────

  /// Compute [PlayerProfileStats] for the given player from [GameData]
  /// history. Returns a default/empty stats object when no history exists.
  PlayerProfileStats _computeStats(Player player, GameData gameData) {
    // Early exit when no history exists — skip the full scan.
    if (gameData.history.isEmpty) {
      return const PlayerProfileStats(
        matchCount: 0,
        uniquePartnerCount: 0,
        levelHistory: [],
        topPartners: [],
        attendanceSummary: 'No session data yet',
      );
    }

    // Collect all games the player participated in
    final allGames = gameData.history
        .expand((g) => g)
        .where((g) => g.players.any((p) => p.id == player.id))
        .toList();

    final matchCount = allGames.length;

    // Unique partners
    final partnerIds = <String>{};
    for (final game in allGames) {
      for (final p in game.players) {
        if (p.id != player.id) {
          partnerIds.add(p.id);
        }
      }
    }

    // Top partners
    final partnerCounts = <String, int>{};
    for (final game in allGames) {
      for (final p in game.players) {
        if (p.id != player.id) {
          partnerCounts[p.name()] = (partnerCounts[p.name()] ?? 0) + 1;
        }
      }
    }
    final topPartners = partnerCounts.entries
        .sortedBy<num>((e) => -e.value)
        .take(5)
        .map((e) => PartnerEntry(e.key, e.value))
        .toList();

    // Level history from games (ordered by game order)
    final levelHistory = allGames.map((g) {
      final selfInGame = g.players.firstWhere((p) => p.id == player.id);
      return selfInGame.elo;
    }).toList();

    // Attendance summary
    final sessionCount = gameData.history.length;
    final attendedSessions = gameData.history
        .where(
          (round) => round.any((g) {
            return g.players.any((p) => p.id == player.id);
          }),
        )
        .length;
    final attendanceSummary = sessionCount > 0
        ? 'Attended $attendedSessions of $sessionCount sessions'
        : 'No session data yet';

    return PlayerProfileStats(
      matchCount: matchCount,
      uniquePartnerCount: partnerIds.length,
      levelHistory: levelHistory,
      topPartners: topPartners,
      attendanceSummary: attendanceSummary,
    );
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gameData = context.watch<GameData>();

    final allPlayers = PlayerRepository.instance.listedPlayers().toList();
    final activeEloFilters = _eloFilters.isEmpty
        ? Elo.values.toSet()
        : _eloFilters;

    // Apply filters
    final filteredPlayers = allPlayers
        .where(
          (p) =>
              activeEloFilters.contains(p.elo) &&
              (p.name().toUpperCase().contains(_query) ||
                  p.elo.name.toUpperCase().contains(_query) ||
                  (p.signInId?.toUpperCase().contains(_query) ?? false)),
        )
        .sortedBy<String>((p) => p.name())
        .toList();

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
          onSearchChanged: () => setState(() {}),
          eloFilters: _eloFilters,
          onEloFilterToggled: _onEloFilterToggled,
          onAddPlayer: _onAddPlayer,
          onImportCsv: _onImportCsv,
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Table Header (hidden on phone) ──────────────
        LayoutBuilder(
          builder: (context, constraints) {
            if (isPhone(constraints.maxWidth)) {
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
                        ? 'No players added yet'
                        : 'No players matching "$_query"',
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

                    return Column(
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
                              ? (_) => _toggleCheckedIn(player, gameData)
                              : null,
                        ),
                        if (isExpanded)
                          PlayerProfileCard(
                            player: player,
                            stats: _computeStats(player, gameData),
                            membership: player.membership,
                            onClose: () => _toggleProfile(player.id),
                            onDelete: () => _onDeletePlayer(player, gameData),
                          ),
                      ],
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
    if (result == null) return;

    await PlayerRepository.instance.add(result);
    if (!mounted) return;
    setState(() {
      // Refresh is handled by the repository cache; rebuild to show new player
    });
  }

  Future<void> _onImportCsv() async {
    final records = await importFromCsv();
    if (!mounted || records.isEmpty) return;

    final gameData = context.read<GameData>();
    final existingPlayersName = {
      for (final player in gameData.checkedInPlayers.values) player.name(): player,
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
        context.showErrorToast('Duplicate name found in file');
      }
      return;
    }

    final duplicateNames = parsedNames.keys.toSet().intersection(
      existingPlayersName.keys.toSet(),
    );
    if (duplicateNames.isNotEmpty) {
      if (mounted) {
        context.showErrorToast(
          "Conflict name with existing player: ${duplicateNames.join(', ')}",
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
    if (confirmedSelection != true) return;
    if (!mounted) return;

    try {
      await PlayerRepository.instance.addAll(newPlayers);
    } catch (_) {
      if (mounted) {
        context.showErrorToast('Failed to import players — try again');
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
        for (final p in PlayerRepository.instance.listedPlayers())
          p.name(),
      };
      if (existingNames.contains(fullName)) {
        if (mounted) {
          context.showToast('A player named "$fullName" already exists');
        }
        return;
      }

      final newPlayer = Player.create(
        firstName: firstName,
        lastName: lastName,
        elo: reg.tier.lowerBoundElo,
      );

      try {
        await PlayerRepository.instance.add(newPlayer);
        // Removes reg from _pendingRegistrations via _reloadPendingRegistrations.
        await PendingRegistrationRepository.instance.delete(reg.id);
      } catch (_) {
        if (mounted) {
          context.showToast('Failed to approve ${reg.name}');
        }
        return;
      }

      if (!mounted) return;
      context.showToast('${reg.name} has been approved');
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
      context.showToast('${reg.name} has been rejected');
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
    required this.onSearchChanged,
    required this.eloFilters,
    required this.onEloFilterToggled,
    required this.onAddPlayer,
    required this.onImportCsv,
  });

  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final Set<Elo> eloFilters;
  final void Function(Elo elo, bool selected) onEloFilterToggled;
  final VoidCallback onAddPlayer;
  final VoidCallback onImportCsv;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search + action buttons
        Row(
          children: [
            Expanded(
              child: AppSearchInput(
                controller: searchController,
                onChanged: (_) => onSearchChanged(),
                placeholder: 'Search players…',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _ActionButton(
              label: 'Add',
              icon: Icons.person_add_rounded,
              onTap: onAddPlayer,
            ),
            const SizedBox(width: AppSpacing.xs),
            _ActionButton(
              label: 'Import',
              icon: Icons.upload_file_rounded,
              onTap: onImportCsv,
            ),
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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: _HeaderLabel('Name / ID')),
          SizedBox(width: AppSpacing.md),
          SizedBox(width: 155, child: _HeaderLabel('Level')),
          SizedBox(width: AppSpacing.md),
          SizedBox(width: 88, child: _HeaderLabel('Membership')),
          SizedBox(width: AppSpacing.sm),
          SizedBox(width: 76, child: _HeaderLabel('Checked in')),
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
    return AlertDialog(
      title: const Text('Disable player?', style: AppTypography.cardTitle),
      content: const Text(
        "They'll be checked out and removed from their court or the "
        'waitlist immediately.',
        style: AppTypography.body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Disable'),
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
    return AlertDialog(
      title: const Text('Delete player?', style: AppTypography.cardTitle),
      content: Text(
        "Remove $playerName from the club roster? This can't be undone.",
        style: AppTypography.body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.warningText),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

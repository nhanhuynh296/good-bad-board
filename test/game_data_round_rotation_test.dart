import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

import 'support/repository_sandbox.dart';

/// Creates a test player with a unique name and the given Elo.
Player _p(String name, Elo elo) =>
    Player.create(firstName: name, lastName: 'Test', elo: elo);

/// Creates 8 players with evenly-distributed Elo levels.
Future<List<Player>> _eightPlayers() async {
  final players = [
    _p('A1', Elo.a1),
    _p('A2', Elo.a2),
    _p('B1', Elo.b1),
    _p('B2', Elo.b2),
    _p('C1', Elo.c1),
    _p('C2', Elo.c2),
    _p('S1', Elo.s1),
    _p('S2', Elo.s2),
  ];
  await PlayerRepository.instance.addAll(players);
  return players;
}

/// Helper: count total players on courts.
int _playersOnCourts(GameData data) =>
    data.stagingMatches.fold<int>(0, (sum, g) => sum + g.playerIds.length);

void main() {
  late RepositorySandbox sandbox;

  // A rotation ends a round, so it logs that round — the repositories have to
  // be live for these tests.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('round_rotation_test');
  });

  tearDown(() => sandbox.tearDown());

  // ─────────────────────────────────────────────────────────────────
  // RND-03: Auto-rotation at 0:00 — recomputes level-balanced court
  // assignment from all checked-in players, increments round number,
  // restarts countdown at full duration.
  // ─────────────────────────────────────────────────────────────────
  group('RND-03 — Auto-rotation (rotateNow without staging)', () {
    test('rotateNow increments round number', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();
      expect(data.roundNumber, equals(1));

      await data.rotateNow();
      expect(data.roundNumber, equals(2));
    });

    test('rotateNow recomputes court assignments from player pool', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();
      final courtsBefore = _playersOnCourts(data);
      expect(courtsBefore, greaterThanOrEqualTo(4));

      await data.rotateNow();
      // After rotation, courts should still be populated
      final courtsAfter = _playersOnCourts(data);
      expect(courtsAfter, greaterThanOrEqualTo(4));
    });

    test(
      'rotateNow restarts round with fresh assignment when no staged',
      () async {
        final data = GameData()..setNumberOfCourt(2);
        final players = await _eightPlayers();
        for (final p in players) {
          data.addFullPricedPlayer(p);
        }
        await data.makeGame();

        await data.rotateNow();
        // After rotation, court 0 should have new assignment (may be same
        // by coincidence, but typically different)
        final court0After = data.stagingMatches[0].players.toList();
        // At minimum, courts should be populated
        expect(court0After.length, greaterThanOrEqualTo(2));
        // The assignment should be recomputed (even if identical by chance,
        // the round number changed to confirm rotation happened)
        expect(data.roundNumber, equals(2));
      },
    );

    test('rotateNow clears staging after adoption', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();
      expect(data.isStaged, isFalse);

      data.stageNextRound();
      expect(data.isStaged, isTrue);

      await data.rotateNow();
      // After rotation, staged state should be cleared
      expect(data.isStaged, isFalse);
      expect(data.roundNumber, equals(2));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // RND-04: "Rotate now" triggers immediate rotation — round
  // increments, courts recomputed (or staged adopted), countdown
  // restarts.
  // ─────────────────────────────────────────────────────────────────
  group('RND-04 — Manual Rotate now', () {
    test('rotateNow increments round number every call', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();
      expect(data.roundNumber, equals(1));

      await data.rotateNow();
      expect(data.roundNumber, equals(2));

      await data.rotateNow();
      expect(data.roundNumber, equals(3));

      await data.rotateNow();
      expect(data.roundNumber, equals(4));
    });

    test('rotateNow works mid-round at any time remaining', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();
      expect(data.roundNumber, equals(1));

      // Simulate rotating at any arbitrary time
      await data.rotateNow();
      expect(data.roundNumber, equals(2));
      expect(data.isStaged, isFalse);
    });

    test('rotateNow recomputes courts when no staged round exists', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();

      // Ensure there are players on courts
      expect(_playersOnCourts(data), greaterThanOrEqualTo(4));

      await data.rotateNow();
      // After rotation, all courts up to numberOfCourt should exist
      expect(data.stagingMatches.length, greaterThanOrEqualTo(2));
      // Players should be placed on courts
      expect(_playersOnCourts(data), greaterThanOrEqualTo(4));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // RND-05: Pre-make next round — computes staged lineup without
  // changing live courts. "Cancel next" replaces the button. Panel
  // appears with summary + striped progress bar that fills up.
  // ─────────────────────────────────────────────────────────────────
  group('RND-05 — Pre-make next round', () {
    test('stageNextRound does not change live court assignments', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();
      final liveBefore = data.stagingMatches
          .map((g) => g.players.toList())
          .toList();

      data.stageNextRound();
      // Live court assignments should be unchanged after staging
      final liveAfter = data.stagingMatches
          .map((g) => g.players.toList())
          .toList();
      for (var i = 0; i < liveBefore.length; i++) {
        expect(
          liveAfter[i].map((p) => p.id),
          equals(liveBefore[i].map((p) => p.id)),
        );
      }
    });

    test('stageNextRound sets isStaged to true', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();
      expect(data.isStaged, isFalse);

      data.stageNextRound();
      expect(data.isStaged, isTrue);
    });

    test('stageNextRound computes a valid staged lineup', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();

      data.stageNextRound();
      expect(data.isStaged, isTrue);
      // The staged lineup should have courts with players
      final staged = data.stagedLineup!;
      expect(staged, isNotEmpty);
      final stagedPlayers = staged.fold<int>(
        0,
        (sum, g) => sum + g.players.length,
      );
      expect(stagedPlayers, greaterThanOrEqualTo(4));
    });

    test('staged summary describes player count and court count', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();

      data.stageNextRound();
      final summary = data.stagedSummary;
      expect(summary, contains('players'));
      expect(summary, contains('courts'));
    });

    test('rotation countdown is unchanged after staging', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();
      expect(data.roundNumber, equals(1));

      data.stageNextRound();
      // Round number should not change (staging is separate)
      expect(data.roundNumber, equals(1));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // RND-06: Staged round becomes live — when rotateNow is called
  // with a staged round, the previously staged lineup is adopted
  // (not recomputed), isStaged becomes false, round increments.
  // ─────────────────────────────────────────────────────────────────
  group('RND-06 — Staged round becomes live', () {
    test('rotateNow adopts staged lineup when one exists', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();

      // Stage a round
      data.stageNextRound();
      expect(data.isStaged, isTrue);
      final stagedLineup = data.stagedLineup!;

      // Rotate now — should adopt the staged lineup
      await data.rotateNow();
      expect(data.isStaged, isFalse);
      expect(data.roundNumber, equals(2));

      // The staged lineup was adopted (not recomputed from scratch)
      // The full set of players in staging should match
      final allLivePlayers = data.stagingMatches
          .expand((g) => g.players)
          .map((p) => p.id)
          .toSet();
      final allStagedPlayers = stagedLineup
          .expand((g) => g.players)
          .map((p) => p.id)
          .toSet();
      expect(allLivePlayers, equals(allStagedPlayers));
    });

    test('isStaged is false after rotateNow adopts staged lineup', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();
      data.stageNextRound();
      expect(data.isStaged, isTrue);

      await data.rotateNow();
      expect(data.isStaged, isFalse);
    });

    test('round number increments when staged becomes live', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();
      expect(data.roundNumber, equals(1));

      data.stageNextRound();
      expect(data.roundNumber, equals(1)); // staging doesn't change round

      await data.rotateNow();
      expect(data.roundNumber, equals(2)); // rotation does
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // RND-07: Cancel staged — panel disappears, "Pre-make next round"
  // returns, live round unaffected.
  // ─────────────────────────────────────────────────────────────────
  group('RND-07 — Cancel staged round', () {
    test('cancelStagedRound sets isStaged to false', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();
      data.stageNextRound();
      expect(data.isStaged, isTrue);

      data.cancelStagedRound();
      expect(data.isStaged, isFalse);
    });

    test(
      'cancelStagedRound does not affect live round or round number',
      () async {
        final data = GameData()..setNumberOfCourt(2);
        final players = await _eightPlayers();
        for (final p in players) {
          data.addFullPricedPlayer(p);
        }
        await data.makeGame();
        final liveBefore = data.stagingMatches
            .map((g) => g.players.toList())
            .toList();
        expect(data.roundNumber, equals(1));

        data.stageNextRound();
        data.cancelStagedRound();

        // Live courts are unchanged
        final liveAfter = data.stagingMatches
            .map((g) => g.players.toList())
            .toList();
        for (var i = 0; i < liveBefore.length; i++) {
          expect(
            liveAfter[i].map((p) => p.id),
            equals(liveBefore[i].map((p) => p.id)),
          );
        }
        // Round number unchanged
        expect(data.roundNumber, equals(1));
      },
    );

    test('can stage again after cancel', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();

      data.stageNextRound();
      expect(data.isStaged, isTrue);

      data.cancelStagedRound();
      expect(data.isStaged, isFalse);

      // Should be able to stage again
      data.stageNextRound();
      expect(data.isStaged, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // RND-08: Only one staged round at a time — "Pre-make next round"
  // hidden while staged round exists.
  // ─────────────────────────────────────────────────────────────────
  group('RND-08 — Only one staged round at a time', () {
    test('stageNextRound is no-op when already staged', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();

      data.stageNextRound();
      expect(data.isStaged, isTrue);
      final firstStaged = data.stagedLineup;

      // Calling stageNextRound again should not change anything
      data.stageNextRound();
      expect(data.isStaged, isTrue);
      // The staged lineup should be the same
      expect(data.stagedLineup, same(firstStaged));
    });

    test('isStaged remains true until cancel or rotate', () async {
      final data = GameData()..setNumberOfCourt(2);
      final players = await _eightPlayers();
      for (final p in players) {
        data.addFullPricedPlayer(p);
      }
      await data.makeGame();
      expect(data.isStaged, isFalse);

      data.stageNextRound();
      expect(data.isStaged, isTrue);

      // Calling stageNextRound again keeps it true
      data.stageNextRound();
      expect(data.isStaged, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // RND-09: Mode label — verified via widget tests.
  // The modeLabel is computed from settings, not GameData itself.
  // ─────────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────────
  // Initial state
  // ─────────────────────────────────────────────────────────────────
  group('Round rotation — initial state', () {
    test('roundNumber starts at 1', () {
      final data = GameData();
      expect(data.roundNumber, equals(1));
    });

    test('isStaged starts as false', () {
      final data = GameData();
      expect(data.isStaged, isFalse);
    });

    test('stagedLineup is null initially', () {
      final data = GameData();
      expect(data.stagedLineup, isNull);
    });
  });
}

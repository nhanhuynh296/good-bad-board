import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:test/test.dart';

import 'support/repository_sandbox.dart';
import 'support/prefs_sandbox.dart';

void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('membership_test');
  });

  tearDown(() => sandbox.tearDown());

  // setMembership persists via GameData.onUpdatePlayer, which does not
  // return the write future. An empty write coalesces behind every earlier
  // write, so awaiting it makes sure the file is written before tearDown
  // deletes tempDir. A fixed delay was not sufficient under load.
  Future<void> flushPendingWrites() =>
      PlayerRepository.instance.addAll(const []);

  group('MembershipStatus', () {
    test('Player.create defaults to member', () {
      final player = Player.create(
        firstName: 'Alice',
        lastName: 'Smith',
        elo: Elo.c2,
      );

      expect(player.membership, MembershipStatus.member);
    });

    test('next cycles member -> casual -> disabled -> member', () {
      expect(MembershipStatus.member.next, MembershipStatus.casual);
      expect(MembershipStatus.casual.next, MembershipStatus.disabled);
      expect(MembershipStatus.disabled.next, MembershipStatus.member);
    });
  });

  group('checkInPlayer membership gating', () {
    test('refuses to check in a disabled player', () {
      final gameData = GameData();
      final player = Player.create(
        firstName: 'Deb',
        lastName: 'Roe',
        elo: Elo.c2,
        membership: MembershipStatus.disabled,
      );

      final result = gameData.checkInPlayer(player);

      expect(result, CheckInResult.disabled);
      expect(gameData.isPlayerCheckedIn(player), isFalse);
    });

    test('checks in a player with no prior session-pool activation', () {
      final gameData = GameData();
      final player = Player.create(
        firstName: 'Eve',
        lastName: 'Chan',
        elo: Elo.b1,
      );

      final result = gameData.checkInPlayer(player);

      expect(result, CheckInResult.checkedIn);
      expect(gameData.isPlayerCheckedIn(player), isTrue);
      expect(gameData.checkedInPlayers, containsPair(player.id, player));
    });
  });

  group('checkOutPlayer session-pool eviction', () {
    test('removes the player from the session pool', () {
      final gameData = GameData();
      final player = Player.create(
        firstName: 'Fay',
        lastName: 'Lopez',
        elo: Elo.a2,
      );
      gameData.checkInPlayer(player);
      expect(gameData.checkedInPlayers, containsPair(player.id, player));

      gameData.checkOutPlayer(player);

      expect(gameData.checkedInPlayers.containsKey(player.id), isFalse);
    });
  });

  group('setMembership', () {
    test('disabling a checked-in, on-court player checks them out, frees '
        'their court slot, and promotes a waitlisted player (WL-02)', () async {
      final gameData = GameData()..setNumberOfCourt(1);
      final courtPlayers = List.generate(
        4,
        (i) => Player.create(
          firstName: 'Court',
          lastName: '$i',
          elo: Elo.values[i],
        ),
      );
      for (final p in courtPlayers) {
        await PlayerRepository.instance.add(p);
        gameData.checkInPlayer(p);
      }
      await gameData.makeGame(); // fills the single court with all 4

      final waitlisted = Player.create(
        firstName: 'Wait',
        lastName: 'Listed',
        elo: Elo.s1,
      );
      await PlayerRepository.instance.add(waitlisted);
      gameData.checkInPlayer(waitlisted);
      expect(gameData.gameContainingPlayer(waitlisted), isNull);

      final target = courtPlayers.first;
      gameData.setMembership(target, MembershipStatus.disabled);
      await flushPendingWrites();

      expect(gameData.isPlayerCheckedIn(target), isFalse);
      expect(gameData.checkedInPlayers.containsKey(target.id), isFalse);
      expect(gameData.gameContainingPlayer(target), isNull);
      final promotedCourt = gameData.gameContainingPlayer(waitlisted);
      expect(promotedCourt, isNotNull);
      expect(promotedCourt!.players, contains(waitlisted));
    });

    test('disabling a player who is not checked in has no court/waitlist '
        'side effects', () async {
      final gameData = GameData();
      final player = Player.create(
        firstName: 'Gina',
        lastName: 'Park',
        elo: Elo.b2,
      );
      await PlayerRepository.instance.add(player);

      gameData.setMembership(player, MembershipStatus.disabled);
      await flushPendingWrites();

      expect(gameData.isPlayerCheckedIn(player), isFalse);
      expect(gameData.checkedInPlayers.containsKey(player.id), isFalse);
    });

    test(
      'a disabled player cannot be checked in again until re-enabled',
      () async {
        final gameData = GameData();
        final player = Player.create(
          firstName: 'Hugo',
          lastName: 'Diaz',
          elo: Elo.c1,
        );
        await PlayerRepository.instance.add(player);
        gameData.checkInPlayer(player);
        gameData.setMembership(player, MembershipStatus.disabled);
        await flushPendingWrites();

        final disabledPlayer = player.copyWith(
          membership: MembershipStatus.disabled,
        );
        final blockedResult = gameData.checkInPlayer(disabledPlayer);
        expect(blockedResult, CheckInResult.disabled);

        final reEnabledPlayer = disabledPlayer.copyWith(
          membership: MembershipStatus.member,
        );
        final allowedResult = gameData.checkInPlayer(reEnabledPlayer);
        expect(allowedResult, CheckInResult.checkedIn);
      },
    );
  });
}

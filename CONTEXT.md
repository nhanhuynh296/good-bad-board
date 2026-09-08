# Good Bad Board

A badminton club organiser. It holds the club's players, builds balanced matches for a
play session, and keeps the history of what was played.

## Language

### People

**Player**:
A person who plays at the club. A Player is never removed from the data. Deleting a
Player erases their personal information and keeps the rest.
_Avoid_: user, member, participant

**Anonymised Player**:
A Player whose personal information was erased on delete. The id, the Elo and the play
history stay. `deletedDate` records when it happened.
_Avoid_: deleted player, removed player, tombstone

**Listed Player**:
A Player who is not anonymised. The Players the organizer can pick from: the roster list,
check-in, matchmaking. It is the complement of Anonymised Player and says nothing about
Membership or the Session.
_Avoid_: active player, live player, current player

**Membership**:
A Player's standing at the club: Member, Casual, or Disabled. Membership says nothing
about deletion. A Disabled Player is still a club member who cannot check in.
_Avoid_: status, role, account type

**Elo**:
A Player's skill grade, from `c2` up to `s1`. It is one of eight fixed grades. It is not
a numeric rating and the club does not compute it from results.
_Avoid_: rating, rank, level, score

### Play

**Session**:
One play day. It has a set of checked-in Players and a court count.
_Avoid_: event, meet, night

**Court**:
One numbered playing area in a Session. A Court holds at most four Players.
_Avoid_: table, court slot

**Game**:
One match on one Court. A Game holds the Players who played it and the time it was made.
It is the unit stored in the history.
_Avoid_: match, court row, fixture

**Round**:
Every Court at one moment. A Round exists only in Time Based sessions, because only there
do all Courts change together. Game Based sessions have no Round.
_Avoid_: rotation, set, cycle

**Game Type**:
How a Session ends its Games. **Time Based** rotates every Court when the clock stops.
**Game Based** saves one Court when its match finishes.
_Avoid_: mode, game mode, rotation mode

**Waitlist**:
The checked-in Players who hold no Court slot. The app promotes from it when a slot opens.
_Avoid_: queue, bench, reserve

**Check-in**:
A Player joining the Session on the day. A checked-in Player is in the Session and can be
put on a Court. Check-out reverses it. A Disabled Player cannot check in.
_Avoid_: attend, present, active, sign in

## Banned words

**Active / Inactive** — never use either word for a Player. Each one has meant four
different things in this codebase, and the four are independent:

| What you mean | Say | Test |
| --- | --- | --- |
| Not deleted | Listed Player | `!player.isAnonymised` |
| Allowed to check in | Membership is not Disabled | `player.membership != disabled` |
| In the Session today | Checked in | `gameData.isPlayerCheckedIn(player)` |
| Holding a Court slot | On Court (else Waitlist) | `gameData.gameContainingPlayer(player) != null` |

A Player can be Listed, Disabled, and hold play history at once. "Active" hides which of
the four you meant, so the reader guesses.

The word is fine outside the domain: the selected tab, an in-flight write, a UI mode that
is switched on. Those are not Players.

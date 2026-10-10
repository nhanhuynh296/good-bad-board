# A Round is recorded on the Game row

`games.json` is a flat list of Games, one row per Court, and it holds no Round. A Round is
real in Time Based sessions — every Court changes together — but the file cannot express
it. `Game.create` stamps `createdDate` when the Game is built, not when it is saved, so
the Courts of one Round hold timestamps that differ by milliseconds and cannot be grouped
reliably. A Game therefore carries a round id, set at `Game.create`, shared by every Court
in the Round. In Game Based sessions the round id is null, because there is no Round.

## Considered options

- **Group by timestamp proximity.** Rejected. The timestamps come from build time, not
  save time, and a staged Round can sit unbuilt for minutes before it is played.
- **Give a Game Based Court its own round id — a Round of one.** Rejected. Every consumer
  that counts Rounds would then read 12 Game Based Courts as 12 Rounds. Null is the honest
  value for "does not apply".
- **Set the round id just before the save.** Rejected by preference, not by argument. Both
  points work. Creation is the earlier one.

## Consequences

- This changes the shape of `games.json`. It needs its own migration decision and its own
  golden test, so it is not part of the `JsonCollection` refactor.
- Empty Courts become meaningful. A Time Based Round that ran three of five Courts records
  two empty Games, and the round id groups them. Until this lands, an empty row is
  ambiguous — it may be an idle Court, or a roster destroyed by the bug in ADR-0001.
- `rotateNow` currently filters empty Courts out (`game_data.dart:314`) while
  `saveCurrentGame` keeps them (`:513`). Both record a Time Based Round. `rotateNow` must
  change to keep them.

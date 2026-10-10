# Players are anonymised, not deleted

Every Game stores its roster as a list of player ids only. Removing a Player therefore
breaks every Game they played, and the load path used to drop the broken ids and save the
shortened roster back — which erased 98% of the match history (PERSISTENCE.md §3.1).
Deleting a Player now erases their personal information and keeps the record: the name is
emptied, `signInId` is cleared, and `deletedDate` is set. The id, the Elo and the
`createdDate` stay, so the play history stays correct.

## Considered options

- **Reuse `MembershipStatus.disabled`.** Rejected. Membership means club standing. Making
  it also mean "this person was deleted" puts two meanings on one word, and un-disabling
  would un-delete.
- **Hard delete, and repair the roster on load.** Rejected. The roster holds ids only, so
  there is nothing left to repair from.
- **Store a snapshot of each Player inside the Game.** Rejected for now. It is a better
  model and it would give analytics the Elo at play time, but it needs a file format
  change and a migration. Worth revisiting.

## Consequences

- An anonymised Player keeps a row in `players.json` forever, including one who never
  played. At 245 players in 42 KB, the dead rows cost nothing, and the alternative needs a
  scan of every Game to decide.
- Nothing stores the words "deleted player". The UI reads `deletedDate != null` and renders
  a localised label, so all three languages stay correct.
- Analytics that group by player id keep working. Analytics that read a name — "most
  played with", for example — show the placeholder label instead.

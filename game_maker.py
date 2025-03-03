import math
import statistics
from dataclasses import dataclass
from itertools import batched
from typing import ClassVar

import numpy

from player import Player


@dataclass
class Match:
    players: list[Player]

    PLAYER_PER_COURT: ClassVar[int] = 4

    def __init__(self, players: list[Player]):
        assert len(players) == 4, f"Invalid number of players, got {len(players)}"
        self.players = sorted(players, key=lambda p: p.elo)

    def __hash__(self):
        return hash(*self.players)

    def elo_gap(self) -> float:
        elo = [player.elo for player in self.players]
        return max(*elo) - min(*elo)


class GameMaker:
    def __init__(self):
        self._players: list[Player] = list()
        self._history: list[Match] = list()
        self._court = 0
        ...

    def set_court(self, court: int):
        assert 0 <= court <= len(self._players) / Match.PLAYER_PER_COURT, (
            "Not enough players"
        )
        self._court = court

    def add_player(self, player: Player):
        self._players.append(player)

    def remove_player(self, player: Player):
        self._players.remove(player)

    def make_game(self):
        players = self._choose_players()
        matches = self._make_match(players)
        self._history.extend(matches)
        self.improve_elo_spread(matches, 0)
        print(f"{self.calculate_elo_spread(matches):.2f} {matches}")

    def _choose_players(self) -> list[Player]:
        players_match_count = self._count_player_matches()
        average_match_played = self._average_player_matches()
        modifier = math.floor(len(self._players) / Match.PLAYER_PER_COURT)
        weights = [
            (1 + (average_match_played - players_match_count[p]) / modifier)
            / len(self._players)
            for p in self._players
        ]
        return numpy.random.choice(
            list(self._players),
            p=weights,
            size=self._court * Match.PLAYER_PER_COURT,
            replace=False,
        )

    @staticmethod
    def _make_match(players: list[Player]) -> list[Match]:
        sorted_player = sorted(players, key=lambda player: player.elo)
        batched_players = batched(sorted_player, Match.PLAYER_PER_COURT, strict=True)
        return [Match(list(players)) for players in batched_players]

    def _count_player_matches(self) -> dict[Player, int]:
        match_count = {player: 0 for player in self._players}
        for match in self._history:
            for player in match.players:
                match_count[player] += 1
        return match_count

    def _average_player_matches(self) -> float:
        match_counts = self._count_player_matches()
        total_matches = sum(match_counts.values())
        num_players = len(match_counts)
        return total_matches / num_players if num_players > 0 else 0.0

    @staticmethod
    def calculate_elo_spread(matches: list[Match]) -> float:
        match_elo = [match.elo_gap() for match in matches]
        return statistics.mean(match_elo)

    def improve_elo_spread(self, matches: list[Match], target_spread: float):
        # If the current spread is too high, try to swap players with other groups
        if (current_spread := self.calculate_elo_spread(matches)) > target_spread:
            return matches

        # Try swapping players between groups to reduce the spread
        for match1 in matches:
            for match2 in matches:
                if match1 is match2:
                    continue
                for player1_index in range(Match.PLAYER_PER_COURT):
                    for player2_index in range(Match.PLAYER_PER_COURT):
                        match1.players[player1_index], match2.players[player2_index] = (
                            match2.players[player2_index],
                            match1.players[player1_index],
                        )

                        new_spread = self.calculate_elo_spread(matches)
                        if abs(new_spread - target_spread) > abs(
                            current_spread - target_spread
                        ):
                            current_spread = new_spread
                            break
                        else:
                            # swap back
                            (
                                match1.players[player1_index],
                                match2.players[player2_index],
                            ) = (
                                match2.players[player2_index],
                                match1.players[player1_index],
                            )

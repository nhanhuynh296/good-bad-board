import itertools
import math
import random
import statistics
from collections import Counter
from itertools import batched
from typing import Any, ClassVar

import numpy as np
from pydantic import BaseModel, Field, field_serializer

from player import Player


class Match(BaseModel):
    PLAYER_PER_COURT: ClassVar[int] = 4
    players: list[Player] = Field(max_length=4, min_length=4)
    elo_gap: int = Field(init=False, default=0)

    def model_post_init(self, __context: Any):
        self.players = sorted(self.players, key=lambda p: p.elo.value)
        self.elo_gap = abs(self.players[0].elo - self.players[-1].elo)

    def __str__(self):
        return f"[{self.players[0]} {self.players[3]}] vs [{self.players[1]} {self.players[2]}]"

    @field_serializer("players")
    def ser_players(self, players: list[Player]):
        return [player.id for player in players]


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
        candidate_players = self._choose_players()
        matches = self._make_match(candidate_players)
        self._history.extend(matches)
        self.improve_elo_spread(matches, 2)
        print(f"{self.calculate_elo_spread(matches):.2f}")
        for court_num, match in enumerate(matches, start=1):
            print(f"Court {court_num}: {match}")
        self.print_statistic_history()

    def _choose_players(self) -> list[Player]:
        players_match_count = self._count_player_matches()
        average_match_played = self._average_player_matches()
        modifier = math.floor(len(self._players) / Match.PLAYER_PER_COURT)
        weights = [
            (1 + (average_match_played - players_match_count[p]) / modifier)
            / len(self._players)
            for p in self._players
        ]
        return np.random.choice(
            list(self._players),
            p=weights,
            size=self._court * Match.PLAYER_PER_COURT,
            replace=False,
        )

    @staticmethod
    def _make_match(players: list[Player]) -> list[Match]:
        sorted_player = players
        random.shuffle(sorted_player)
        batched_players = batched(sorted_player, Match.PLAYER_PER_COURT, strict=True)
        return [Match(players=list(players)) for players in batched_players]

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
        return statistics.mean(match_counts.values())

    @staticmethod
    def calculate_elo_spread(matches: list[Match]) -> float:
        matches_elo = [match.elo_gap for match in matches]
        return max(matches_elo)

    def improve_elo_spread(self, matches: list[Match], target_spread: float):
        # If the current spread is too high, try to swap players with other groups
        if (current_spread := self.calculate_elo_spread(matches)) < target_spread:
            return matches

        # Try swapping players between groups to reduce the spread
        for match1, match2 in itertools.combinations(matches, 2):
            for player1_index in range(Match.PLAYER_PER_COURT):
                for player2_index in range(Match.PLAYER_PER_COURT):
                    match1.players[player1_index], match2.players[player2_index] = (
                        match2.players[player2_index],
                        match1.players[player1_index],
                    )

                    new_spread = self.calculate_elo_spread(matches)
                    #  just enough spread
                    if new_spread < target_spread:
                        print(f"== Nah {new_spread=}")
                        return None
                    if (new_spread - target_spread) < (current_spread - target_spread):
                        current_spread = new_spread
                        print(f"==Yes {current_spread=}")
                        break
                    # swap back
                    (
                        match1.players[player1_index],
                        match2.players[player2_index],
                    ) = (
                        match2.players[player2_index],
                        match1.players[player1_index],
                    )
        return None

    def print_statistic_history(self):
        counter = self._count_player_matches()
        inverse_counter = Counter(counter.values())
        for match_played, count in inverse_counter.items():
            print(f"{count:3d} player had {match_played:02d} matches")

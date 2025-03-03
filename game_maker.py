from dataclasses import dataclass

from player import Player


class GameMaker:
    def __init__(self):
        self._players: set[Player] = set()
        ...

    def add_player(self, player: Player):
        self._players.add(player)

    def remove_player(self, player: Player):
        self._players.remove(player)

    def make_game(self): ...


@dataclass
class Match:
    player1: Player
    player2: Player
    player3: Player
    player4: Player

    def __init__(self, players: set[Player]):
        assert len(players) == 4
        self.player1, self.player2, self.player3, self.player4 = sorted(
            players, key=lambda player: player.elo
        )

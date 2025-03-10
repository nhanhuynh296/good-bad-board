from pydantic import RootModel

from player import Player

INDENT = 4

Players = RootModel[list[Player]]


def save_players(players: list[Player]) -> None:
    players = Players(players)
    with open("players.json", "w") as f:
        f.write(players.model_dump_json(indent=INDENT))


def load_players() -> Players:
    with open("players.json") as f:
        return Players.model_validate_json(f.read())


def save_matches(): ...

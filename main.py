from faker import Faker

from game_maker import GameMaker
from player import Elo, Player

faker = Faker()
players = [
    Player(name="Howard", elo=Elo.B1),
    Player(name="Yong", elo=Elo.B2),
    Player(name="Ryan", elo=Elo.B2),
    Player(name="Ethan", elo=Elo.B2),
    Player(name="Sherry", elo=Elo.C1),
    Player(name="Wei", elo=Elo.B1),
    Player(name="Jordan", elo=Elo.A2),
    Player(name="Justin", elo=Elo.A1),
    Player(name="Trinity", elo=Elo.C1),
    Player(name="Victor", elo=Elo.A2),
]
# players = [Player(name=faker.first_name(), elo=faker.random_element([e for e in Elo])) for _ in range(26)]

game_maker = GameMaker()
for player in players:
    game_maker.add_player(player)
game_maker.set_court(2)
game_maker.make_game()
game_maker.make_game()
game_maker.make_game()
game_maker.make_game()

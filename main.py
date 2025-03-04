from faker import Faker

from game_maker import GameMaker
from player import Player

faker = Faker()
players = [Player(name=faker.first_name(), elo=faker.random_int(1000, 2500)) for _ in range(26)]

game_maker = GameMaker()
for player in players:
    game_maker.add_player(player)
game_maker.set_court(5)
game_maker.make_game()
game_maker.make_game()
game_maker.make_game()
game_maker.make_game()

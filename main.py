from faker import Faker

from game_maker import GameMaker
from player import Player

faker = Faker()
players = [Player(faker.first_name(), faker.random_int(1000, 2500)) for _ in range(10)]

game_maker = GameMaker()
for player in players:
    game_maker.add_player(player)
game_maker.set_court(2)
game_maker.make_game()
game_maker.make_game()
game_maker.make_game()
game_maker.make_game()

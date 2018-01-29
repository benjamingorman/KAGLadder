import json
import traceback
from datetime import datetime
import server.utils as utils

VALID_REGIONS = ["EU", "US", "AUS"]
VALID_KAG_CLASSES = ["archer", "builder", "knight"]
DEFAULT_RATING = 1000

class DatabaseObject():
    def serialize(self):
        return json.dumps(self.__dict__)

    def validate(self):
        return False

    @classmethod
    def from_data(cls, data):
        instance = cls()
        for key, value in data.items():
            if key in instance.__dict__:
                #utils.log("Set {0}:{1}".format(key, value))
                instance.__dict__[key] = value
            else:
                #utils.log("Skipping {0}".format(key))
                pass
        return instance

    @classmethod
    def from_row(cls, row):
        return cls(*row)

class Player(DatabaseObject):
    def __init__(self, username, nickname="", clantag="", gender=0, head=0):
        self.username = username
        self.nickname = nickname
        self.clantag = clantag
        self.gender = int(gender)
        self.head = int(head)

class MatchHistory(DatabaseObject):
    def __init__(self, region=None, player1=None, player2=None, kag_class=None, match_time=None,
                 player1_score=None, player2_score=None, duel_to_score=None):
        self.region = region
        self.player1 = player1
        self.player2 = player2
        self.kag_class = kag_class
        self.match_time = int(match_time)
        self.player1_score = int(player1_score)
        self.player2_score = int(player2_score)
        self.duel_to_score = int(duel_to_score)

    def validate(self):
        try:
            assert(self.region in VALID_REGIONS)
            assert(utils.is_nonempty_string(self.player1))
            assert(utils.is_nonempty_string(self.player2))
            assert(utils.is_nonempty_string(self.player2))
            assert(self.kag_class in VALID_KAG_CLASSES)
            assert(utils.is_nonempty_string(self.match_time))
            assert(len(self.match_time) == 10)
            int(self.match_time)
            assert(utils.is_nonempty_string(self.player1_score))
            int(self.player1_score)
            assert(utils.is_nonempty_string(self.player2_score))
            int(self.player2_score)
            assert(utils.is_nonempty_string(self.duel_to_score))
            int(self.duel_to_score)
            assert(self.player1_score == self.duel_to_score or self.player2_score == self.duel_to_score)
        except ValueError as e:
            utils.log(e)
            return False
        except AssertionError as e:
            tb = traceback.format_exc()
            utils.log(tb.split("\n")[-3])
            return False

        return True

class PlayerRating(DatabaseObject):
    def __init__(self, username, region, kag_class, rating=DEFAULT_RATING, wins=0, losses=0):
        self.username = username
        self.region = region
        self.kag_class = kag_class
        self.rating = int(rating)
        self.wins = int(wins)
        self.losses = int(losses)

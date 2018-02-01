import json
import traceback
import re
from datetime import datetime
from collections import OrderedDict
import server.utils as utils
import server.db_backend as db
import server.queries as queries
from server.modelbase import Model, Field
from server.constants import *

def username_validator(x):
    return len(x) <= 20 and re.match("^[a-zA-Z0-9_-]*$", x)

def region_validator(x):
    return x in VALID_REGIONS

def kag_class_validator(x):
    return x in VALID_KAG_CLASSES

def nickname_validator(x):
    return len(x) <= 64

def clantag_validator(x):
    return len(x) <= 16

def gender_validator(x):
    return x == 0 or x == 1

def head_validator(x):
    # Default head is 255
    # Custom heads are 0 - 30
    # Standard head pack is 31 - 99
    # Flags of the world are 287 - 363
    return x == 255 or 0 <= x and x <= 99 or 287 <= x and x <= 363

def rating_validator(x):
    return x >= 0

def match_time_validator(x):
    return len(str(x)) == 10

class Player(Model):
    username = Field(0, str, username_validator)
    nickname = Field(1, str, nickname_validator)
    clantag  = Field(2, str, clantag_validator)
    gender   = Field(3, int, gender_validator, default=0)
    head     = Field(4, int, head_validator, default=0)

    def db_create_or_update(self):
        self.validate()
        db.run_query(queries.create_or_update_player, self.as_tuple())

    @staticmethod
    def db_get(username):
        row = db.get_one_row(queries.get_player, (username,))
        if row:
            return Player.from_row(row)

    @staticmethod
    def db_get_or_create(username):
        player = Player.db_get(username)
        if not player:
            player = Player()
            player.username = username
            player.set_defaults()
        return player

class MatchHistory(Model):
    region        = Field(0, str, region_validator)
    player1       = Field(1, str, username_validator)
    player2       = Field(2, str, username_validator)
    kag_class     = Field(3, str, kag_class_validator)
    match_time    = Field(4, int, match_time_validator)
    player1_score = Field(5, int, lambda x: x >= 0)
    player2_score = Field(6, int, lambda x: x >= 0)
    duel_to_score = Field(7, int, lambda x: x > 0)

    def db_create_or_update(self):
        self.validate()
        db.run_query(queries.create_or_update_match_history, self.as_tuple())

    @staticmethod
    def db_get(region, match_time):
        row = db.get_one_row(queries.get_match_history, (region, match_time))
        if row:
            return MatchHistory.from_row(row)

class PlayerRating(Model):
    username  = Field(0, str, username_validator)
    region    = Field(1, str, region_validator)
    kag_class = Field(2, str, kag_class_validator)
    rating    = Field(3, int, rating_validator, default=DEFAULT_RATING)
    wins      = Field(4, int, lambda x: x >= 0, default=0)
    losses    = Field(5, int, lambda x: x >= 0, default=0)

    def db_create_or_update(self):
        self.validate()
        db.run_query(queries.create_or_update_player_rating, self.as_tuple())

    @staticmethod
    def db_get(username, region, kag_class):
        row = db.get_one_row(queries.get_player_rating, (username, region, kag_class))
        if row:
            return PlayerRating.from_row(row)

    @staticmethod
    def db_get_or_create(username, region, kag_class):
        pr = PlayerRating.db_get(username, region, kag_class)
        if not pr:
            pr = PlayerRating()
            pr.username = username
            pr.region = region
            pr.kag_class = kag_class
            pr.set_defaults()
        return pr

class LeaderboardRow(Model):
    username = Field(0, str, username_validator)
    nickname = Field(1, str, nickname_validator)
    clantag  = Field(2, str, clantag_validator)
    gender   = Field(3, int, gender_validator)
    head     = Field(4, int, head_validator)
    rating   = Field(5, int, rating_validator)
    wins     = Field(6, int, lambda x: x >= 0)
    losses   = Field(7, int, lambda x: x >= 0)

class MatchStats(Model):
    pass

import json
import traceback
import re
from datetime import datetime
from collections import OrderedDict
import server.utils as utils
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
    return 0 <= x and x <= 255

def rating_validator(x):
    return x >= 0

class Player(Model):
    username = Field(0, str, username_validator)
    nickname = Field(1, str, nickname_validator)
    clantag  = Field(2, str, clantag_validator)
    gender   = Field(3, int, gender_validator, default=0)
    head     = Field(4, int, head_validator, default=0)

class MatchHistory(Model):
    region        = Field(0, str, region_validator)
    player1       = Field(1, str, username_validator)
    player2       = Field(2, str, username_validator)
    kag_class     = Field(3, str, kag_class_validator)
    match_time    = Field(4, int, lambda x: len(str(x)) == 10)
    player1_score = Field(5, int, lambda x: x >= 0)
    player2_score = Field(6, int, lambda x: x >= 0)
    duel_to_score = Field(7, int, lambda x: x > 0)

class PlayerRating(Model):
    username  = Field(0, str, username_validator)
    region    = Field(1, str, region_validator)
    kag_class = Field(2, str, kag_class_validator)
    rating    = Field(3, int, rating_validator, default=DEFAULT_RATING)
    wins      = Field(4, int, lambda x: x >= 0, default=0)
    losses    = Field(5, int, lambda x: x >= 0, default=0)

class LeaderboardRow(Model):
    username = Field(0, str, username_validator)
    nickname = Field(1, str, nickname_validator)
    clantag  = Field(2, str, clantag_validator)
    gender   = Field(3, int, gender_validator)
    head     = Field(4, int, head_validator)
    rating   = Field(5, int, rating_validator)
    wins     = Field(6, int, lambda x: x >= 0)
    losses   = Field(7, int, lambda x: x >= 0)

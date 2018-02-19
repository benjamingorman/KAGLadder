import re
from server.constants import *

def is_str(x):
    return type(x) == str

def is_int(x):
    return type(x) == int

def username(x):
    return is_str(x) and len(x) <= 20 and re.match("^[a-zA-Z0-9_-]*$", x)

def region(x):
    return x in VALID_REGIONS

def kag_class(x):
    return x in VALID_KAG_CLASSES

def nickname(x):
    return is_str(x) and len(x) <= 20

def clantag(x):
    return is_str(x) and len(x) <= 10

def gender(x):
    return x == 0 or x == 1

def head(x):
    # Default head is 255
    # Custom heads are 0 - 30
    # Standard head pack is 31 - 99
    # Flags of the world are 287 - 363
    return (0 <= x and x <= 28) or (31 <= x and x <= 99) or (x == 255) or (287 <= x and x <= 363)

def rating(x):
    return is_int(x) and x >= 0

def score(x):
    return is_int(x) and x >= 0

def coins(x):
    return is_int(x) and x >= 0 and x <= 4294967296

def id_field(x):
    return is_int(x) and x >= 0

def match_time(x):
    return is_int(x) and len(str(x)) == 10

def round_index(x):
    return is_int(x) and x < MAX_DUEL_TO_SCORE * 2

def events(x):
    return 0 < len(x) and len(x) <= 8096

def url(x):
    return 0 < len(x)  and len(x) <= 255

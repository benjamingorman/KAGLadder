import math
from server.constants import *
from server.normal_table import NORMAL_TABLE

ELO_BASE = 5
ELO_SCALING = 200.0  # how quickly ratings adjust after matches
ELO_DIVISOR = 1400.0  # reflects how likely a higher rated player is to beat a lower one
MIN_MATCH_LENGTH_SCALING = 0.5
MAX_MATCH_LENGTH_SCALING = 1.2


def normal_distribution(z):
    for (_z, p) in NORMAL_TABLE:
        if z <= _z:
            return p
    return 0.9997

    z = round(z, 1)
    if z <= -3.4:
        return 0.0003
    elif z >= 3.4:
        return 0.9997
    else:
        return NORMAL_TABLE.get(z, 0.5)


def get_scale_between(start, end, x):
    return (x-start) / (end-start)


def scale_between(start, end, progress):
    return start + (end-start) * progress


def get_win_probabilities(p1_rating, p2_rating, p1_score, p2_score, duel_to_score):
    delta = p2_rating - p1_rating
    expectedScorePct = 1.0 / (1.0 + pow(ELO_BASE, delta/ELO_DIVISOR))

    delta = 1
    mu = expectedScorePct - 0.5

    p1_need_to_win = duel_to_score - p1_score
    p2_need_to_win = duel_to_score - p2_score

    z = p2_need_to_win / (p1_need_to_win + p2_need_to_win) - 0.5
    p1_win_p = round(normal_distribution(z) * delta + mu, 3)
    return (p1_win_p, 1-p1_win_p)

def get_odds_from_win_prob(win_p):
    return round(1 + odds_function(win_p), 1)

def odds_function(win_p):
    return MAX_BETTING_ODDS / math.e**(15*win_p)

def get_new_ratings(p1_rating, p2_rating, p1_score, p2_score):
    delta = p2_rating - p1_rating
    scorePct = p1_score / (p1_score + p2_score)
    expectedScorePct = 1.0 / (1.0 + pow(ELO_BASE, delta/ELO_DIVISOR))

    duel_to_score = max(p1_score, p2_score)
    match_length_pct = get_scale_between(MIN_DUEL_TO_SCORE, MAX_DUEL_TO_SCORE, duel_to_score)
    match_length_scaling = scale_between(MIN_MATCH_LENGTH_SCALING,
                                         MAX_MATCH_LENGTH_SCALING,
                                         match_length_pct)

    # When a player goes up D the opponent goes up -D
    p1_gain = math.ceil(ELO_SCALING * (scorePct - expectedScorePct))

    # Scale on match length
    p1_gain *= match_length_scaling
    p1_gain = int(p1_gain)

    # Gain/lose at least 1 point
    if p1_gain == 0:
        if p1_score > p2_score:
            p1_gain = 1
        else:
            p1_gain = -1

    p2_gain = -p1_gain

    # Prevent losing elo for a win
    if p1_gain < 0 and p1_score > p2_score:
        p1_gain = 1
        p2_gain = -1
    elif p2_gain < 0 and p2_score > p1_score:
        p2_gain = 1
        p1_gain = -1

    p1_new = max(p1_rating + p1_gain, MIN_RATING)
    p2_new = max(p2_rating + p2_gain, MIN_RATING)

    return (p1_new, p2_new)

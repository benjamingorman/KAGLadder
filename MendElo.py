import math

class Match:
    def __init__(self):
        self.challengerUsername = ""
        self.challengedUsername = ""
        self.whichClass = ""
        self.scoreChallenger = 0
        self.scoreChallenged = 0
        self.duelToScore = 11

    @staticmethod
    def from_line(line):
        parts = line.split()[2].split(",")
        assert(len(parts) == 6)

        m = Match()
        m.challengerUsername = parts[0]
        m.challengedUsername = parts[1]
        m.whichClass = parts[2]
        m.scoreChallenger = int(parts[3])
        m.scoreChallenged = int(parts[4])
        m.duelToScore = int(parts[5])
        return m

ELO_MATCH_HISTORY_FILE = "Backup_ELO_MatchHistory.cfg"
DEFAULT_ELO = 1000
ELO_BASE = 5
ELO_SCALING = 200.0
ELO_DIVISOR = 1400.0

def compute_new_ratings(ratings_dict, match):
    oldChallengerRating = ratings_dict.get(match.challengerUsername, DEFAULT_ELO)
    oldChallengedRating = ratings_dict.get(match.challengedUsername, DEFAULT_ELO)

    delta = oldChallengedRating - oldChallengerRating
    score = match.scoreChallenger / float(match.scoreChallenger + match.scoreChallenged)
    expectedScore = 1 / float(1 + pow(ELO_BASE, delta/ELO_DIVISOR))

    challengerGain = int(math.ceil(ELO_SCALING * (score - expectedScore)))
    newChallengerRating = oldChallengerRating + challengerGain
    newChallengedRating = oldChallengedRating - challengerGain

    ratings_dict[match.challengerUsername] = newChallengerRating
    ratings_dict[match.challengedUsername] = newChallengedRating

def print_ratings(ratings_dict, whichClass):
    for name, rating in ratings_dict.items():
        print("{0}-{1} = {2}".format(name, whichClass, rating))

archer_ratings = {}
builder_ratings = {}
knight_ratings = {}
with open(ELO_MATCH_HISTORY_FILE, 'r') as f:
    for line in f:
        match = Match.from_line(line)
        if match.whichClass == "archer":
            compute_new_ratings(archer_ratings, match)
        elif match.whichClass == "builder":
            compute_new_ratings(builder_ratings, match)
        elif match.whichClass == "knight":
            compute_new_ratings(knight_ratings, match)

print_ratings(archer_ratings, "archer")
print_ratings(builder_ratings, "builder")
print_ratings(knight_ratings, "knight")


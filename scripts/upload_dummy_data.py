import sys
import random
import json
import time
import requests
import string

N_CLANS = 6
N_PLAYERS = 100
N_MATCHES = 100

def rand_bool():
    return random.randint(0,1) == 0

def rand_uppercase():
    return random.choice(string.ascii_uppercase)

def gen_username():
    adjectives = ["amazing", "red", "quick", "strong", "pretty", "mad", "killer", "angel", "lol", "wicked", "tame", "clever", "blue", "purple", "yellow", "lovely", "happy", "pro", "the"]
    nouns = ["death", "bro", "girl", "arrow", "badger", "rabbit", "fox", "bull", "sword", "bow", "axe", "tree", "cheese", "angel", "devil", "box", "hawk", "spear", "tongue", "bone", "cross", "ear", "dude", "lady", "man", "master", "warrior", "ninja", "samurai", "pro"]

    username = random.choice(adjectives)
    if random.randint(0,1) == 0:
        username += "_"
    
    username += random.choice(nouns)

    if rand_bool():
        username += str(random.randint(0, 99))

    return username[:20]

def gen_gender():
    return random.randint(0,1)

def gen_nickname(username):
    return username

def gen_head():
    heads = []
    for h in range(0, 28):
        heads.append(h)

    for h in range(31, 99):
        heads.append(h)

    heads.append(255)

    for h in range(287, 363):
        heads.append(h)

    return random.choice(heads)

def gen_clan():
    brackets = rand_bool()
    num_letters = random.randint(3,5)
    clan = ''.join([rand_uppercase() for _ in range(num_letters)])
    if rand_bool():
        return "[{0}]".format(clan)
    else:
        return clan

def gen_skills():
    return {"archer": random.randint(0, 1000), "builder": random.randint(0, 1000), "knight": random.randint(0, 1000)}

def gen_match(set_of_players):
    players = random.sample(set_of_players, 2)
    player1 = players[0]
    player2 = players[1]
    region = random.choice(["EU", "AUS", "US"])
    kag_class = random.choice(["archer", "builder", "knight"])
    time_now = int(time.time())
    match_time = random.randint(time_now - 30000, time_now)
    duel_to_score = random.randint(1, 11)

    player1_performance = max(1, int(random.random() * player1.skills[kag_class]))
    player2_performance = max(1, int(random.random() * player2.skills[kag_class]))

    if player1_performance > player2_performance:
        player1_wins = duel_to_score
        player2_wins = int((player2_performance / player1_performance) * duel_to_score)
        if player2_wins == duel_to_score:
            player2_wins -= 1
    else:
        player2_wins = duel_to_score
        player1_wins = int((player1_performance / player2_performance) * duel_to_score)
        if player1_wins == duel_to_score:
            player1_wins -= 1

    match = {}
    match["region"] = region
    match["player1"] = player1.username
    match["player2"] = player2.username
    match["kag_class"] = kag_class
    match["match_time"] = match_time
    match["player1_score"] = player1_wins
    match["player2_score"] = player2_wins
    
    stats = {}
    stats["player1stats"] = {}
    stats["player1stats"]["nickname"] = gen_nickname(player1.username)
    stats["player1stats"]["clantag"] = player1.clan
    stats["player1stats"]["gender"] = player1.gender
    stats["player1stats"]["head"] = player1.head

    stats["player2stats"] = {}
    stats["player2stats"]["nickname"] = gen_nickname(player2.username)
    stats["player2stats"]["clantag"] = player2.clan
    stats["player2stats"]["gender"] = player2.gender
    stats["player2stats"]["head"] = player2.head
    match["stats"] = stats
    match["rounds"] = {"roundstats": [
        {"starttime": 0, "endtime": 10, "winner": player1.username, "events": [{}]}
        ]}
    return match

def rand_bool():
    return bool(random.getrandbits(1))

class DummyPlayer:
    def __init__(self, username, clan):
        self.username = username
        self.clan = clan
        self.skills = gen_skills()
        self.gender = gen_gender()
        self.head = gen_head()

if __name__ == "__main__":
    if len(sys.argv) > 1:
        N_MATCHES = int(sys.argv[1])

    usernames = set()
    clans = set()

    while len(usernames) < N_PLAYERS:
        usernames.add(gen_username())

    while len(clans) < N_CLANS:
        clans.add(gen_clan())

    players = []
    for name in usernames:
        players.append(DummyPlayer(name, random.choice(list(clans))))

    for i in range(N_MATCHES):
        match = gen_match(players)
        print("Posting {}".format(i))
        res = requests.post("http://localhost:5000/create_match", data=json.dumps(match), headers={"Content-Type": "application/json"})
        print(res)
        sys.stdout.flush()

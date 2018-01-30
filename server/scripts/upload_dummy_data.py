import sys
import random
import json
import time
import requests
from server.models import MatchHistory

N_MATCHES = 50

def gen_username():
    adjectives = ["amazing", "red", "quick", "strong", "pretty", "mad", "killer", "angel", "lol", "wicked", "tame", "clever", "blue", "purple", "yellow"]
    nouns = ["badger", "rabbit", "fox", "bull", "sword", "bow", "axe", "tree", "cheese", "angel", "devil", "box", "hawk", "spear"]

    username = random.choice(adjectives)
    if random.randint(0,1) == 0:
        username += "_"
    
    username += random.choice(nouns)

    if random.randint(0,1) == 0:
        username += str(random.randint(0, 99))

    return username

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

    match = MatchHistory()
    match.region = region
    match.player1 = player1.username
    match.player2 = player2.username
    match.kag_class = kag_class
    match.match_time = match_time
    match.player1_score = player1_wins
    match.player2_score = player2_wins
    match.duel_to_score = duel_to_score
    return match

def rand_bool():
    return bool(random.getrandbits(1))

class DummyPlayer:
    def __init__(self, username, skills):
        self.username = username
        self.skills = skills

if __name__ == "__main__":
    num_matches = 10
    if len(sys.argv) > 1:
        num_matches = int(sys.argv[1])
    usernames = set()

    for i in range(50):
        usernames.add(gen_username())

    players = []
    for name in usernames:
        players.append(DummyPlayer(name, gen_skills()))

    for i in range(num_matches):
        print(i)
        match = gen_match(players)
        requests.post("https://api.kagladder.com/create_match", data=match.__dict__)

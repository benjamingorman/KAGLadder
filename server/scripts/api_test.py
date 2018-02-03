import time
import json
import requests
import random
import string

SERVER_ADDR = "https://api.kagladder.com"

def get(endpoint):
    print("GET " + endpoint)
    url = SERVER_ADDR + endpoint
    return requests.get(url).json()

def post(endpoint, data):
    print("POST " + endpoint)
    url = SERVER_ADDR + endpoint
    return requests.post(url, data=json.dumps(data), headers={"Content-Type": "application/json"}).json()

def random_string(N):
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=N))

def create_match(match_time, nickname, clantag, gender, head):
    return {"region": "EU", "player1": "testplayer1", "player2": "testplayer2", "kag_class": "knight",
        "match_time": match_time, "player1_score": 5, "player2_score": 3, "duel_to_score": 5,
        "stats":
            {"player1stats": {"nickname": nickname, "clantag": clantag, "gender": gender, "head": head},
             "player2stats": {"nickname": nickname, "clantag": clantag, "gender": gender, "head": head}
            }
        }

time_now = int(time.time())
rand_nickname = random_string(10)
rand_clantag = random_string(5)
rand_gender = random.randint(0, 1)
rand_head = random.randint(31, 60)

print("Creating match1")
match1 = create_match(time_now, rand_nickname, rand_clantag, rand_gender, rand_head)
result = post("/create_match", match1)
assert(result == "true")

# Stats should have updated players
testplayer1 = get("/players/testplayer1")
print("testplayer1", testplayer1)
assert(testplayer1["username"] == "testplayer1")
assert(testplayer1["nickname"] == rand_nickname)
assert(testplayer1["clantag"] == rand_clantag)
assert(testplayer1["gender"] == rand_gender)
assert(testplayer1["head"] == rand_head)

testplayer2 = get("/players/testplayer2")
print("testplayer2", testplayer2)
assert(testplayer2["username"] == "testplayer2")
assert(testplayer2["nickname"] == rand_nickname)
assert(testplayer2["clantag"] == rand_clantag)
assert(testplayer2["gender"] == rand_gender)
assert(testplayer2["head"] == rand_head)

first_p1r = get("/player_ratings/testplayer1/EU")
first_p2r = get("/player_ratings/testplayer2/EU")

print("Creating match2")
match2 = create_match(time_now+1000, rand_nickname, rand_clantag, rand_gender, rand_head)
result = post("/create_match", match2)
assert(result == "true")

second_p1r = get("/player_ratings/testplayer1/EU")
second_p2r = get("/player_ratings/testplayer2/EU")

assert(second_p1r["knight"]["rating"] > first_p1r["knight"]["rating"])
assert(second_p1r["knight"]["wins"] == first_p1r["knight"]["wins"] + 1)
assert(second_p1r["knight"]["losses"] == first_p1r["knight"]["losses"])

assert(second_p2r["knight"]["rating"] < first_p2r["knight"]["rating"])
assert(second_p2r["knight"]["wins"] == first_p2r["knight"]["wins"])
assert(second_p2r["knight"]["losses"] == first_p2r["knight"]["losses"]+1)

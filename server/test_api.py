import urllib
import urllib.request
import json
import time
import requests

SERVER_ADDR = "http://127.0.0.1:5000"

def get(endpoint):
    url = SERVER_ADDR + endpoint
    return requests.get(url).json()

def post(endpoint, data):
    url = SERVER_ADDR + endpoint
    return requests.post(url, data=data).json()

time_now = str(int(time.time()))
print(post('/api/create_match', {"region": "EU", "player1": "Eluded", "player2": "Cohen", "kag_class": "knight",
        "match_time": time_now, "player1_score": 1, "player2_score": 5, "duel_to_score": 5}))

print(get("/api/players/Eluded"))
print(get("/api/match_history/EU/" + time_now))
print(get("/api/player_rating/Eluded/EU/knight"))
print(get("/api/player_match_history/Eluded"))
print(get("/api/recent_match_history"))

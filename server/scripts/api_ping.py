import json
import requests

SERVER_ADDR = "https://api.kagladder.com"

def get(endpoint):
    print("GET " + endpoint)
    url = SERVER_ADDR + endpoint
    return requests.get(url).json()

username = "Eluded"
print(get("/players/{0}".format(username)))
print()
print(get("/player_match_history/{0}".format(username)))
print()
print(get("/recent_match_history"))
print()
print(get("/leaderboard/EU/knight"))
print()
print(get("/player_ratings/{0}/EU".format(username)))
print()

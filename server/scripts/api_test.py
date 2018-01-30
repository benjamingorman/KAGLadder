import urllib
import urllib.request
import json
import time
import requests

SERVER_ADDR = "https://api.kagladder.com"

def get(endpoint):
    print("GET " + endpoint)
    url = SERVER_ADDR + endpoint
    return requests.get(url).json()

def post(endpoint, data):
    print("POST " + endpoint)
    url = SERVER_ADDR + endpoint
    return requests.post(url, data=data).json()

username = "purplebadger8"
print(get("/recent_match_history"))
print()
print(get("/players/{0}".format(username)))
print()
#print(get("/match_history/EU/"))
print(get("/player_ratings/{0}/EU".format(username)))
print()
print(get("/player_match_history/{0}".format(username)))
print()

import argparse
import kagtcprlib
import json
import logging
import re
import requests
import xmltodict

API_URL = None # set in main
POST_HEADERS = {'Content-Type': 'application/json'}

def get_region(request):
    # All the clients should be named like "kagladder-EU", "kagladder-US" 
    return request.client_name.split("-")[1]

def handle_playerinfo(req):
    log = logging.getLogger(req.client_name)
    region = get_region(req)

    username = req.params["username"]
    url = "{0}/player/{1}".format(API_URL, username)
    response = requests.get(url)
    try:
        response_data = response.json()
        log.debug("response_data: %s", response_data)

        kag_response = {
                "playerinfo": {
                    "region": region,
                    "username": username,
                    "coins": 0,
                    "knight": {"rating": 1000, "wins": 0, "losses": 0},
                    "archer": {"rating": 1000, "wins": 0, "losses": 0},
                    "builder": {"rating": 1000, "wins": 0, "losses": 0},
                    }
                }

        if response_data == "null":
            log.info("API couldn't find player %s", username)
        else:
            if "coins" in response_data:
                kag_response["playerinfo"]["coins"] = response_data["coins"];

            ratings = response_data["ratings"][region]
            for kag_class in ["archer", "builder", "knight"]:
                if kag_class in ratings:
                    kag_response["playerinfo"][kag_class] = ratings[kag_class]

        return dict_to_xml(kag_response)
    except ValueError as e:
        log.error("Caught ValueError in handle_playerratings %s", e)
        return ""

def handle_savematch(req):
    log = logging.getLogger(req.client_name)
    region = get_region(req)

    data = {}
    data["region"] = region
    data["player1"] = req.params["player1"]
    data["player2"] = req.params["player2"]
    data["kag_class"] = req.params["kagclass"]
    data["match_time"] = int(req.params["starttime"])
    data["player1_score"] = int(req.params["player1score"])
    data["player2_score"] = int(req.params["player2score"])
    data["duel_to_score"] = int(req.params["dueltoscore"])
    stats = req.params["stats"]["ratedmatchstats"]
    stats["player1stats"]["head"] = int(stats["player1stats"]["head"])
    stats["player1stats"]["gender"] = int(stats["player1stats"]["gender"])
    stats["player2stats"]["head"] = int(stats["player2stats"]["head"])
    stats["player2stats"]["gender"] = int(stats["player2stats"]["gender"])
    data["stats"] = stats
    data["rounds"] = req.params["rounds"]

    # if there's only 1 round then xmltodict will not convert roundstats into a list
    # so do it manually
    roundstats = req.params["rounds"]["roundstats"]
    if not is_list(roundstats):
        req.params["rounds"]["roundstats"] = [roundstats]

    url = "{0}/create_match".format(API_URL)
    log.debug("handle_savematch: data=%s", json.dumps(data))

    # The 'requests' library defaults to form-encoded data
    # This is fine for data with a flat structure but not with nested objects
    # So instead send data as a string and include a "Content-Type: application/json" header
    response = requests.post(url, data=json.dumps(data), headers=POST_HEADERS)
    if response and response.status_code == requests.codes.ok:
        return dict_to_xml({"response": response.json()})

def handle_coinchange(req):
    log = logging.getLogger(req.client_name)
    username = req.params["username"]
    amount = int(req.params["amount"])

    post_data = {"username": username, "amount": amount}

    url = "{0}/coinchange".format(API_URL)
    response = requests.post(url, data=json.dumps(post_data), headers=POST_HEADERS)
    if response and response.status_code == requests.codes.ok:
        return dict_to_xml(response.json())

def dict_to_xml(the_dict):
    return xmltodict.unparse(the_dict, full_document=False, newl="")

def is_list(x):
    return isinstance(x, (list,))

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("config", help="Path to the config toml file")
    parser.add_argument("--api-url", default="https://api.kagladder.com", help="URL of the API")
    parser.add_argument("--log-dir", default="./logs", help="Directory to save log files to")
    args = parser.parse_args()

    API_URL = args.api_url
    clients = kagtcprlib.load_clients_from_config_file(args.config, log_directory=args.log_dir)

    for client in clients:
        assert(re.match("kagladder-(EU|AUS|US)", client.name))
        client.add_handler("playerinfo", handle_playerinfo)
        client.add_handler("savematch", handle_savematch)
        client.add_handler("coinchange", handle_coinchange)

    kagtcprlib.run_clients(clients)

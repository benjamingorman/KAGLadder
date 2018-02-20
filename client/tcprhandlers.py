import requests
import xmltodict
import json

POST_HEADERS = {'Content-Type': 'application/json'}

def handle_request(req, server_addr, region):
    if req.method == "ping":
        return handle_request_ping(req)
    elif req.method == "playerinfo":
        return handle_request_playerinfo(req, server_addr, region)
    elif req.method == "savematch":
        return handle_request_savematch(req, server_addr, region)
    elif req.method == "coinchange":
        return handle_request_coinchange(req, server_addr)

def handle_request_ping(req):
    return "<response>pong{0}</response>".format(req.params["time"])

def handle_request_playerinfo(req, server_addr, region):
    username = req.params["username"]
    url = "{0}/player/{1}".format(server_addr, username)
    response = requests.get(url)
    try:
        response_data = response.json()
        print("response_data:", response_data)

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
            print("API couldn't find player", username)
        else:
            if "coins" in response_data:
                kag_response["playerinfo"]["coins"] = response_data["coins"];

            ratings = response_data["ratings"][region]
            for kag_class in ["archer", "builder", "knight"]:
                if kag_class in ratings:
                    kag_response["playerinfo"][kag_class] = ratings[kag_class]

        return dict_to_xml(kag_response)
    except ValueError as e:
        print("Caught ValueError in handle_request_playerratings", e)
        return ""

def handle_request_savematch(req, server_addr, region):
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

    url = "{0}/create_match".format(server_addr)
    print("handle_request_savematch", "data=" + json.dumps(data))

    # The 'requests' library defaults to form-encoded data
    # This is fine for data with a flat structure but not with nested objects
    # So instead send data as a string and include a "Content-Type: application/json" header
    response = requests.post(url, data=json.dumps(data), headers=POST_HEADERS)
    if response and response.status_code == requests.codes.ok:
        return dict_to_xml({"response": response.json()})

def handle_request_coinchange(req, server_addr):
    username = req.params["username"]
    amount = int(req.params["amount"])

    post_data = {"username": username, "amount": amount}

    url = "{0}/coinchange".format(server_addr)
    response = requests.post(url, data=json.dumps(post_data), headers=POST_HEADERS)
    if response and response.status_code == requests.codes.ok:
        return dict_to_xml(response.json())

def dict_to_xml(the_dict):
    return xmltodict.unparse(the_dict, full_document=False, newl="")

def is_list(x):
    return isinstance(x, (list,))

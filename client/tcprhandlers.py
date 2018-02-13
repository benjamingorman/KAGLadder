import requests
import xmltodict
import json

POST_HEADERS = {'Content-Type': 'application/json'}

def handle_request(req, server_addr, region):
    if req.method == "ping":
        return handle_request_ping(req)
    elif req.method == "playerratings":
        return handle_request_playerratings(req, server_addr, region)
    elif req.method == "savematch":
        return handle_request_savematch(req, server_addr, region)

def handle_request_ping(req):
    return "<response>pong{0}</response>".format(req.params["time"])

def handle_request_playerratings(req, server_addr, region):
    username = req.params["username"]
    url = "{0}/player/{1}".format(server_addr, username)
    response = requests.get(url)
    try:
        response_data = response.json()
        print("response_data:", response_data)

        kag_response = {
                "playerratings": {
                    "region": region,
                    "username": username,
                    "knight": {"rating": 1000, "wins": 0, "losses": 0},
                    "archer": {"rating": 1000, "wins": 0, "losses": 0},
                    "builder": {"rating": 1000, "wins": 0, "losses": 0},
                    }
                }

        if response_data == "null":
            print("API couldn't find player", username)
        else:
            ratings = response_data["ratings"][region]
            for kag_class in ["archer", "builder", "knight"]:
                if kag_class in ratings:
                    kag_response["playerratings"][kag_class] = ratings[kag_class]
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

    url = "{0}/create_match".format(server_addr)
    print("handle_request_savematch", "data=" + json.dumps(data))

    # The 'requests' library defaults to form-encoded data
    # This is fine for data with a flat structure but not with nested objects
    # So instead send data as a string and include a "Content-Type: application/json" header
    return requests.post(url, data=json.dumps(data), headers=POST_HEADERS).text

def dict_to_xml(the_dict):
    return xmltodict.unparse(the_dict, full_document=False, newl="")

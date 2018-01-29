import requests
import xmltodict

SERVER_ADDR = "https://api.kagladder.com"

def handle_request(req, region):
    if req.method == "ping":
        return handle_request_ping(req)
    elif req.method == "playerratings":
        return handle_request_playerratings(req, region)
    elif req.method == "savematch":
        return handle_request_savematch(req, region)

def handle_request_ping(req):
    return "<response>pong{0}</response>".format(req.params["time"])

def handle_request_playerratings(req, region):
    username = req.params["username"]
    url = "{0}/player_ratings/{1}/{2}".format(SERVER_ADDR, username, region)
    data = requests.get(url).json()
    return dict_to_xml({"playerratings": data})

def handle_request_savematch(req, region):
    data = {}
    data["region"] = region
    data["player1"] = req.params["player1"]
    data["player2"] = req.params["player2"]
    data["kag_class"] = req.params["kagclass"]
    data["match_time"] = req.params["starttime"]
    data["player1_score"] = req.params["player1score"]
    data["player2_score"] = req.params["player2score"]
    data["duel_to_score"] = req.params["dueltoscore"]
    url = "{0}/create_match".format(SERVER_ADDR)
    return requests.post(url, data=data).text

def dict_to_xml(the_dict):
    return xmltodict.unparse(the_dict, full_document=False, newl="")

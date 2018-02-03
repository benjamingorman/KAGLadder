import flask
import json
import codecs
import urllib
from flask_cors import CORS
from flask import jsonify
import server.queries as queries
import server.ratings as ratings
import server.utils as utils
from server.constants import DEFAULT_RATING, VALID_KAG_CLASSES, IP_WHITELIST

app = flask.Flask(__name__, static_folder=None)
CORS(app) # enable cross-origin requests
app.debug = True

def default_handler(query, params_dict, one_result=False):
    utils.log("default handler", params_dict, one_result)
    try:
        results = query.run(params_dict)
    except ValueError as e:
        utils.log("ValueError: " + str(e))
        flask.abort(400)

    if one_result:
        if len(results):
            return jsonify(results[0])
        else:
            return jsonify("null")
    else:
        return jsonify(results)

@app.route('/players/<username>')
def get_player(username):
    return default_handler(queries.get_player, {"username": username}, one_result=True)

@app.route('/match_history/<region>/<match_time>')
def get_match_history(region, match_time):
    return default_handler(queries.get_match_history, {"region": region, "match_time": match_time}, one_result=True)

@app.route('/player_match_history/<username>')
def get_match_history_for_player(username):
    return default_handler(queries.get_player_match_history, {"username": username})

@app.route('/recent_match_history')
@app.route('/recent_match_history/<limit>')
def get_recent_matches(limit=20):
    return default_handler(queries.get_recent_match_history, {"limit": limit})

@app.route('/leaderboard/<region>/<kag_class>')
def get_leaderboard(region, kag_class):
    return default_handler(queries.get_leaderboard, {"region": region, "kag_class": kag_class})

@app.route('/player_ratings/<username>/<region>')
def get_player_ratings(username, region):
    try:
        results = queries.get_player_ratings.run({"username": username, "region": region})
    except ValueError as e:
        print(e)
        flask.abort(400)

    if len(results) == 0:
        return jsonify("null")
    else:
        data = {"username": username, "region": region}

        for kag_class in VALID_KAG_CLASSES:
            data[kag_class] = {"rating": DEFAULT_RATING, "wins": 0, "losses": 0}

        for rating in results:
            data[rating["kag_class"]] = {"rating": rating["rating"], "wins": rating["wins"], "losses": rating["losses"]}

        return jsonify(data)

@app.route('/create_match', methods=['POST'])
def create_match():
    if not is_req_ip_whitelisted(flask.request):
        flask.abort(403)

    match = flask.request.get_json()
    if not match:
        utils.log("No match data supplied")
        flask.abort(400)

    utils.log("Processing match " + str(match))

    utils.log("Creating match...")
    queries.create_or_update_match_history.run(match)
    utils.log("Updating players...")
    update_players(match)
    utils.log("Updating ratings...")
    update_ratings(match)
    return jsonify("true")

@app.route('/')
def get_homepage():
    output = "<html><body><h1>KAGELO API</h1>"
    output += "<table><thead><tr><td>Endpoint</td><td>Methods</td></tr></thead><tbody>"
    for (url, methods, func_name) in list_routes():
        output += "<tr><td>{0}</td><td>{1}</td></tr>".format(url, methods)
    output += "</tbody></table></body></html>"
    output = output.replace("%5B", "{")
    output = output.replace("%5D", "}")
    return output

@app.after_request
def add_header(response):
    response.cache_control.max_age = 60
    return response

def is_req_ip_whitelisted(req):
    return req.remote_addr in IP_WHITELIST

def update_players(match):
    for (username, player_stats) in [(match["player1"], match["stats"]["player1stats"]),
                                     (match["player2"], match["stats"]["player2stats"])]:
        queries.create_or_update_player.run({"username": username, "nickname": player_stats["nickname"],
            "clantag": player_stats["clantag"], "gender": player_stats["gender"], "head": player_stats["head"]})

def update_ratings(match):
    pr1_results = queries.get_player_rating.run({"username": match["player1"], "region": match["region"],
        "kag_class": match["kag_class"]})
    pr2_results = queries.get_player_rating.run({"username": match["player2"], "region": match["region"],
        "kag_class": match["kag_class"]})

    if len(pr1_results) == 0:
        pr1 = queries.create_or_update_player_rating.get_params_template()
        pr1["username"] = match["player1"]
        pr1["region"] = match["region"]
        pr1["kag_class"] = match["kag_class"]
        pr1["wins"] = 0
        pr1["losses"] = 0
        pr1["rating"] = DEFAULT_RATING 
    else:
        pr1 = pr1_results[0]

    if len(pr2_results) == 0:
        pr2 = queries.create_or_update_player_rating.get_params_template()
        pr2["username"] = match["player2"]
        pr2["region"] = match["region"]
        pr2["kag_class"] = match["kag_class"]
        pr2["wins"] = 0
        pr2["losses"] = 0
        pr2["rating"] = DEFAULT_RATING 
    else:
        pr2 = pr2_results[0]

    (p1_new_rating, p2_new_rating) = ratings.get_new_ratings(pr1["rating"], pr2["rating"], match["player1_score"],
        match["player2_score"])
    utils.log("Old ratings {0} {1}".format(pr1["rating"], pr2["rating"]))
    utils.log("New ratings {0} {1}".format(p1_new_rating, p2_new_rating))

    pr1["rating"] = p1_new_rating
    pr2["rating"] = p2_new_rating

    if match["player1_score"] > match["player2_score"]:
        pr1["wins"] += 1
        pr2["losses"] += 1
    else:
        pr1["losses"] += 1
        pr2["wins"] += 1

    queries.create_or_update_player_rating.run(pr1)
    queries.create_or_update_player_rating.run(pr2)

def list_routes():
    output = []
    for rule in app.url_map.iter_rules():
        options = {}
        for arg in rule.arguments:
            options[arg] = "[{0}]".format(arg)
        methods = ','.join(rule.methods)
        url = flask.url_for(rule.endpoint, **options)
        output.append((url, methods, rule.endpoint))

    return sorted(output, key=lambda x: x[0])

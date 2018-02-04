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

@app.route('/match_history/<match_id>')
def get_match_history(match_id):
    return default_handler(queries.get_match_history, {"id": match_id}, one_result=True)

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
    rating_changes = get_rating_changes(match)
    utils.log("Rating changes:", rating_changes)

    utils.log("Creating match...")
    insert_match(match, rating_changes)

    utils.log("Updating players...")
    update_players(match)

    utils.log("Updating ratings...")
    update_ratings(match, rating_changes)

    return jsonify({"player1_rating_change": rating_changes[0], "player2_rating_change": rating_changes[1]})

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

def get_rating_changes(match):
    pr1_results = queries.get_player_rating.run({"username": match["player1"], "region": match["region"],
        "kag_class": match["kag_class"]})
    pr2_results = queries.get_player_rating.run({"username": match["player2"], "region": match["region"],
        "kag_class": match["kag_class"]})

    p1_rating = DEFAULT_RATING
    p2_rating = DEFAULT_RATING
    if len(pr1_results):
        p1_rating = pr1_results[0]["rating"]

    if len(pr2_results):
        p2_rating = pr2_results[0]["rating"]
    
    utils.log("p1_rating", p1_rating, "p2_rating", p2_rating)
    (p1_new_rating, p2_new_rating) = ratings.get_new_ratings(p1_rating, p2_rating, match["player1_score"], match["player2_score"])
    return (p1_new_rating - p1_rating, p2_new_rating - p2_rating)

def insert_match(match, rating_changes):
    match["player1_rating_change"] = rating_changes[0]
    match["player2_rating_change"] = rating_changes[1]
    queries.create_or_update_match_history.run(match)

def update_players(match):
    # Ensure players exist
    queries.create_player.run({"username": match["player1"]})
    queries.create_player.run({"username": match["player2"]})

    to_update = []
    if "stats" in match: 
        if "player1stats" in match["stats"]:
            to_update.append((match["player1"], match["stats"]["player1stats"]))
        if "player2stats" in match["stats"]:
            to_update.append((match["player1"], match["stats"]["player2stats"]))

    for (username, player_stats) in to_update:
        queries.create_or_update_player.run({"username": username, "nickname": player_stats["nickname"],
            "clantag": player_stats["clantag"], "gender": player_stats["gender"], "head": player_stats["head"]})

def update_ratings(match, rating_changes):
    # First upsert a rating entry for each player so we can be sure one exists
    for player in ["player1", "player2"]:
        pr = queries.create_player_rating.get_params_template()
        pr["username"] = match[player]
        pr["region"] = match["region"]
        pr["kag_class"] = match["kag_class"]
        queries.create_player_rating.run(pr)

    pr1_results = queries.get_player_rating.run({"username": match["player1"], "region": match["region"],
        "kag_class": match["kag_class"]})
    pr2_results = queries.get_player_rating.run({"username": match["player2"], "region": match["region"],
        "kag_class": match["kag_class"]})

    pr1 = pr1_results[0]
    pr2 = pr2_results[0]

    pr1["rating"] = pr1["rating"] + rating_changes[0]
    pr2["rating"] = pr2["rating"] + rating_changes[1]

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

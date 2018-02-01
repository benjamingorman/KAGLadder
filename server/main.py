import flask
import json
import codecs
import urllib
from flask_cors import CORS
from flask import jsonify
import server.queries as queries
import server.ratings as ratings
import server.utils as utils
import server.db_backend as db
from server.models import *
from server.constants import DEFAULT_RATING

app = flask.Flask(__name__, static_folder=None)
CORS(app) # enable cross-origin requests
app.debug = True

@app.route('/players/<username>')
def get_player(username):
    if username_validator(username):
        player = Player.db_get(username)
        if player:
            return jsonify(player.to_dict())
        else:
            return jsonify("null")
    else:
        flask.abort(400)

@app.route('/match_history/<region>/<match_time>')
def get_match_history(region, match_time):
    if region_validator(region) and match_time_validator(match_time):
        mh = MatchHistory.db_get(region, match_time)
        if mh:
            return jsonify(mh.to_dict())
        else:
            return jsonify("null")
    else:
        flask.abort(400)

@app.route('/player_ratings/<username>/<region>')
def get_player_ratings(username, region):
    if username_validator(username) and region_validator(region):
        ratings = db.get_many_rows_as_models(PlayerRating, queries.get_player_ratings, (username, region))
        result = {"username": username, "region": region}

        for kag_class in VALID_KAG_CLASSES:
            result[kag_class] = {"rating": DEFAULT_RATING, "wins": 0, "losses": 0}

        for rating in ratings:
            result[rating.kag_class] = {"rating": rating.rating, "wins": rating.wins, "losses": rating.losses}
    
        return jsonify(result)
    else:
        flask.abort(400)

@app.route('/player_match_history/<username>')
def get_match_history_for_player(username):
    if username_validator(username):
        matches = db.get_many_rows_as_models(MatchHistory, queries.get_player_match_history, (username, username))
        return jsonify([match.to_dict() for match in matches])
    else:
        flask.abort(400)

@app.route('/recent_match_history')
@app.route('/recent_match_history/<limit>')
def get_recent_matches(limit=20):
    if type(limit) == str:
        try:
            limit = int(limit)
        except ValueError:
            limit = 20
    matches = db.get_many_rows_as_models(MatchHistory, queries.get_recent_match_history, (limit,))
    return jsonify([match.to_dict() for match in matches])

@app.route('/leaderboard/<region>/<kag_class>')
def get_leaderboard(region, kag_class):
    if region_validator(region) and kag_class_validator(kag_class):
        leaderboard = db.get_many_rows_as_models(LeaderboardRow, queries.get_leaderboard, (region, kag_class))
        return jsonify([lr.to_dict() for lr in leaderboard])
    else:
        flask.abort(400)

@app.route('/create_match', methods=['POST'])
def create_match():
    utils.log("create_match called")
    if not is_req_ip_whitelisted(flask.request):
        flask.abort(403)

    data = flask.request.get_json()
    if not data:
        utils.log("No data supplied")
        flask.abort(400)

    utils.log("Request data", data)
    try:
        match = MatchHistory.from_dict(data)
        match_stats = data["stats"]
    except Exception as e:
        utils.log("ERROR couldn't deserialize match: " + str(e))
        flask.abort(400)

    if match.validate():
        utils.log("Valid match.")
        process_match(match, match_stats)
        return jsonify("true")
    else:
        utils.log("Invalid match")
        flask.abort(400)

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

def process_match(match, match_stats):
    utils.log("Processing match " + match.serialize())
    utils.log("Creating match...")
    match.db_create_or_update()
    utils.log("Updating players...")
    update_players(match, match_stats)
    utils.log("Updating ratings...")
    update_ratings(match)

def update_players(match, match_stats):
    for (username, player_stats) in [(match.player1, match_stats["player1stats"]),
                                     (match.player2, match_stats["player2stats"])]:
        player = Player.db_get_or_create(username)
        player.nickname = player_stats["nickname"]
        player.clantag  = player_stats["clantag"]
        player.head     = int(player_stats["head"])
        player.gender   = int(player_stats["gender"])
        player.db_create_or_update()

def update_ratings(match):
    pr1 = PlayerRating.db_get_or_create(match.player1, match.region, match.kag_class)
    pr2 = PlayerRating.db_get_or_create(match.player2, match.region, match.kag_class)

    (p1_new_rating, p2_new_rating) = ratings.get_new_ratings(pr1.rating, pr2.rating, match.player1_score, match.player2_score)
    utils.log("Old ratings {0} {1}".format(pr1.rating, pr2.rating))
    utils.log("New ratings {0} {1}".format(p1_new_rating, p2_new_rating))

    pr1.rating = p1_new_rating
    pr2.rating = p2_new_rating

    if match.player1_score > match.player2_score:
        pr1.wins += 1
        pr2.losses += 1
    else:
        pr1.losses += 1
        pr2.wins += 1

    pr1.db_create_or_update()
    pr2.db_create_or_update()

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

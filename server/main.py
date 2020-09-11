import codecs
import flask
import os
import json
import re
import urllib
from collections import defaultdict
from flask_cors import CORS
from flask import jsonify
from flask_caching import Cache
import server.queries as queries
import server.ratings as ratings
import server.utils as utils
import server.db_backend as db_backend
from server.constants import DEFAULT_RATING, VALID_KAG_CLASSES

IP_WHITELIST = set()
with open("ip_whitelist.txt", "r") as whitelist:
    for ip in whitelist:
        IP_WHITELIST.add(ip.strip())

app = flask.Flask(__name__, static_folder="static")
cfg_env = "KAGLADDER_CONFIG_FILE"
if cfg_env not in os.environ:
    utils.log("WARN You must provide a path to a config file in ${}".format(cfg_env))
else:
    utils.log("Using config file: " + os.environ[cfg_env])

app.config.from_envvar(cfg_env)
db_backend.setup(
        app.config["DB_HOST"],
        app.config["DB_USER"],
        app.config["DB_PASSWORD"],
        app.config["DB_DB"],
        )

CORS(app) # enable cross-origin requests

# Certain endpoints always provide the same response and so they can be cached forever
eternal_cache = Cache(app, config={'CACHE_TYPE': 'simple'})

# Other endpoints change only when a new match is inserted, and thus can be cached most of the time
cache = Cache(app, config={'CACHE_TYPE': 'simple'})

def catch_value_error(func, *params):
    try:
        result = func(*params)
        return result
    except ValueError as e:
        utils.log("ValueError", e)
        flask.abort(400)

def default_handler(query, params_dict={}, one_result=False):
    #utils.log("default handler", params_dict, one_result)
    results = catch_value_error(query.run, params_dict)

    if one_result:
        if len(results):
            return jsonify(results[0])
        else:
            return jsonify("null")
    else:
        return jsonify(results)

@app.route('/player/<username>')
@cache.memoize()
def get_player(username):
    """Returns information about a specific player.
    Args:
        username (str): the player's username
    """
    player_results = catch_value_error(queries.get_player.run,  {"username": username})
    player_data = None

    if len(player_results):
        player_data = player_results[0]
    else:
        return jsonify("null")

    ratings_results = catch_value_error(queries.get_player_ratings.run,  {"username": username})
    ratings_data = {"EU": {}, "AUS": {}, "US": {}}

    for rat in ratings_results:
        ptr = ratings_data[rat["region"]]
        ptr[rat["kag_class"]] = {"rating": rat["rating"], "wins": rat["wins"], "losses": rat["losses"]}

    data = {}
    utils.add_dict(data, player_data)
    utils.add_dict(data, {"ratings": ratings_data})
    return jsonify(data)

@app.route('/player_names/')
@cache.memoize()
def get_player_names():
    """Returns a list of all player usernames and nicknames
    """
    return default_handler(queries.get_player_names)

@app.route('/match/<int:match_id>')
@eternal_cache.memoize()
def get_match(match_id):
    """Returns information about a specific match.
    Args:
        match_id (int): the id of the match
    """
    return default_handler(queries.get_match_history, {"id": match_id}, one_result=True)

@app.route('/match_round_stats/<int:match_id>')
@eternal_cache.memoize()
def get_match_round_stat(match_id):
    """Returns the stats for each round in the given match.
    Args:
        match_id (int): the id of the match
    """
    return default_handler(queries.get_match_round_stats, {"match_id": match_id})

@app.route('/match_counter')
@cache.memoize()
def get_match_counter():
    """Returns the most recently used match id. Useful for detecting when a new match has occurred.
    """
    return default_handler(queries.get_most_recent_match_id, one_result=True)

@app.route('/player_match_history/<username>')
@cache.memoize()
def get_player_match_history(username):
    """Returns the match history for a specific player.
    Args: 
        username (str): The player's username.
    """
    return default_handler(queries.get_player_match_history, {"username": username})

@app.route('/recent_match_history')
@app.route('/recent_match_history/<int:limit>')
@cache.memoize()
def get_recent_match_history(limit=50):
    """Returns a list of the most recently played matches.
    Args:
        limit (int): maximum number of results
    """
    return default_handler(queries.get_recent_match_history, {"limit": limit})

@app.route('/leaderboard/<region>/<kag_class>')
@cache.memoize()
def get_leaderboard(region, kag_class):
    """Returns the leaderboard for a given region and class.

    Args:
        region (str): one of ["EU", "US", "AUS"]
        kag_class (str): one of ["archer", "builder", "knight"]
    """
    return default_handler(queries.get_leaderboard, {"region": region, "kag_class": kag_class})

@app.route('/clans')
@cache.memoize()
def get_clans():
    """Returns a list of clans and players in them.
    """
    data = queries.get_clans.run()
    clans = defaultdict(list)

    for item in data:
        #utils.log("item", item)
        clans[item["clantag"]].append(item["username"])

    result = []
    for (clantag, members) in clans.items():
        result.append({"clan": clantag, "members": members})

    return jsonify(result)

@app.route('/clan/<clantag>')
def get_clan(clantag):
    """Returns info about a specific clan
    """
    utils.log("get_clan", clantag)
    members = queries.get_clan_members.run({"clantag": clantag})
    info_results = queries.get_clan_info.run({"clantag": clantag})
    utils.log("members", members)
    utils.log("info_results", info_results)

    result = {}
    result["members"] = members

    if len(info_results):
        info = info_results[0]
        for (key, val) in info.items():
            result[key] = val

    return jsonify(result)

@app.route('/create_match', methods=['POST'])
def create_match():
    """Creates a new match and adds it to the database.
    """
    if not is_req_ip_whitelisted(flask.request):
        flask.abort(403)

    match = flask.request.get_json()
    if not match:
        utils.log("No match data supplied")
        flask.abort(400)

    utils.log("Processing match " + str(match))
    rating_changes = get_rating_changes(match)
    utils.log("Rating changes:", rating_changes)

    cache.clear()

    utils.log("Creating match...")
    insert_match(match, rating_changes)

    utils.log("Updating players...")
    update_players(match)

    utils.log("Updating ratings...")
    update_ratings(match, rating_changes)

    match_id = queries.get_most_recent_match_id.run()[0]["id"]

    utils.log("Match id is {}. Creating rounds...".format(match_id))
    insert_rounds(match, match_id)

    return jsonify({"player1_rating_change": rating_changes[0], "player2_rating_change": rating_changes[1]})

@app.route('/coinchange', methods=['POST'])
def coinchange():
    """Alters the amount of coins a player has
    """
    if not is_req_ip_whitelisted(flask.request):
        flask.abort(403)

    params = flask.request.get_json()
    if not params:
        utils.log("No params supplied")
        flask.abort(400)

    username = params["username"]
    amount = int(params["amount"])

    queries.touch_player.run({"username": username})
    queries.add_coins.run({"coinamount": amount, "username": username})
    data = queries.get_player_coins.run({"username": username})
    return jsonify(data[0])

@app.route('/')
@eternal_cache.memoize()
def get_homepage():
    dont_document = set(["/", "/static", "/create_match", "/coinchange"])
    endpoint_info = {}
    endpoint_variations = defaultdict(list)

    for rule in app.url_map.iter_rules():
        parts = rule.rule.split("/")
        ep = "/" + parts[1]

        if ep in dont_document:
            continue

        ep_args = rule.arguments
        endpoint_variations[ep].append(list(ep_args))

        if ep not in endpoint_info:
            methods = list(rule.methods)

            doc = app.view_functions[rule.endpoint].__doc__ or ""
            (desc, args, returns) = parse_docstring(doc)

            endpoint_info[ep] = (methods, desc, args, returns)

    return flask.render_template("apidoc.html", endpoint_info=sorted(endpoint_info.items()),
                                 endpoint_variations=endpoint_variations);

@app.after_request
def add_header(response):
    response.cache_control.max_age = 60
    return response

def parse_docstring(doc):
    lines = {"desc": [], "args": [], "returns": []}
    block = "desc"

    for line in doc.splitlines():
        if block == "desc":
            if re.match("^\s*Args:", line):
                block = "args"
                continue
        elif block == "args":
            if re.match("^\s*Returns:", line):
                block = "returns"
                continue
        lines[block].append(line.strip())

    desc = "\n".join(lines["desc"])
    args = []
    returns = []

    for arg_line in lines["args"]:
        match = re.match("(\w+) \((\w+)\):(.*)", arg_line)
        if match:
            (arg_name, arg_type, arg_desc) = (match.group(1), match.group(2), match.group(3))
            args.append((arg_name, arg_type, arg_desc))

    for ret_line in lines["returns"]:
        match = re.match("(\w+) \((\w+)\):(.*)", arg_line)
        if match:
            (ret_name, ret_type, ret_desc) = (match.group(1), match.group(2), match.group(3))
            returns.append((ret_name, ret_type, ret_desc))

    return (desc, args, returns)


def is_local_ip_address(addr):
    parts = addr.split('.')
    if len(parts) >= 2 and parts[0] == "172" and 16 <= parts[1] and parts[1] <= 31:
        return True
    return False


def is_req_ip_whitelisted(req):
    if app.config.get("DISABLE_WHITELIST"):
        utils.log("Whitelist is disabled!")
        return True
    elif is_local_ip_address(req.remote_addr):
        return True
    elif req.remote_addr in IP_WHITELIST:
        return True
    else:
        utils.log("IP not whitelisted: %s", req.remote_addr)
        return False

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

def insert_rounds(match, match_id):
    num_rounds = len(match["rounds"]["roundstats"])
    if num_rounds == 0:
        utils.log("WARN 0 rounds in match")
    else:
        utils.log("{} to insert".format(num_rounds))
        for (round_index, round_data) in enumerate(match["rounds"]["roundstats"]):
            utils.log("Inserting round: {} {}".format(round_index, round_data))
            duration = int(round_data["endtime"]) - int(round_data["starttime"])
            winner = round_data["winner"]
            events = round_data["events"]
            queries.create_round_stats.run({
                "match_id": match_id,
                "round_index": round_index,
                "winner": winner,
                "duration": duration,
                "events": events
                })

def update_players(match):
    # Ensure players exist
    queries.touch_player.run({"username": match["player1"]})
    queries.touch_player.run({"username": match["player2"]})

    to_update = []
    if "stats" in match: 
        if "player1stats" in match["stats"]:
            to_update.append((match["player1"], match["stats"]["player1stats"]))
        if "player2stats" in match["stats"]:
            to_update.append((match["player2"], match["stats"]["player2stats"]))

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

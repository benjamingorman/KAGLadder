def generic_get_query(table_name, key_column_names):
    template = """SELECT * FROM {0} WHERE {1};"""
    where_part = " AND ".join(["{0}=%s".format(name) for name in key_column_names])
    return template.format(table_name, where_part)

def generic_create_or_update_query(table_name, column_names):
    template = """INSERT INTO {0} ({1})
VALUES ({2})
ON DUPLICATE KEY UPDATE
{3};"""
    columns_part = ", ".join([name for name in column_names])
    params_part = ", ".join(["%s" for name in column_names])
    last_part = ",\n".join(["{0}=VALUES({0})".format(name) for name in column_names])
    return template.format(table_name, columns_part, params_part, last_part)

# Player
get_player = generic_get_query("players", ["username"])
create_or_update_player = generic_create_or_update_query("players", ["username", "nickname", "clantag", "gender", "head"])

# MatchHistory
get_match_history = generic_get_query("match_history", ["region", "match_time"])
create_or_update_match_history = generic_create_or_update_query("match_history", ["region", "player1", "player2", "kag_class", "match_time", "player1_score", "player2_score", "duel_to_score"])

# PlayerRating
get_player_rating = generic_get_query("player_rating", ["username", "region", "kag_class"])
create_or_update_player_rating = generic_create_or_update_query(
        "player_rating", ["username", "region", "kag_class", "rating", "wins", "losses"])

# Other
get_player_ratings = generic_get_query("player_rating", ["username", "region"])
get_player_match_history = "SELECT * FROM match_history WHERE player1=%s OR player2=%s ORDER BY match_time DESC"
get_recent_match_history = "SELECT * FROM match_history ORDER BY match_time DESC LIMIT %s"
get_leaderboard = """SELECT players.username, players.nickname, players.clantag, players.gender, players.head, player_rating.rating, player_rating.wins, player_rating.losses
FROM player_rating INNER JOIN players ON players.username=player_rating.username
WHERE player_rating.region=%s AND player_rating.kag_class=%s
ORDER BY player_rating.rating DESC;
    """

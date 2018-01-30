get_player = "SELECT * FROM players WHERE username=%s"
get_match_history = "SELECT * FROM match_history WHERE region=%s AND match_time=%s"
get_player_rating = "SELECT * FROM player_rating WHERE username=%s AND region=%s AND kag_class=%s"
get_player_ratings = "SELECT * FROM player_rating WHERE username=%s AND region=%s"
get_player_match_history = "SELECT * FROM match_history WHERE player1=%s OR player2=%s"
get_recent_match_history = "SELECT * FROM match_history ORDER BY match_time DESC LIMIT %s"
get_leaderboard = """SELECT players.username, players.nickname, players.clantag, players.gender, players.head, player_rating.rating, player_rating.wins, player_rating.losses
FROM player_rating INNER JOIN players ON players.username=player_rating.username
WHERE player_rating.region=%s AND player_rating.kag_class=%s
ORDER BY player_rating.rating DESC;
    """
create_match_history = """
    INSERT INTO match_history (region, player1, player2, kag_class, match_time, player1_score, player2_score, duel_to_score)
    VALUES                    (%s,     %s,      %s,      %s,        %s,         %s,            %s,            %s)
    """
update_player_rating = """
    REPLACE INTO player_rating (username, region, kag_class, rating, wins, losses)
    VALUES                     (%s,       %s,     %s,        %s,     %s,   %s)
    """
update_player = """
    REPLACE INTO players       (username, nickname, clantag, gender, head)
    VALUES                     (%s,       %s,       %s,      %s,     %s)
    """

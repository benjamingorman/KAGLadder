from server.query import Query, Field, generic_create_or_update
import server.validators as validators

username = Field("username", validators.username)
nickname = Field("nickname", validators.nickname)
clantag  = Field("clantag", validators.clantag)
gender   = Field("gender", validators.gender, parser=int)
head     = Field("head", validators.head, parser=int)
coins     = Field("coins", validators.coins, parser=int)

id_field  = Field("id", validators.id_field, parser=int)
region    = Field("region", validators.region)
kag_class = Field("kag_class", validators.kag_class)
score     = Field("score", validators.score, parser=int)
rating    = Field("rating", validators.rating, parser=int)
rating_change = Field("rating_change", validators.is_int, parser=int)
match_time = Field("match_time", validators.match_time, parser=int)

wins      = score.rename("wins")
losses    = score.rename("losses")

limit     = Field("limit", validators.is_int)

round_index = Field("round_index", validators.round_index, parser=int)
duration = Field("duration", validators.is_int, parser=int)
events = Field("events", validators.events)

url_field = Field("url", validators.url)

player_row        = [username, nickname, clantag, gender, head, coins]
player_rating_row = [username, region, kag_class, rating, wins, losses]
match_history_row = [id_field, region, username.rename("player1"), username.rename("player2"), kag_class, match_time,
        score.rename("player1_score"), score.rename("player2_score"),
        rating_change.rename("player1_rating_change"), rating_change.rename("player2_rating_change")
        ]
round_stats_row = [id_field.rename("match_id"), round_index, username.rename("winner"), duration, events]
clan_row = [clantag, url_field.rename("badgeURL"), url_field.rename("forumURL"), username.rename("leader")]

get_player = Query(
        "SELECT * FROM players WHERE username=%s",
        [username],
        player_row
        )

get_player_names = Query(
        "SELECT username, nickname FROM players ORDER BY username",
        [],
        [username, nickname]
        )

create_player = Query(
        generic_create_or_update("players", ["username"]),        
        [username],
        []
        )

create_or_update_player = Query(
        generic_create_or_update("players", ["username", "nickname", "clantag", "gender", "head", "coins"]),        
        [username, nickname.optional(), clantag.optional(), gender.optional(), head.optional(), coins.optional()],
        []
        )

create_or_update_match_history = Query(
        generic_create_or_update("match_history", ["region", "player1", "player2", "kag_class", "match_time",
            "player1_score", "player2_score", "player1_rating_change", "player2_rating_change"
            ]),        
        [region, username.rename("player1"), username.rename("player2"), kag_class, match_time,
            score.rename("player1_score"), score.rename("player2_score"),
            rating_change.rename("player1_rating_change"), rating_change.rename("player2_rating_change")
            ],
        []
        )

create_round_stats = Query(
        """INSERT INTO round_stats (match_id, round_index, winner, duration, events)
                       VALUES      (%s,       %s,          %s,     %s,       %s);   
        """,
        [id_field.rename("match_id"), round_index, username.rename("winner"), duration, events],
        []
        )

get_player_rating = Query(
        "SELECT * FROM player_rating WHERE username=%s AND region=%s AND kag_class=%s",
        [username, region, kag_class],
        player_rating_row
        )

get_player_ratings = Query(
        "SELECT * FROM player_rating WHERE username=%s",
        [username],
        player_rating_row
        )

create_player_rating = Query(
        generic_create_or_update("player_rating", ["username", "region", "kag_class"]),
        [username, region, kag_class],
        []
        )

create_or_update_player_rating = Query(
        generic_create_or_update("player_rating", ["username", "region", "kag_class", "rating", "wins", "losses"]),
        [username, region, kag_class, rating.optional(), wins.optional(), losses.optional()],
        []
        )

get_match_history = Query(
        "SELECT * FROM match_history WHERE id=%s",
        [id_field],
        match_history_row
        )

get_most_recent_match_id = Query(
        "SELECT MAX(id) FROM match_history LIMIT 1",
        [],
        [id_field]
        )

get_match_round_stats = Query(
        "SELECT * FROM round_stats WHERE match_id=%s ORDER BY round_index;",
        [id_field.rename("match_id")],
        round_stats_row
        )

get_player_match_history = Query(
        "SELECT * FROM match_history WHERE player1=%s OR player2=%s ORDER BY match_time DESC",
        [username, username],
        match_history_row
        )

get_recent_match_history = Query(
        "SELECT * FROM match_history ORDER BY match_time DESC LIMIT %s",
        [limit],
        match_history_row
        )

get_leaderboard = Query(
        """SELECT players.username, players.nickname, players.clantag, players.gender, players.head, player_rating.rating, player_rating.wins, player_rating.losses
FROM player_rating INNER JOIN players ON players.username=player_rating.username
WHERE player_rating.region=%s AND player_rating.kag_class=%s
ORDER BY player_rating.rating DESC;
    """,
    [region, kag_class],
    [username, nickname, clantag, gender, head, rating, wins, losses]
    )

get_clan_members = Query(
        "SELECT username FROM players WHERE LTRIM(RTRIM(clantag))=%s;",
        [clantag],
        [username]
        )

get_clan_info = Query(
        "SELECT * FROM clan WHERE clantag=%s",
        [clantag],
        clan_row
        )

get_clans = Query(
        "SELECT username, LTRIM(RTRIM(clantag)) FROM players WHERE TRIM(IFNULL(clantag,'')) <> '';",
        [],
        [username, clantag]
        )

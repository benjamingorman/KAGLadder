module.exports = {
    apiBaseURL: "https://api.kagladder.com",
    leaderboard: (region, kag_class) => `leaderboard/${region}/${kag_class}`,
    matchHistory: `recent_match_history`,
    players: (username) => `players/${username}`,
    playerMatchHistory: (username) => `player_match_history/${username}`,
    playerRatings: (username, region) => `player_ratings/${username}/${region}`,
}

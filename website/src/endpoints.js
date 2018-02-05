module.exports = {
    apiBaseURL: "https://api.kagladder.com",
    leaderboard: (region, kag_class) => `leaderboard/${region}/${kag_class}`,
    match: (matchID) => `match/${matchID}`,
    recentMatchHistory: `recent_match_history`,
    player: (username) => `player/${username}`,
    playerMatchHistory: (username) => `player_match_history/${username}`,
    clans: "clans",
}

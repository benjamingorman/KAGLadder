module.exports = {
    apiBaseURL: "https://api.kagladder.com",
    playerRatings: (username, region) => `player_ratings/${username}/${region}`,
    leaderboard: (region, kag_class) => `leaderboard/${region}/${kag_class}`,
}

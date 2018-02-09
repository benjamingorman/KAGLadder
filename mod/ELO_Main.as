#include "Logging.as";
#include "ELO_Common.as";
#include "PlayerInfo.as"
#include "RulesCore.as";
#include "TCPR_Common.as";

const string DEFAULT_CHALLENGE_CLASS = "knight";
const u8 DEFAULT_DUEL_TO_SCORE = 5;
const u8 DEFAULT_DUEL_TO_SCORE_SHORT = 2;
const u8 PLAYER_COUNT_FOR_SHORT_DUEL = 6;
const u8 MAX_PLAYER_CHALLENGES = 10;

RatedChallenge[] CHALLENGE_QUEUE;
RatedMatch CURRENT_MATCH;
RatedMatchStats CURRENT_MATCH_STATS;
TCPR::Request[] REQUESTS;

void onInit(CRules@ this) {
    log("onInit", "init rules");
    this.set_bool("VAR_MATCH_IN_PROGRESS", false);
    this.addCommandID("CMD_SYNC_CHALLENGE_QUEUE");
    this.addCommandID("CMD_SYNC_CURRENT_MATCH");
}

void onTick(CRules@ this) {
    if (getNet().isServer()) {
        TCPR::update(@REQUESTS);
            
        if (getGameTime() % 30 == 0) {
            // Deal with players leaving the server etc.
            if (isRatedMatchInProgress())
                checkCurrentMatchStillValid();
            checkChallengesStillValid();
        }
    }
}

void onTCPRConnect(CRules@ this) {
    /*
    requestPlayerRatings("Eluded");
    requestSaveMatch(getTestMatch());
    */
}

void onStateChange(CRules@ this, const u8 oldState) {
    if (!getNet().isServer())
        return;

    if (isRatedMatchInProgress() && this.getCurrentState() == GAME_OVER && oldState != GAME_OVER) {
        OnGameOver();
    }
}

void OnGameOver() {
    int winningTeam = getRules().getTeamWon();
    log("onGameOver", "Detected game over! Winning team: " + winningTeam);

    CPlayer@ player1 = getPlayerByUsername(CURRENT_MATCH.player1);
    CPlayer@ player2 = getPlayerByUsername(CURRENT_MATCH.player2);

    if (player1 is null || player2 is null) {
        cancelCurrentMatch();
        return;
    }

    // Work out which player won
    if (player1.getTeamNum() == winningTeam) {
        CURRENT_MATCH.player1Score++;
    }
    else if (player2.getTeamNum() == winningTeam) {
        CURRENT_MATCH.player2Score++;
    }
    else {
        // It's a draw
    }

    if (CURRENT_MATCH.player1Score == CURRENT_MATCH.duelToScore
        || CURRENT_MATCH.player2Score == CURRENT_MATCH.duelToScore) {
        finishCurrentMatch();
    }

    syncCurrentMatch();
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player) {
    log("onNewPlayerJoin", player.getUsername());
    requestPlayerRatings(player.getUsername()); 
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params) {
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player) {
    if (player is null)
        return true;

    log("onServerProcessChat", "Got: " + text_in);
    string[] tokens = tokenize(text_in);

    if (tokens.length() == 0) {
        return true;
    }
    else if (tokens[0] == "!debug") {
        handleChatCommandDebug(player);
    }
    else if (tokens[0] == "!clearchallenges") {
        handleChatCommandClearChallenges(player);
    }
    else if (tokens[0] == "!help") {
        handleChatCommandHelp(player);
    }
    else if (tokens[0] == "!cancelmatch") {
        handleChatCommandCancelMatch(player);
    }
    else if (tokens[0] == "!cancelchallenge") {
        handleChatCommandCancelChallenge(player, tokens);
    }
    else if (tokens[0] == "!accept") {
        handleChatCommandAccept(player, tokens);
    }
    else if (tokens[0] == "!challenge" || tokens[0] == "!chal" || tokens[0] == "chall") {
        handleChatCommandChallenge(player, tokens);
    }
    else if (tokens[0] == "!reject") {
        handleChatCommandReject(player, tokens);
    }
    else if (tokens[0] == "!ratings") {
        handleChatCommandRatings(player, tokens);
    }
    return true;
}

void handleChatCommandDebug(CPlayer@ player) {
    if (player.isMod()) {
        string msg = "challenge queue length: " + CHALLENGE_QUEUE.length;
        msg += "\nrequests length: " + REQUESTS.length;
        msg += "\ngame in progess: " + isRatedMatchInProgress();
        whisper(player, msg);
    }
}

void handleChatCommandHelp(CPlayer@ player) {
    log("handleChatCommandHelp", "Called");
    whisper(player, getModHelpString());
}

void handleChatCommandCancelMatch(CPlayer@ player) {
    log("handleChatCommandCancelMatch", "Called");
    bool playerIsInMatch = CURRENT_MATCH.player1 == player.getUsername() || CURRENT_MATCH.player2 == player.getUsername();
    if (isRatedMatchInProgress()) {
        if (player.isMod() || playerIsInMatch) {
            cancelCurrentMatch();
        }
        else {
            whisper(player, "You don't have permission to cancel this match.");
        }
    }
    else {
        whisper(player, "There is no match in progress.");
    }
}

void handleChatCommandCancelChallenge(CPlayer@ player, string[]@ tokens) {
    log("handleChatCommandCancelChallenge", "Called");

    int[] challenges = findPlayerChallenges(player.getUsername());

    if (challenges.length == 0) {
        whisper(player, "You haven't challenged anyone yet!");
    }
    else if (challenges.length == 1) {
        CHALLENGE_QUEUE.removeAt(challenges[0]);
        syncChallengeQueue();
        whisper(player, "Cancelled your challenge.");
    }
    else if (tokens.length > 1) {
        // >= 1 challenge; need to be specific about which one to cancel
        string otherPlayerIdent = tokens[1];
        CPlayer@ otherPlayer = getPlayerByIdent(otherPlayerIdent);

        if (otherPlayer !is null) {
            int challengeIndex = findChallengeBetweenPlayers(player.getUsername(), otherPlayer.getUsername());
            if (challengeIndex != -1) {
                CHALLENGE_QUEUE.removeAt(challengeIndex);
                syncChallengeQueue();
                whisper(player, "Cancelled your challenge against: " + otherPlayer.getUsername());
            }
        }
        else {
            whisper(player, "You haven't challenged anyone named: " + otherPlayerIdent);
        }
    }
    else {
        whisper(player, "Be more specific: e.g. !cancelchallenge Geti");
    }
}

void handleChatCommandClearChallenges(CPlayer@ player) {
    log("handleChatCommandClearChallenges", "Called");
    if (player.isMod()) {
        CHALLENGE_QUEUE.clear();
        syncChallengeQueue();
        whisper(player, "Challenges cleared.");
    }
    else {
        whisper(player, "You don't have permission to do that");
    }
}

bool handleChatCommandChallenge(CPlayer@ player, string[]@ tokens) {
    log("handleChatCommandChallenge", "Called");

    if (tokens.length == 1) {
        whisper(player, "Be more specific: for example !challenge Geti");
        return false;
    }

    string otherPlayerIdent = tokens[1];
    string kagClass = DEFAULT_CHALLENGE_CLASS;
    int duelToScore = getDefaultDuelToScore();

    for (int i=2; i <= 3; ++i) {
        if (tokens.length > i) {
            if (isStringPositiveInteger(tokens[i])) {
                duelToScore = parseInt(tokens[i]);
            }
            else {
                kagClass = tokens[i];
            }
        }
    }

    string errMsg;
    bool success;

    // Allow "!challenge all"
    if (otherPlayerIdent == "all") {
        for (int i=0; i < getPlayersCount(); ++i) {
            CPlayer@ other = getPlayer(i);
            if (player is other)
                continue;

            success = handleChallenge(player, other.getUsername(), kagClass, duelToScore, errMsg);

            if (!success)
                break;
        }
    }
    else {
        success = handleChallenge(player, otherPlayerIdent, kagClass, duelToScore, errMsg);
    }

    if (success) {
        whisper(player, "Challenge sent.");
    }
    else {
        log("handleChatCommandChallenge", "Invalid challenge: " + errMsg);
        whisper(player, "Your challenge was invalid: " + errMsg);
    }

    return true;
}

bool handleChallenge(CPlayer@ player, string otherPlayerIdent, string kagClass, int duelToScore, string &out errMsg) {
    RatedChallenge chal();
    chal.challenger = player.getUsername();
    chal.challenged = "";
    chal.kagClass = kagClass;
    chal.duelToScore = duelToScore;

    CPlayer@ challengedPlayer = getPlayerByIdent(otherPlayerIdent, errMsg);
    if (challengedPlayer is null) {
        return false;
    }
    else {
        chal.challenged = challengedPlayer.getUsername();
    }

    if (chal.isValid(errMsg)) {
        registerChallenge(player, chal);
        return true;
    }
    else {
        chal.debug();
        return false;
    }
}

void handleChatCommandReject(CPlayer@ player, string[]@ tokens) {
    log("handleChatCommandReject", "called");

    string ident = "";
    if (tokens.length >= 2) {
        ident = tokens[1];
    }

    int challengeIndex = -1;

    // Allow "!reject" if there's 1 challenge against them
    if (ident == "") {
        int count = countChallengesAgainstPlayer(player.getUsername());
        if (count == 0) {
            whisper(player, "You haven't been challenged by anyone.");
        }
        else if (count == 1) {
            challengeIndex = findFirstChallengeAgainst(player.getUsername());
        }
        else {
            whisper(player, "Be more specific: for example !reject Geti");
        }
    }
    else {
        string errMsg;
        CPlayer@ otherPlayer = getPlayerByIdent(ident, errMsg);
        if (otherPlayer is null) {
            whisper(player, errMsg);
        }
        else {
            challengeIndex = findChallengeBetweenPlayers(otherPlayer.getUsername(), player.getUsername());
            if (challengeIndex == -1) 
                whisper(player, "You haven't been challenged by that person");
        }
    }

    if (challengeIndex != -1) {
        CHALLENGE_QUEUE.removeAt(challengeIndex);
        syncChallengeQueue();
        whisper(player, "Challenge rejected.");
    }
}

void handleChatCommandAccept(CPlayer@ player, string[]@ tokens) {
    log("handleChatCommandAccept", "called");

    string ident = "";
    if (tokens.length >= 2)
        ident = tokens[1];

    if (isRatedMatchInProgress()) {
        whisper(player, "Wait until the current duel is finished!");
    }
    else {
        int challengeIndex = -1;
        string otherPlayerName;

        // allow "!accept" if there's only 1 challenge against them
        if (ident == "") {
            int count = countChallengesAgainstPlayer(player.getUsername());
            if (count == 0) {
                whisper(player, "You haven't been challenged by anyone.");
            }
            else if (count == 1) {
                challengeIndex = findFirstChallengeAgainst(player.getUsername());
                otherPlayerName = CHALLENGE_QUEUE[challengeIndex].challenger;
            }
            else {
                whisper(player, "Be more specific: for example !accept Geti");
            }
        }
        else {
            string errMsg;
            CPlayer@ otherPlayer = getPlayerByIdent(ident, errMsg);
            if (otherPlayer is null) {
                whisper(player, errMsg);
            }
            else {
                otherPlayerName = otherPlayer.getUsername();
                challengeIndex = findChallengeBetweenPlayers(otherPlayer.getUsername(), player.getUsername());
                if (challengeIndex == -1) 
                    whisper(player, "You haven't been challenged by that person");
            }
        }

        if (challengeIndex != -1) {
            startMatch(CHALLENGE_QUEUE[challengeIndex]);
            CHALLENGE_QUEUE.removeAt(challengeIndex);
            deleteAllPlayerChallenges(otherPlayerName);
            syncChallengeQueue();
            //debugChallengeQueue();
        }
    }
}

void handleChatCommandRatings(CPlayer@ player, string[]@ tokens) {
    PlayerRatings@ ratings = getStoredPlayerRatings(player.getUsername());

    if (ratings is null) {
        whisper(player, "Your ratings couldn't be loaded.");
    }
    else {
        whisperAll("{player}'s ratings: knight {rating_knight} ({wins_knight}-{losses_knight}), archer {rating_archer} ({wins_archer}-{losses_archer}), builder {rating_builder} ({wins_builder}-{losses_builder})"
            .replace("{player}", player.getUsername())
            .replace("{rating_knight}", ""+ratings.rating_knight)
            .replace("{wins_knight}", ""+ratings.wins_knight)
            .replace("{losses_knight}", ""+ratings.losses_knight)
            .replace("{rating_archer}", ""+ratings.rating_archer)
            .replace("{wins_archer}", ""+ratings.wins_archer)
            .replace("{losses_archer}", ""+ratings.losses_archer)
            .replace("{rating_builder}", ""+ratings.rating_builder)
            .replace("{wins_builder}", ""+ratings.wins_builder)
            .replace("{losses_builder}", ""+ratings.losses_builder)
            );
    }
}

int[] findPlayerChallenges(string player) {
    int[] result;
    for (int i=0; i < CHALLENGE_QUEUE.length; ++i) {
        RatedChallenge chal = CHALLENGE_QUEUE[i];
        if (chal.challenger == player)
            result.push_back(i);
    }
    return result;
}

int[] findChallengesAgainstPlayer(string player) {
    int[] result;
    for (int i=0; i < CHALLENGE_QUEUE.length; ++i) {
        RatedChallenge chal = CHALLENGE_QUEUE[i];
        if (chal.challenged == player)
            result.push_back(i);
    }
    return result;
}

// Returns the index of the challenge found in CHALLENGE_QUEUE or -1 if not found
int findChallengeBetweenPlayers(string player1, string player2) {
    for (int i=0; i < CHALLENGE_QUEUE.length; ++i) {
        RatedChallenge chal = CHALLENGE_QUEUE[i];

        if (chal.challenger == player1 && chal.challenged == player2)
            return i;
    }

    return -1;
}

// Returns the index of the first challenge found against the given player
int findFirstChallengeAgainst(string player) {
    int[] challenges = findChallengesAgainstPlayer(player);
    if (challenges.length == 0) {
        return -1;
    }
    else {
        return challenges[0];
    }
}

int countPlayerChallenges(string player) {
    return findPlayerChallenges(player).length;
}

int countChallengesAgainstPlayer(string player) {
    return findChallengesAgainstPlayer(player).length;
}

void deleteAllPlayerChallenges(string player) {
    for (int i = (CHALLENGE_QUEUE.length-1); i >= 0; --i) {
        RatedChallenge chal = CHALLENGE_QUEUE[i];
        if (chal.challenger == player)
            CHALLENGE_QUEUE.removeAt(i);
    }
}

void registerChallenge(CPlayer@ player, RatedChallenge chal) {
    log("registerChallenge", "called");
    chal.debug();
    int existingChallengeIndex = findChallengeBetweenPlayers(chal.challenger, chal.challenged);

    string errMsg;
    if (!chal.isValid(errMsg)) {
        whisper(player, "Your challenge is invalid: " + errMsg);
    }
    else if (countPlayerChallenges(chal.challenger) >= MAX_PLAYER_CHALLENGES) {
        whisper(player, "You can't issue more than " + MAX_PLAYER_CHALLENGES + " challenges.");
    }
    else if (existingChallengeIndex >= 0) {
        whisper(player, "You've already challenged that person. The old challenge will be removed.");
        CHALLENGE_QUEUE.removeAt(existingChallengeIndex);
        CHALLENGE_QUEUE.push_back(chal);
        syncChallengeQueue();
    }
    else {
        CHALLENGE_QUEUE.push_back(chal);
        syncChallengeQueue();
    }
}

void startMatch(RatedChallenge chal) {
    string errMsg;
    if (isRatedMatchInProgress()) {
        log("startMatch", "ERROR match is already in progress");
    }
    else if (!chal.isValid(errMsg)) {
        log("startMatch", "ERROR couldn't start match, invalid challenge: " + errMsg);
        whisperAll("Something went wrong! Match couldn't be started.");
    }
    else {
        CURRENT_MATCH = RatedMatch(chal.challenger, chal.challenged, chal.kagClass, chal.duelToScore);
        CPlayer@ player1 = getPlayerByUsername(CURRENT_MATCH.player1);
        CPlayer@ player2 = getPlayerByUsername(CURRENT_MATCH.player2);

        // Change classes appropriately
        RulesCore@ core;
        getRules().get("core", @core);
        PlayerInfo@ p1Info = core.getInfoFromName(CURRENT_MATCH.player1);
        PlayerInfo@ p2Info = core.getInfoFromName(CURRENT_MATCH.player2);

        if (p1Info is null || p2Info is null) {
            log("startMatch", "ERROR either p1Info or p2Info is null");
            cancelCurrentMatch();
        }
        else {
            log("startMatch", "Changing classes to " + CURRENT_MATCH.kagClass);
            player1.lastBlobName = CURRENT_MATCH.kagClass;
            player2.lastBlobName = CURRENT_MATCH.kagClass;
            p1Info.blob_name = CURRENT_MATCH.kagClass;
            p2Info.blob_name = CURRENT_MATCH.kagClass;
        }

        CURRENT_MATCH_STATS = RatedMatchStats();
        CURRENT_MATCH_STATS.setPlayerStats(player1, 1);
        CURRENT_MATCH_STATS.setPlayerStats(player2, 2);

        allSpec();
        player1.server_setTeamNum(0);
        player2.server_setTeamNum(1);
        LoadMapCycle("mapcycle_" + CURRENT_MATCH.kagClass + ".cfg");
        LoadNextMap();

        syncMatchInProgress(true);
        syncCurrentMatch();
        whisperAll("Starting match! " + CURRENT_MATCH.player1 + " vs. " + CURRENT_MATCH.player2);
        CURRENT_MATCH.debug();
    }
}

// Cancels the current match if something unexpected happened. Results are not saved.
void cancelCurrentMatch() {
    log("cancelCurrentMatch", "called");
    syncMatchInProgress(false);
    whisperAll("Cancelling current match.");
}

// Called after the final round of the match 
void finishCurrentMatch() {
    log("finishCurrentMatch", "called");
    syncMatchInProgress(false);
    saveCurrentMatch();

    // Summary
    u16 rating_p1 = getPlayerRating(CURRENT_MATCH.player1, CURRENT_MATCH.kagClass);
    u16 rating_p2 = getPlayerRating(CURRENT_MATCH.player2, CURRENT_MATCH.kagClass);
    int change_p1, change_p2;
    predictRatingChanges(CURRENT_MATCH, rating_p1, rating_p2, change_p1, change_p2);
    string str_change_p1 = (change_p1 > 0 ? "+" : "") + change_p1;
    string str_change_p2 = (change_p2 > 0 ? "+" : "") + change_p2;

    string winner = CURRENT_MATCH.player1;
    if (CURRENT_MATCH.player2Score > CURRENT_MATCH.player1Score)
        winner = CURRENT_MATCH.player2;
    whisperAll("WINNER: " + winner);
    whisperAll("Predicted rating changes: " + CURRENT_MATCH.player1 + " " + str_change_p1
              + ", " + CURRENT_MATCH.player2 + " " + str_change_p2);
    requestPlayerRatings(CURRENT_MATCH.player1);
    requestPlayerRatings(CURRENT_MATCH.player2);
}

void saveCurrentMatch() {
    log("saveCurrentMatch", "called");
    requestSaveMatch(CURRENT_MATCH, CURRENT_MATCH_STATS);
}

void requestPlayerRatings(string username) {
    TCPR::Request req("playerratings", @onPlayerRatingsRequestComplete);
    req.setParam("username", username);
    TCPR::makeRequest(@REQUESTS, @req);
}

void onPlayerRatingsRequestComplete(TCPR::Request req, string response) {
    string username;
    req.params.get("username", username);
    log("onPlayerRatingsRequestComplete", username + ": " + response);
    getRules().set_string(getSerializedPlayerRatingsRulesProp(username), response); 
    getRules().Sync(getSerializedPlayerRatingsRulesProp(username), true);
}

void requestSaveMatch(RatedMatch match, RatedMatchStats stats) {
    TCPR::Request req("savematch", @onSaveMatchRequestComplete);
    req.setParam("player1", match.player1);
    req.setParam("player2", match.player2);
    req.setParam("kagclass", match.kagClass);
    req.setParam("starttime", ""+match.startTime);
    req.setParam("player1score", ""+match.player1Score);
    req.setParam("player2score", ""+match.player2Score);
    req.setParam("dueltoscore", ""+match.duelToScore);
    req.setParam("stats", stats.serialize());
    TCPR::makeRequest(@REQUESTS, @req);
}

void onSaveMatchRequestComplete(TCPR::Request req, string response) {
    log("onSaveMatchRequestComplete", "Response: " + response);
}

string serializeChallengeQueue() {
    string ser = "<challengequeue>";
    for (int i=0; i < CHALLENGE_QUEUE.length(); ++i) {
        RatedChallenge chal = CHALLENGE_QUEUE[i];
        ser += chal.serialize();
    }
    ser += "</challengequeue>";
    return ser;
}

void syncMatchInProgress(bool val) {
    log("syncMatchInProgress", "Called");
    getRules().set_bool("VAR_MATCH_IN_PROGRESS", val);
    getRules().Sync("VAR_MATCH_IN_PROGRESS", true);
}

void syncChallengeQueue() {
    log("syncChallengeQueue", "Called");
    CBitStream params;
    params.write_string(serializeChallengeQueue());
    getRules().SendCommand(getRules().getCommandID("CMD_SYNC_CHALLENGE_QUEUE"), params, true);
}

void syncCurrentMatch() {
    log("syncCurrentMatch", "Called");
    CBitStream params;
    params.write_string(CURRENT_MATCH.serialize());
    getRules().SendCommand(getRules().getCommandID("CMD_SYNC_CURRENT_MATCH"), params, true);
}

// Puts everyone into spectator
void allSpec() {
    int specTeam = getRules().getSpectatorTeamNum();

    for (int i=0; i < getPlayerCount(); i++) {
        CPlayer@ p = getPlayer(i);
        if (p is null || p.getTeamNum() == specTeam)
            continue;
        p.server_setTeamNum(specTeam);
    }
}

RatedMatch getTestMatch() {
    RatedMatch testMatch;
    testMatch.player1 = "Alice";
    testMatch.player2 = "Bob";
    testMatch.kagClass = "knight";
    testMatch.duelToScore = 5;
    testMatch.player1Score = 5;
    testMatch.player2Score = 1;
    testMatch.startTime = Time();
    return testMatch;
}

int getDefaultDuelToScore() {
    if (getPlayersCount() >= PLAYER_COUNT_FOR_SHORT_DUEL) {
        return DEFAULT_DUEL_TO_SCORE_SHORT;
    }
    else {
        return DEFAULT_DUEL_TO_SCORE;
    }
}

void debugHeads() {
    CPlayer@ eluded = getPlayerByUsername("Eluded");
    if (eluded !is null) {
        log("onTick", "Eluded head: " + eluded.getHead());
        log("onTick", "Eluded sex: " + eluded.getSex());
        log("onTick", "Eluded nick: " + eluded.getCharacterName());
    }
}

void debugChallengeQueue() {
    for (int i=0; i < CHALLENGE_QUEUE.length; ++i) {
        log("debugChallengeQueue", "CHALLENGE QUEUE DEBUG " + i);
        CHALLENGE_QUEUE[i].debug();
    }
}

void checkCurrentMatchStillValid() {
    // Check there's 1 player in each team
    int team0Players = 0;
    int team1Players = 0;
    for (int i=0; i < getPlayersCount(); ++i) {
        CPlayer@ player = getPlayer(i);
        if (player.getTeamNum() == 0) {
            team0Players++;
        }
        else if (player.getTeamNum() == 1) {
            team1Players++;
        }
    }

    if (!(team0Players == 1 && team1Players == 1)) {
        cancelCurrentMatch();
    }
}

void checkChallengesStillValid() {
    string errMsg;
    bool changed = false;

    for (int i=CHALLENGE_QUEUE.length-1; i >= 0; --i) {
        if (!CHALLENGE_QUEUE[i].isValid(errMsg)) {
            CHALLENGE_QUEUE.removeAt(i);
            changed = true;
        }
    }

    if (changed)
        syncChallengeQueue();
}

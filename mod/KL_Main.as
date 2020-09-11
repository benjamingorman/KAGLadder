#include "PlayerInfo.as"
#include "RulesCore.as";
#include "Logging.as";
#include "KL_Common.as";
#include "KL_Types.as";
#include "KL_BettingOdds.as";
#include "TCPR_Common.as";
#include "XMLParser.as";

const string DEFAULT_CHALLENGE_CLASS = "knight";
const u8 DEFAULT_DUEL_TO_SCORE = 5;
const u8 DEFAULT_DUEL_TO_SCORE_SHORT = 2;
const u8 PLAYER_COUNT_FOR_SHORT_DUEL = 6;
const u8 MAX_PLAYER_CHALLENGES = 10;
const u8 CHALLENGE_QUEUE_WAIT_TIME_SECS = 10;
const u32 MAX_BET = 1000;
const u32 COINS_EARNED_PER_ROUND_WIN = 10;

RatedChallenge[] CHALLENGE_QUEUE;
RatedMatch CURRENT_MATCH;
RatedMatchStats CURRENT_MATCH_STATS;
RatedMatchRoundStats[] ROUND_STATS;
RatedMatchRoundStats CURRENT_ROUND_STATS;
RatedMatchBet[] CURRENT_MATCH_BETS;
TCPR::Request[] REQUESTS;

void onReload(CRules@ this) {
  log("onReload", "Testing savematch");
  testSaveMatch();
}

void onInit(CRules@ this) {
    log("onInit", "init rules");
    if (getNet().isServer()) {
        if (!checkMapsIncluded()) {
            log("onInit", "ERROR you forgot to include the needed maps.");
            shutdownServer();
        }
        else {
            LoadMapCycle("mapcycle_knight.cfg");
        }
    }

    this.set_bool("KL_DEBUG", false);
    this.set_bool("VAR_MATCH_IN_PROGRESS", false);
    this.set_u32("VAR_QUEUE_WAIT_UNTIL", 0); // game time when challenge queue will unlock
    this.set_u8("VAR_NEXT_MATCH_EVENT_ID", 0); // incrementing counter
    this.addCommandID("CMD_SYNC_CHALLENGE_QUEUE");
    this.addCommandID("CMD_SYNC_MATCH_BETS");
    this.addCommandID("CMD_SYNC_CURRENT_MATCH");
    this.addCommandID("CMD_SYNC_PLAYER_INFO");
    this.addCommandID("CMD_SYNC_PLAYER_COINS"); // use this after bets are complete
    this.addCommandID("CMD_SYNC_QUEUE_WAIT_UNTIL");
    this.addCommandID("CMD_TOGGLE_HELP");
    this.addCommandID("CMD_MATCH_EVENT");
}

void onRestart(CRules@ this) {
    // Called every time the map changes
    log("onRestart", "Called");
    CURRENT_ROUND_STATS = RatedMatchRoundStats();
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

void onStateChange(CRules@ this, const u8 oldState) {
    if (!getNet().isServer())
        return;

    if (isRatedMatchInProgress()
        && this.getCurrentState() == GAME_OVER
        && oldState != GAME_OVER) {
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
        CURRENT_ROUND_STATS.winner = player1.getUsername();
        CURRENT_MATCH.player1Score++;
    }
    else if (player2.getTeamNum() == winningTeam) {
        CURRENT_ROUND_STATS.winner = player2.getUsername();
        CURRENT_MATCH.player2Score++;
    }
    else {
        // It's a draw
    }

    CURRENT_ROUND_STATS.end_time = Time();
    ROUND_STATS.push_back(CURRENT_ROUND_STATS);

    if (CURRENT_MATCH.player1Score == CURRENT_MATCH.duelToScore
        || CURRENT_MATCH.player2Score == CURRENT_MATCH.duelToScore) {
        finishCurrentMatch();
    }
    else {
        syncCurrentMatch();
    }
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player) {
    log("onNewPlayerJoin", player.getUsername());
    if (!player.isBot()) {
        requestPlayerInfo(player.getUsername()); 
        syncChallengeQueue();
        syncMatchBets();
        syncCurrentMatch();
        syncQueueSystemWait();
        syncPlayerInfoToNewPlayer(player);
    }
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params) {
    if (cmd == this.getCommandID("CMD_MATCH_EVENT")) {
        //log("onCommand", "Got CMD_MATCH_EVENT");

        if (isRatedMatchInProgress()) {
            u8 evtID;
            if (params.saferead_u8(evtID)) {
                string prop = getMatchEventProp(evtID);
                MatchEvent evt;
                getRules().get(prop, evt);
                CURRENT_ROUND_STATS.logEvent(evt);
            }
        }
    }
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player) {
    if (player is null)
        return true;

    //log("onServerProcessChat", "Got: " + text_in);
    string[] tokens = tokenize(text_in);

    bool isMod = player.isMod();
    bool isDev = player.getUsername() == "Eluded";

    if (tokens.length() == 0) {
        return true;
    }
    else if (isDev && tokens[0] == "!debug") {
        handleChatCommandDebug(player);
    }
    else if (isDev && tokens[0] == "!testsavematch") {
        testSaveMatch();
    }
    else if (isMod && tokens[0] == "!addcoins") {
        handleChatCommandAddCoins(player, tokens);
    }
    else if (isMod && tokens[0] == "!shieldbot") {
        spawnShieldBot(player);
    }
    else if (isMod && tokens[0] == "!clearchallenges") {
        handleChatCommandClearChallenges(player);
    }
    else if (tokens[0] == "!help") {
        handleChatCommandHelp(player);
    }
    else if (tokens[0] == "!cancelmatch") {
        handleChatCommandCancelMatch(player);
    }
    else if (tokens[0] == "!cancelchallenge" || tokens[0] == "!cancelchal") {
        handleChatCommandCancelChallenge(player, tokens);
    }
    else if (tokens[0] == "!accept") {
        handleChatCommandAccept(player, tokens);
    }
    else if (tokens[0] == "!challenge" || tokens[0] == "!chal") {
        handleChatCommandChallenge(player, tokens);
    }
    else if (tokens[0] == "!reject") {
        handleChatCommandReject(player, tokens);
    }
    else if (tokens[0] == "!ratings") {
        handleChatCommandRatings(player, tokens);
    }
    else if (tokens[0] == "!bet") {
        handleChatCommandBet(player, tokens);
    }
    else if (tokens[0] == "!coins") {
        handleChatCommandCoins(player, tokens);
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

void handleChatCommandAddCoins(CPlayer@ player, string[]@ tokens) {
    if (player.isMod()) {
        if (tokens.length == 3) {
            string username = tokens[1];
            string amountString = tokens[2];
            int amount = parseInt(amountString);
            if (getPlayerByUsername(username) !is null) {
                requestCoinChange(username, amount);
            }
        }
    }
}


void handleChatCommandHelp(CPlayer@ player) {
    log("handleChatCommandHelp", "Called");
    CBitStream params;
    getRules().SendCommand(getRules().getCommandID("CMD_TOGGLE_HELP"), params, player);
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
        syncChallengeQueue();
    }
    else {
        success = handleChallenge(player, otherPlayerIdent, kagClass, duelToScore, errMsg);
        syncChallengeQueue();
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
    else if (challengedPlayer.isBot()) {
        errMsg = "Bots cannot be challenged.";
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

        bool canStart = false;

        if (challengeIndex != -1) {
            if (isQueueSystemWaiting()) {
                if (challengeIndex == 0) {
                    // it's the first challenge so allow them to start
                    canStart = true;
                }
                else if (CHALLENGE_QUEUE.length > 0) {
                    RatedChallenge chal0 = CHALLENGE_QUEUE[0];
                    uint secondsLeft = getQueueSystemWaitSecondsLeft();
                    whisperAll("You can't accept for {secondsLeft} more seconds. Waiting for {challenged} to accept {challenger}..."
                        .replace("{secondsLeft}", ""+secondsLeft)
                        .replace("{challenged}", chal0.challenged)
                        .replace("{challenger}", chal0.challenger)
                        );
                }
            }
            else {
                canStart = true;
            }
        }

        if (canStart) {
            RatedChallenge chal = CHALLENGE_QUEUE[challengeIndex];
            CHALLENGE_QUEUE.removeAt(challengeIndex);
            deleteAllPlayerChallenges(otherPlayerName);
            syncChallengeQueue();
            startMatch(chal);
            //debugChallengeQueue();
        }
    }
}

void handleChatCommandRatings(CPlayer@ player, string[]@ tokens) {
    RatedPlayerInfo@ info = getStoredPlayerInfo(player.getUsername());

    if (info is null) {
        whisper(player, "Your ratings couldn't be loaded.");
    }
    else {
        whisperAll("{player}'s ratings: knight {rating_knight} ({wins_knight}-{losses_knight}), archer {rating_archer} ({wins_archer}-{losses_archer}), builder {rating_builder} ({wins_builder}-{losses_builder})"
            .replace("{player}", player.getUsername())
            .replace("{rating_knight}", ""+info.rating_knight)
            .replace("{wins_knight}", ""+info.wins_knight)
            .replace("{losses_knight}", ""+info.losses_knight)
            .replace("{rating_archer}", ""+info.rating_archer)
            .replace("{wins_archer}", ""+info.wins_archer)
            .replace("{losses_archer}", ""+info.losses_archer)
            .replace("{rating_builder}", ""+info.rating_builder)
            .replace("{wins_builder}", ""+info.wins_builder)
            .replace("{losses_builder}", ""+info.losses_builder)
            );
    }
}

void handleChatCommandBet(CPlayer@ player, string[]@ tokens) {
    string syntaxExample = "Invalid syntax. Bet like this: !bet Eluded 100";

    if (isRatedMatchInProgress()) {
        if (tokens.length < 3) {
            whisper(player, syntaxExample);
        }
        else {
            string bettedOnIdent = tokens[1];
            string betAmountString = tokens[2];

            // Allow !bet 100 Eluded
            if (parseInt(betAmountString) == 0) {
                bettedOnIdent = tokens[2];
                betAmountString = tokens[1];
            }

            string errMsg;
            CPlayer@ bettedOnPlayer = getPlayerByIdent(bettedOnIdent, errMsg);
            string bettedOnUsername;
            if (bettedOnPlayer is null) {
                whisper(player, errMsg);
            }
            else {
                bettedOnUsername = bettedOnPlayer.getUsername();
            }

            if (!(bettedOnUsername == CURRENT_MATCH.player1 || bettedOnUsername == CURRENT_MATCH.player2)) {
                whisper(player, "You can't bet on someone who's not fighting!");
            }
            else if (bettedOnUsername.length > 0 && isStringPositiveInteger(betAmountString)) {
                u32 betAmount = 0;
                betAmount = parseInt(betAmountString);

                if (betAmount <= 0) {
                    whisper(player, "You have to bet at least 1 coin.");
                }
                else if (betAmount > MAX_BET) {
                    whisper(player, "The maximum bet is " + MAX_BET + " coins.");
                }
                else {
                    u32 coins = getPlayerCoins(player.getUsername());

                    if (coins < betAmount) {
                        whisper(player, "You only have " + coins + " coins.");
                    }
                    else {
                        float winP1, winP2, oddsP1, oddsP2;
                        getWinPctAndOddsForMatch(CURRENT_MATCH, winP1, winP2, oddsP1, oddsP2);
                        float odds = oddsP1;
                        if (bettedOnUsername == CURRENT_MATCH.player2)
                            odds = oddsP2;

                        RatedMatchBet bet(player.getUsername(), bettedOnUsername, betAmount, odds);
                        placeBet(bet);
                    }
                }
            }
            else {
                whisper(player, syntaxExample);
            }
        }
    }
    else {
        whisper(player, "You can't bet unless there's a match in progress.");
    }
}

void handleChatCommandCoins(CPlayer@ player, string[]@ tokens) {
    u32 coins = getPlayerCoins(player.getUsername());
    whisperAll(player.getUsername() + " has " + coins + " coins.");
}

// Assumes the bet is valid
void placeBet(RatedMatchBet bet) {
    log("placeBet", "Placing bet " + bet.serialize());

    // Check if a similar bet exists and if so merge them
    int existingBetIndex = findBet(bet.betterUsername, bet.bettedOnUsername);
    if (existingBetIndex != -1) {
        RatedMatchBet existingBet = CURRENT_MATCH_BETS[existingBetIndex];
        existingBet.betAmount = bet.betAmount;
        existingBet.odds = bet.odds;
    }
    else {
        CURRENT_MATCH_BETS.push_back(bet);
    }

    syncMatchBets();
}

int findBet(string better, string bettedOn) {
    int index = -1;

    for (uint i=0; i < CURRENT_MATCH_BETS.length; ++i) {
        RatedMatchBet bet = CURRENT_MATCH_BETS[i];

        if (bet.betterUsername == better && bet.bettedOnUsername == bettedOn)
            return i;
    }

    return index;
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
    }
    else {
        CHALLENGE_QUEUE.push_back(chal);
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

        ROUND_STATS.clear();
        CURRENT_ROUND_STATS = RatedMatchRoundStats();

        allSpec();
        player1.server_setTeamNum(0);
        player2.server_setTeamNum(1);
        LoadMapCycle("mapcycle_" + CURRENT_MATCH.kagClass + ".cfg");
        LoadNextMap();

        syncMatchInProgress(true);
        syncCurrentMatch();
        whisperAll("Starting match! " + CURRENT_MATCH.player1 + " vs. " + CURRENT_MATCH.player2);
    }
}

// Cancels the current match if something unexpected happened. Results are not saved.
void cancelCurrentMatch() {
    log("cancelCurrentMatch", "called");
    syncMatchInProgress(false);
    CURRENT_MATCH_BETS.clear();
    syncMatchBets();
    whisperAll("Cancelling current match.");
}

// Called after the final round of the match 
void finishCurrentMatch() {
    log("finishCurrentMatch", "called");

    string winner = CURRENT_MATCH.player1;
    string loser = CURRENT_MATCH.player2;
    int winnerScore = CURRENT_MATCH.player1Score;
    int loserScore = CURRENT_MATCH.player2Score;
    if (CURRENT_MATCH.player2Score > CURRENT_MATCH.player1Score) {
        winner = CURRENT_MATCH.player2;
        loser = CURRENT_MATCH.player1;
        winnerScore = CURRENT_MATCH.player2Score;
        loserScore = CURRENT_MATCH.player1Score;
    }

    whisperAll("WINNER: {winner} {winnerScore} - {loserScore} {loser}"
        .replace("{winner}", winner)
        .replace("{winnerScore}", ""+winnerScore)
        .replace("{loserScore}", ""+loserScore)
        .replace("{loser}", ""+loser)
        );

    int winnerCoins = COINS_EARNED_PER_ROUND_WIN*winnerScore;
    int loserCoins = COINS_EARNED_PER_ROUND_WIN*loserScore;
    requestCoinChange(winner, winnerCoins);
    requestCoinChange(loser, loserCoins);
    whisperAll(winner + " earned " + winnerCoins + " coins, " + loser + " earned " + loserCoins + " coins."); 

    resolveMatchBets(winner);
    syncMatchInProgress(false);
    CURRENT_MATCH_BETS.clear();
    syncMatchBets();
    saveCurrentMatch();

    requestPlayerInfo(CURRENT_MATCH.player1);
    requestPlayerInfo(CURRENT_MATCH.player2);

    if (CHALLENGE_QUEUE.length > 0) {
        startQueueSystemWait();
    }
    return;
}

// Sends money where it belongs
void resolveMatchBets(string winner) {
    log("resolveMatchBets", "Called: " + CURRENT_MATCH_BETS.length);

    for (uint i=0; i < CURRENT_MATCH_BETS.length; ++i) {
        RatedMatchBet bet = CURRENT_MATCH_BETS[i];
        int coinChange;

        if (bet.bettedOnUsername == winner) {
            // Bet wins
            coinChange = Maths::Round(bet.betAmount * (bet.odds - 1));
            whisperAll(bet.betterUsername + " won " + coinChange + " coins!"); 
        }
        else {
            // Bet loses
            coinChange = -bet.betAmount;
            whisperAll(bet.betterUsername + " lost " + coinChange + " coins!"); 
        }

        requestCoinChange(bet.betterUsername, coinChange);
    }
}

// To prevent people spamming !accept as soon as a game finishes, wait a few seconds after a match
// where only the players in the topmost challenge may accept.
void startQueueSystemWait() {
    log("startQueueSystemWait", "Called");
    getRules().set_u32("VAR_QUEUE_WAIT_UNTIL", Time() + CHALLENGE_QUEUE_WAIT_TIME_SECS);
    syncQueueSystemWait();
}

void saveCurrentMatch() {
    log("saveCurrentMatch", "called");
    requestSaveMatch();
}

void requestPlayerInfo(string username) {
    TCPR::Request req("playerinfo", @onPlayerInfoRequestComplete);
    req.setParam("username", username);
    TCPR::makeRequest(@REQUESTS, @req);
}

void onPlayerInfoRequestComplete(TCPR::Request req, string response) {
    string username;
    req.params.get("username", username);
    //log("onPlayerInfoRequestComplete", username + ": " + response);
    RatedPlayerInfo pr();
    if (pr.deserialize(response)) {
        log("onPlayerInfoRequestComplete", "deserialized successfully");
        getRules().set_string(getSerializedPlayerInfoRulesProp(username), response);
        getRules().set(getPlayerInfoRulesProp(username), pr);
        syncPlayerInfo(response);
    }
    else {
        log("onPlayerInfoRequestComplete", "ERROR couldn't deserialize response");
    }
}

void requestCoinChange(string username, int amount) {
    TCPR::Request req("coinchange", @onCoinChangeRequestComplete);
    req.setParam("username", username);
    req.setParam("amount", ""+amount);
    TCPR::makeRequest(@REQUESTS, @req);
}

void onCoinChangeRequestComplete(TCPR::Request req, string response) {
    log("onCoinChangeRequestComplete", response);
    // Response should look like <coins>100</coins>
    XMLParser parser(response);
    XMLDocument@ doc = parser.parse();
    if (doc !is null) {
        int newCoins = parseInt(doc.root.value);
        syncPlayerCoins(req.getParam("username"), newCoins);
        updatePlayerCoins(req.getParam("username"), newCoins);
    }
}

void requestSaveMatch() {
    TCPR::Request req("savematch", @onSaveMatchRequestComplete);
    req.setParam("player1", CURRENT_MATCH.player1);
    req.setParam("player2", CURRENT_MATCH.player2);
    req.setParam("kagclass", CURRENT_MATCH.kagClass);
    req.setParam("starttime", ""+CURRENT_MATCH.startTime);
    req.setParam("player1score", ""+CURRENT_MATCH.player1Score);
    req.setParam("player2score", ""+CURRENT_MATCH.player2Score);
    req.setParam("dueltoscore", ""+CURRENT_MATCH.duelToScore);
    req.setParam("rounds", serializeRoundStats());
    req.setParam("stats", CURRENT_MATCH_STATS.serialize());
    TCPR::makeRequest(@REQUESTS, @req);
}

void onSaveMatchRequestComplete(TCPR::Request req, string response) {
    log("onSaveMatchRequestComplete", "Response: " + response);
    string player1 = req.getParam("player1");
    string player2 = req.getParam("player2");

    XMLParser parser(response);
    XMLDocument@ doc = parser.parse();
    if (doc !is null && doc.root.name == "response") {
        int change_p1 = 0;
        int change_p2 = 0;

        if (doc.root.getChildByName("player1_rating_change") !is null) {
            change_p1 = parseInt(doc.root.getChildByName("player1_rating_change").value);
        }
        if (doc.root.getChildByName("player2_rating_change") !is null) {
            change_p2 = parseInt(doc.root.getChildByName("player2_rating_change").value);
        }

        whisperAll("Rating changes: " + player1 + " " + formatIntWithSign(change_p1) + ", "
            + player2 + " " + formatIntWithSign(change_p2));
    }
    else {
        whisperAll("ERROR Something went wrong when saving " + player1 + " vs. " + player2 + ".");
    }
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

string serializeMatchBets() {
    string ser = "<matchbets>";
    for (int i=0; i < CURRENT_MATCH_BETS.length(); ++i) {
        RatedMatchBet bet = CURRENT_MATCH_BETS[i];
        ser += bet.serialize();
    }
    ser += "</matchbets>";
    return ser;
}

string serializeRoundStats() {
    string ser;
    log("serializeRoundStats", ROUND_STATS.length + " rounds");
    for (int i = 0; i < ROUND_STATS.length; i++) {
        ser += ROUND_STATS[i].serialize();
    }
    log("serializeRoundStats", "length: " + ser.length);
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

void syncMatchBets() {
    log("syncMatchBets", "Called");
    CBitStream params;
    params.write_string(serializeMatchBets());
    getRules().SendCommand(getRules().getCommandID("CMD_SYNC_MATCH_BETS"), params, true);
}

void syncCurrentMatch() {
    log("syncCurrentMatch", "Called");
    CBitStream params;
    params.write_string(CURRENT_MATCH.serialize());
    getRules().SendCommand(getRules().getCommandID("CMD_SYNC_CURRENT_MATCH"), params, true);
}

void syncPlayerInfo(string serializedPlayerInfo) {
    CBitStream params;
    params.write_string(serializedPlayerInfo);
    getRules().SendCommand(getRules().getCommandID("CMD_SYNC_PLAYER_INFO"), params, true);
}

void syncPlayerCoins(string username, u32 amount) {
    CBitStream params;
    params.write_string(username);
    params.write_u32(amount);
    getRules().SendCommand(getRules().getCommandID("CMD_SYNC_PLAYER_COINS"), params, true);
}

void syncQueueSystemWait() {
    getRules().Sync("VAR_QUEUE_WAIT_UNTIL", true);
    CBitStream params;
    // The command is so that the client can be alerted to the sync and potentially play an alert sound
    getRules().SendCommand(getRules().getCommandID("CMD_SYNC_QUEUE_WAIT_UNTIL"), params, true);
}

// Called when a new player joins the server so they can be told about everyone else's ratings
void syncPlayerInfoToNewPlayer(CPlayer@ newPlayer) {
    log("syncPlayerInfoToNewPlayer", "Called for " + newPlayer.getUsername());

    for (int i=0; i < getPlayerCount(); i++) {
        CPlayer@ other = getPlayer(i);

        if (other !is newPlayer) {
            string prop = getSerializedPlayerInfoRulesProp(other.getUsername());

            if (getRules().exists(prop)) {
                log("syncPlayerInfoToNewPlayer", prop + "(" + getRules().get_string(prop) + ")");
                CBitStream params;
                params.write_string(getRules().get_string(prop));
                getRules().SendCommand(getRules().getCommandID("CMD_SYNC_PLAYER_INFO"), params, newPlayer);
            }
            else {
                log("syncPlayerInfoToNewPlayer", "Doesn't exist: " + prop);
            }
        }
    }
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

int getDefaultDuelToScore() {
    if (getPlayersCount() >= PLAYER_COUNT_FOR_SHORT_DUEL) {
        return DEFAULT_DUEL_TO_SCORE_SHORT;
    }
    else {
        return DEFAULT_DUEL_TO_SCORE;
    }
}

int getCurrentRoundIndex() {
    return ROUND_STATS.length;
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

void testSaveMatch() {
    log("testSaveMatch", "Called");
    getRules().set_bool("VAR_MATCH_IN_PROGRESS", true);
    CURRENT_MATCH = RatedMatch("Eluded", "Eluded2", "knight", 2);
    CURRENT_MATCH.player1Score = 2;
    CURRENT_MATCH.player2Score = 0;

    CURRENT_MATCH_STATS = RatedMatchStats();
    CURRENT_MATCH_STATS.player1_stats = RatedMatchPlayerStats();
    CURRENT_MATCH_STATS.player1_stats.nickname = "Joan of Arc<>>>";
    CURRENT_MATCH_STATS.player1_stats.clantag = "[Ω]";
    CURRENT_MATCH_STATS.player1_stats.head = 40;
    CURRENT_MATCH_STATS.player1_stats.gender = 1;
    CURRENT_MATCH_STATS.player2_stats = RatedMatchPlayerStats();
    CURRENT_MATCH_STATS.player2_stats.nickname = "Joan of Arc2";
    CURRENT_MATCH_STATS.player2_stats.clantag = "LOL";
    CURRENT_MATCH_STATS.player2_stats.head = 41;
    CURRENT_MATCH_STATS.player2_stats.gender = 1;

    ROUND_STATS.clear();

    RatedMatchRoundStats round1();
    round1.end_time = Time() + 500;
    round1.winner = "Eluded";

    RatedMatchRoundStats round2();
    round2.start_time = Time() + 501;
    round2.end_time = Time() + 1000;
    round2.winner = "Eluded";

    for (int i = 0; i < 20; i++) {
        string[] params;
        round1.events.push_back(MatchEvent(KNIGHT_SLASH_START, 1, params));
        round2.events.push_back(MatchEvent(KNIGHT_SLASH_START, 1, params));
    }

    ROUND_STATS.push_back(round1);
    ROUND_STATS.push_back(round2);

    finishCurrentMatch();
}

void spawnShieldBot(CPlayer@ player) {
    Vec2f pos(0,0);
    if (player.getBlob() !is null) {
        pos = player.getBlob().getPosition();
    }
    CBlob@ knight = server_CreateBlob("knight", -1, pos);
    knight.AddScript("ShieldBot.as");
}

bool checkMapsIncluded() {
    ConfigFile cfg();
    if(!cfg.loadFile("kl_maps_included.cfg")) {
        return false;
    }
    else {
        bool _;
        bool check = cfg.read_bool("included", _);
        return check;
    }
}

void shutdownServer() {
    log("shutdownServer", "Shutting down server.");
    QuitGame();
}

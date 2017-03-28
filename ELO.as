#include "Logging.as"
#include "ELO_Common.as"
#include "PlayerInfo.as"
#include "RulesCore.as";

const u8 WINNING_SCORE = 11;
const u8 SYNC_EVERY_N_TICKS = 300;
const string ELO_MATCH_HISTORY_CFG = "ELO_MatchHistory.cfg";

Duel[] DUEL_QUEUE;

void onInit(CRules@ this) {
    log("onInit(CRules)", "Called");
    Duel emptyDuel("", "", "knight");
    this.set_u8("CURRENT_DUEL_STATE", DuelState::NO_DUEL);
    this.set("CURRENT_DUEL", emptyDuel);
    this.addCommandID("ON_END_DUEL"); // sent when a duel ends

    // Since we can't sync a Duel object, just sync the score
    this.set_u8("CURRENT_DUEL_SCORE_0", 0);
    this.set_u8("CURRENT_DUEL_SCORE_1", 0);
}

void onTick(CRules@ this) {
    /*
    if (getNet().isClient()) {
        log("onTick", "team 0 score " + this.get_u8("CURRENT_DUEL_SCORE_0"));
        log("onTick", "team 1 score " + this.get_u8("CURRENT_DUEL_SCORE_1"));
    }
    */
    if (getNet().isServer() && getGameTime() % SYNC_EVERY_N_TICKS == 0) {
        syncDuel(this);
    }
}

void onStateChange(CRules@ this, const u8 oldState) {
    if (!getNet().isServer()) return;

    // Detect game over
    u8 duelState = this.get_u8("CURRENT_DUEL_STATE");
    if (duelState == DuelState::ACTIVE_DUEL && this.getCurrentState() == GAME_OVER
        && oldState != GAME_OVER) {
        onGameOver(this);
    }
}

void onGameOver(CRules@ this) {
    int winningTeam = this.getTeamWon();
    log("onGameOver", "Detected game over! Winning team: " + winningTeam);

    Duel currentDuel;
    this.get("CURRENT_DUEL", currentDuel);

    CPlayer@ challenger = getPlayerByUsername(currentDuel.challengerUsername);
    CPlayer@ challenged = getPlayerByUsername(currentDuel.challengedUsername);

    if (challenger is null || challenged is null) {
        log("onStateChange", "Aborting current duel because one player is gone");
        abortCurrentDuel(this);
        return;
    }

    // Work out which player won
    if (challenger.getTeamNum() == winningTeam) {
        currentDuel.scoreChallenger++;
    }
    else {
        currentDuel.scoreChallenged++;
    }
    this.set("CURRENT_DUEL", currentDuel); // update the score

    if (currentDuel.scoreChallenger == WINNING_SCORE || currentDuel.scoreChallenged == WINNING_SCORE) {
        endCurrentDuel(this);
    }

    currentDuel.debug();
    syncDuel(this);
    log("syncDuel", "Done");
}

// Look for challenge commands that look like:
// !challenge [username] [builder|archer|knight]
bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player) {
    if (player is null) return true;

    log("onServerProcessChat", "Got: " + text_in);
    string[]@ tokens = text_in.split(" ");
    if (tokens.length() < 2) return true;

    // Check that a duel isn't already happening
    u8 duelState = this.get_u8("CURRENT_DUEL_STATE");
    if (duelState == DuelState::ACTIVE_DUEL && (tokens[0] == "!challenge" || tokens[0] == "!accept" || tokens[0] == "!reject")) {
        broadcast("Wait until the current duel is finished!");
        return;
    }

    if (tokens[0] == "!challenge") {
        log("onServerProcessChat", "Parsed !challenge cmd");
        string challengedUsername = tokens[1];
        string whichClass = "knight";
        if (tokens.length() >= 3) {
            whichClass = tokens[2];
        }

        setupChallenge(player.getUsername(), challengedUsername, whichClass);
    }
    else if (tokens[0] == "!accept") {
        string username = tokens[1];
        tryAcceptChallenge(player.getUsername(), username);
    }
    else if (tokens[0] == "!reject") {
        string username = tokens[1];
        tryRejectChallenge(player.getUsername(), username);
    }

    return true;
}

void abortCurrentDuel(CRules@ this) {
    log("abortCurrentDuel", "Aborting...");
    this.set_u8("CURRENT_DUEL_STATE", DuelState::NO_DUEL);
    //this.set("CURRENT_DUEL", Duel());

    syncDuel(this);
}

void endCurrentDuel(CRules@ this) {
    log("endCurrentDuel", "Ending...");
    Duel currentDuel;
    this.get("CURRENT_DUEL", currentDuel);
    log("endCurrentDuel", "" + currentDuel.challengerUsername + " " + currentDuel.scoreChallenger + ", "
                               + currentDuel.challengedUsername + " " + currentDuel.scoreChallenged);

    abortCurrentDuel(this);
    saveDuel(currentDuel);
    CBitStream params;
    this.SendCommand(this.getCommandID("ON_END_DUEL"), params); // for ELO updates
}

void syncDuel(CRules@ this) {
    log("syncDuel", "Called");
    this.Sync("CURRENT_DUEL_STATE", true);

    if (this.get_u8("CURRENT_DUEL_STATE") != DuelState::ACTIVE_DUEL) {
        // No need to sync score if there's not a duel on
        return;
    }

    Duel currentDuel;
    this.get("CURRENT_DUEL", currentDuel);

    u8 team0Score;
    u8 team1Score;
    if (currentDuel.getChallengerTeamNum() == 0) {
        team0Score = currentDuel.scoreChallenger;
        team1Score = currentDuel.scoreChallenged;
    }
    else {
        team0Score = currentDuel.scoreChallenged;
        team1Score = currentDuel.scoreChallenger;
    }
    log("syncDuel", "team 0, team 1: " + team0Score + ", " + team1Score);

    this.set_u8("CURRENT_DUEL_SCORE_0", team0Score);
    this.set_u8("CURRENT_DUEL_SCORE_1", team1Score);
    this.Sync("CURRENT_DUEL_SCORE_0", true);
    this.Sync("CURRENT_DUEL_SCORE_1", true);
}

void setupChallenge(string challengerUsername, string challengedUsername, string whichClass) {
    log("setupChallenge", "Called " + challengedUsername + " " + challengerUsername + " " + whichClass);
    if (getPlayerByUsername(challengerUsername) is null) {
        log("setupChallenge", "ERROR challenger doesn't exist");
        return;
    }
    if (getPlayerByUsername(challengedUsername) is null) {
        log("setupChallenge", "ERROR challenged player doesn't exist");
        broadcast("Challenged player doesn't exist!");
        return;
    }
    if (!(whichClass == "knight" || whichClass == "archer" || whichClass == "builder")) {
        log("setupChallenge", "ERROR invalid class " + whichClass);
        broadcast("Invalid class! Choose archer, knight or builder.");
        return;
    }
    if (challengerUsername == challengedUsername) {
        broadcast("Nice try lol.");
        return;
    }

    Duel challenge(challengerUsername, challengedUsername, whichClass);
    DUEL_QUEUE.push_back(challenge);
    log("setupChallenge", "Queued new challenge. Current length " + DUEL_QUEUE.length());

    string aOrAn = whichClass == "archer" ? "an" : "a";
    broadcast(challengerUsername + " has challenged " + challengedUsername + " to " + aOrAn + " " + whichClass + " duel!");
}

void tryAcceptChallenge(string challengedUsername, string challengerUsername) {
    // Check if the challenge exists in the queue
    log("tryAcceptChallenge", "Called " + challengedUsername + " " + challengerUsername);
    bool found = false;
    for (int i=0; i < DUEL_QUEUE.length(); i++) {
        Duel challenge = DUEL_QUEUE[i];

        if (challenge.challengerUsername == challengerUsername
            && challenge.challengedUsername == challengedUsername) {
            startChallenge(challenge);
            DUEL_QUEUE.removeAt(i);
            break;
        }
    }

    if (!found) {
        log("tryAcceptChallenge", "ERROR challenge not found");
    }
}

void tryRejectChallenge(string challengedUsername, string challengerUsername) {
    log("tryRejectChallenge", "Called " + challengedUsername + " " + challengerUsername);
    bool found = false;
    for (int i=0; i < DUEL_QUEUE.length(); i++) {
        Duel challenge = DUEL_QUEUE[i];

        if (challenge.challengerUsername == challengerUsername
            && challenge.challengedUsername == challengedUsername) {
            DUEL_QUEUE.removeAt(i);
            break;
        }
    }

    if (!found) {
        log("tryRejectChallenge", "ERROR challenge not found");
    }
}

void startChallenge(Duel challenge) {
    log("startChallenge", "Called");
    CPlayer@ challenger = getPlayerByUsername(challenge.challengerUsername);
    CPlayer@ challenged = getPlayerByUsername(challenge.challengedUsername);
    if (challenger is null) {
        log("startChallenge", "ERROR challenger is null");
        return;
    }
    if (challenged is null) {
        log("startChallenge", "ERROR challenger is null");
        return;
    }

    allSpec(getRules());
    challenger.server_setTeamNum(0);
    challenged.server_setTeamNum(1);
    getRules().set_u8("CURRENT_DUEL_STATE", DuelState::ACTIVE_DUEL);
    getRules().set("CURRENT_DUEL", challenge);

    // Change classes appropriately
    RulesCore@ core;
    getRules().get("core", @core);
    PlayerInfo@ challengerInfo = core.getInfoFromName(challenge.challengerUsername);
    PlayerInfo@ challengedInfo = core.getInfoFromName(challenge.challengedUsername);

    if (challengerInfo is null || challengedInfo is null) {
        log("startChallenge", "ERROR either challenger or challenged playerinfo is null");
    }
    else {
        log("startChallenge", "Changing classes to " + challenge.whichClass);
        challenger.lastBlobName = challenge.whichClass;
        challenged.lastBlobName = challenge.whichClass;
        challengerInfo.blob_name = challenge.whichClass;
        challengedInfo.blob_name = challenge.whichClass;
    }


    LoadNextMap();
    syncDuel(getRules());
    broadcast("Starting challenge! " + challenge.challengerUsername + " vs. " + challenge.challengedUsername);
}

void saveDuel(Duel duel) {
    log("saveDuel", "Called");
    ConfigFile cfg();
    bool check = cfg.loadFile(ELO_MATCH_HISTORY_CFG);
    if (!check) {
        log("saveDuel", "Couldn't load " + ELO_MATCH_HISTORY_CFG);
        return;
    }

    int i=0;
    while(true) {
        string nextMatchProp = "match" + i;
        if (cfg.exists(nextMatchProp))
            continue;
        else {
            cfg.add_string(nextMatchProp, duel.serialize());
            break;
        }
    }

    cfg.saveFile(ELO_MATCH_HISTORY_CFG);
}

// Puts everyone into spectator
void allSpec(CRules@ this) {
    int specTeam = this.getSpectatorTeamNum();

    for (int i=0; i < getPlayerCount(); i++) {
        CPlayer@ p = getPlayer(i);
        if (p is null || p.getTeamNum() == specTeam) continue;
        p.server_setTeamNum(specTeam);
    }
}
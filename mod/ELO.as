#include "Logging.as"
#include "ELO_Common.as"
#include "PlayerInfo.as"
#include "RulesCore.as";

const u8 MIN_DUEL_TO_SCORE = 1;
const u8 MAX_DUEL_TO_SCORE = 11;
const u8 DEFAULT_DUEL_TO_SCORE = 5;
const u8 SYNC_EVERY_N_TICKS = 300;

Duel[] DUEL_QUEUE;

void onInit(CRules@ this) {
    log("onInit(CRules)", "Called");
    Duel emptyDuel("", "", "knight", 0);
    this.set_u8("CURRENT_DUEL_STATE", DuelState::NO_DUEL);
    this.set("CURRENT_DUEL", emptyDuel);
    this.addCommandID("ON_END_DUEL"); // sent when a duel ends

    // Since we can't sync a Duel object, just sync the score
    this.set_u8("CURRENT_DUEL_SCORE_0", 0);
    this.set_u8("CURRENT_DUEL_SCORE_1", 0);
    this.set_u8("CURRENT_DUEL_TO_SCORE", 0);

    this.set_string("SERIALIZED_DUEL_QUEUE", ""); // this will be sent periodically from the server to clients to display in the UI

    ConfigFile cfg();
    bool check = cfg.loadFile("../Cache/"+ELO_MATCH_HISTORY_CFG);
    if (!check) {
        log("onInit", "Elo match history cfg doesn't exist so creating it");
        cfg.saveFile(ELO_MATCH_HISTORY_CFG);
    }
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
        if (garbageCollectDuelQueue())
            syncDuelQueue(this);

        // Check for disconnects if duel is active
        if (this.get_u8("CURRENT_DUEL_STATE") == DuelState::ACTIVE_DUEL) {
            Duel currentDuel;
            this.get("CURRENT_DUEL", currentDuel);

            CPlayer@ challenger = getPlayerByUsername(currentDuel.challengerUsername);
            CPlayer@ challenged = getPlayerByUsername(currentDuel.challengedUsername);

            if (challenger is null || challenged is null) {
                log("onTick", "Aborting current duel because one player is gone");
                abortCurrentDuel(this);
                return;
            }
        }
    }
}

void onStateChange(CRules@ this, const u8 oldState) {
    if (!getNet().isServer()) return;

    // Detect game over
    u8 duelState = this.get_u8("CURRENT_DUEL_STATE");
    if (duelState == DuelState::ACTIVE_DUEL && this.getCurrentState() == GAME_OVER && oldState != GAME_OVER) {
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
    else if (challenged.getTeamNum() == winningTeam) {
        currentDuel.scoreChallenged++;
    }
    else {
        // It's a draw
    }

    this.set("CURRENT_DUEL", currentDuel); // update the score

    if (currentDuel.scoreChallenger == currentDuel.duelToScore || currentDuel.scoreChallenged == currentDuel.duelToScore) {
        endCurrentDuel(this);
    }

    currentDuel.debug();
    syncDuel(this);
}

string[] tokenize(string text) {
    string[]@ dirtyTokens = text.split(" "); // there could be 0 length tokens
    string[] tokens;

    for (int i=0; i < dirtyTokens.length; ++i) {
        if (dirtyTokens[i].length > 0) {
            tokens.push_back(dirtyTokens[i]);
        }
    }

    return tokens;
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player) {
    if (player is null) return true;

    log("onServerProcessChat", "Got: " + text_in);
    string[] tokens = tokenize(text_in);
    u8 duelState = this.get_u8("CURRENT_DUEL_STATE");
    Duel currentDuel;
    this.get("CURRENT_DUEL", currentDuel);

    if (tokens.length() < 1) {
        return true;
    }
    else if (tokens[0] == "!help") {
        sendChat(this, player, getModHelpString());
    }
    else if (tokens[0] == "!cancel") {
        if (duelState == DuelState::ACTIVE_DUEL) {
            if (player.isMod() || player.getUsername() == currentDuel.challengerUsername || player.getUsername() == currentDuel.challengedUsername) {
                broadcast("Cancelling current duel.");
                abortCurrentDuel(this);
                return true;
            }
            else {
                broadcast("You don't have permission to cancel this duel");
                return true;
            }
        }
        else {
            broadcast("There is no duel at the moment.");
            return true;
        }
    }
    else if (tokens.length < 2) {
        return true;
    }
    else if (tokens[0] == "!challenge") {
        log("onServerProcessChat", "Parsed !challenge cmd");
        string challengedIdent = tokens[1];
        CPlayer@ challengedPlayer = getPlayerByIdent(challengedIdent);
        if (challengedPlayer !is null) {
            string challengedUsername = challengedPlayer.getUsername();
            string whichClass = "knight";
            u8 duelToScore = DEFAULT_DUEL_TO_SCORE;

            if (tokens.length() >= 3) {
                if (isPositiveInteger(tokens[2])) {
                    duelToScore = parseInt(tokens[2]);
                }
                else {
                    whichClass = tokens[2];

                    if (tokens.length() >= 4) {
                        if (isPositiveInteger(tokens[3])) {
                            duelToScore = parseInt(tokens[3]);
                        }
                    }
                }
            }

            setupChallenge(player.getUsername(), challengedUsername, whichClass, duelToScore);
        }
    }
    else if (tokens[0] == "!reject") {
        string ident = tokens[1];
        CPlayer@ otherPlayer = getPlayerByIdent(ident);
        if (otherPlayer !is null) {
            tryRejectChallenge(otherPlayer.getUsername(), player.getUsername());
        }
    }
    else if (tokens[0] == "!accept") {
        if (duelState == DuelState::ACTIVE_DUEL) {
            broadcast("Wait until the current duel is finished!");
        }
        else {
            string ident = tokens[1];
            CPlayer@ otherPlayer = getPlayerByIdent(ident);
            if (otherPlayer !is null) {
                tryAcceptChallenge(otherPlayer.getUsername(), player.getUsername());
            }
        }
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
    string winner = currentDuel.scoreChallenger > currentDuel.scoreChallenged ? currentDuel.challengerUsername : currentDuel.challengedUsername;
    broadcast("GAME OVER! The winner is " + winner + ".");

    abortCurrentDuel(this);
    saveDuel(currentDuel);
    CBitStream params;
    this.SendCommand(this.getCommandID("ON_END_DUEL"), params); // for ELO updates
}

void syncDuel(CRules@ this) {
    //log("syncDuel", "Called");
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
    //log("syncDuel", "team 0, team 1: " + team0Score + ", " + team1Score);

    this.set_u8("CURRENT_DUEL_SCORE_0", team0Score);
    this.set_u8("CURRENT_DUEL_SCORE_1", team1Score);
    this.set_u8("CURRENT_DUEL_TO_SCORE", currentDuel.duelToScore);
    this.Sync("CURRENT_DUEL_SCORE_0", true);
    this.Sync("CURRENT_DUEL_SCORE_1", true);
    this.Sync("CURRENT_DUEL_TO_SCORE", true);
}

void syncDuelQueue(CRules@ this) {
    log("syncDuelQueue", "Called");
    string ser = "<duelqueue>";

    for (int i=0; i < DUEL_QUEUE.length(); ++i) {
        Duel duel = DUEL_QUEUE[i];
        ser += duel.serialize();
    }

    ser += "</duelqueue>";

    this.set_string("SERIALIZED_DUEL_QUEUE", ser);
    this.Sync("SERIALIZED_DUEL_QUEUE", true);
}

// Remove duels from the queue if one of the players is gone
// Returns true/false whether anything was removed
bool garbageCollectDuelQueue() {
    bool removedSomething = false;

    for (int i=DUEL_QUEUE.length()-1; i >= 0; --i) {
        Duel duel = DUEL_QUEUE[i];

        if (getPlayerByUsername(duel.challengerUsername) is null ||
            getPlayerByUsername(duel.challengedUsername) is null) {
            log("garbageCollectDuelQueue", "Garbage collecting duel " + duel.serialize());
            DUEL_QUEUE.removeAt(i);
            removedSomething = true;
        }
    }

    return removedSomething;
}

void setupChallenge(string challengerUsername, string challengedUsername, string whichClass, u8 duelToScore) {
    log("setupChallenge", "Called " + challengerUsername + " " + challengedUsername + " " + whichClass);
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
        broadcast("If you want to challenge yourself, why not try learning a musical instrument?");
        return;
    }
    if (duelToScore < MIN_DUEL_TO_SCORE) {
        broadcast("The minimum score you can duel to is " + MIN_DUEL_TO_SCORE);
        return;
    }
    if (duelToScore > MAX_DUEL_TO_SCORE) {
        broadcast("The maximum score you can duel to is " + MAX_DUEL_TO_SCORE);
        return;
    }

    // Check whether a challenge between these two players already exists
    for (int i=0; i < DUEL_QUEUE.length; ++i) {
        Duel existingChallenge = DUEL_QUEUE[i];

        if (existingChallenge.challengerUsername == challengerUsername && existingChallenge.challengedUsername == challengedUsername) {
            broadcast("You've already challenged that person! The old challenge will be removed.");
            DUEL_QUEUE.removeAt(i);
            break;
        }
    }

    Duel challenge(challengerUsername, challengedUsername, whichClass, duelToScore);
    DUEL_QUEUE.push_back(challenge);
    syncDuelQueue(getRules());
    log("setupChallenge", "Queued new challenge. Current length " + DUEL_QUEUE.length());

    string aOrAn = whichClass == "archer" ? "an" : "a";
    broadcast(challengerUsername + " has challenged " + challengedUsername + " to " + aOrAn + " " + whichClass + " duel to " + duelToScore + "!");
}

void tryAcceptChallenge(string challengerUsername, string challengedUsername) {
    // Check if the challenge exists in the queue
    log("tryAcceptChallenge", "Called " + challengerUsername + " " + challengedUsername);
    bool found = false;
    for (int i=0; i < DUEL_QUEUE.length(); i++) {
        Duel challenge = DUEL_QUEUE[i];

        if (challenge.challengerUsername == challengerUsername
            && challenge.challengedUsername == challengedUsername) {
            DUEL_QUEUE.removeAt(i);
            startChallenge(challenge);
            break;
        }
    }

    if (!found) {
        log("tryAcceptChallenge", "ERROR challenge not found");
    }
}

void tryRejectChallenge(string challengerUsername, string challengedUsername) {
    log("tryRejectChallenge", "Called " + challengerUsername + " " + challengedUsername);
    bool found = false;
    for (int i=0; i < DUEL_QUEUE.length(); i++) {
        Duel challenge = DUEL_QUEUE[i];

        if (challenge.challengerUsername == challengerUsername
            && challenge.challengedUsername == challengedUsername) {
            DUEL_QUEUE.removeAt(i);
            syncDuelQueue(getRules());
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

    // Remove all of the challenger's other challenges from the queue
    for (int i=DUEL_QUEUE.length-1; i >= 0; --i) {
        Duel duel = DUEL_QUEUE[i];
        if (duel.challengerUsername == challenge.challengerUsername) {
            DUEL_QUEUE.removeAt(i);
        }
    }

    LoadNextMap();
    syncDuel(getRules());
    syncDuelQueue(getRules());
    broadcast("Starting challenge! " + challenge.challengerUsername + " vs. " + challenge.challengedUsername);
}

void saveDuel(Duel duel) {
    log("saveDuel", "Called");
    ConfigFile cfg();
    bool check = cfg.loadFile("../Cache/"+ELO_MATCH_HISTORY_CFG);
    if (!check) {
        log("saveDuel", "Couldn't load " + ELO_MATCH_HISTORY_CFG);
        return;
    }

    for (int i=0; i < 1000000; ++i) {
        string nextMatchProp = "match" + i;
        //log("saveDuel", "Checking " + nextMatchProp);
        if (cfg.exists(nextMatchProp))
            continue;
        else {
            cfg.add_string(nextMatchProp, duel.serialize());
            break;
        }
    }

    cfg.saveFile(ELO_MATCH_HISTORY_CFG);
    log("saveDuel", "Done");
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

void displayTopPlayers(string whichClass) {
    /* don't think this will work since it's not possible to iterate over the keys of a config file
    if (!(whichClass == "knight" || whichClass == "archer" || whichClass == "builder")) {
        log("displayTopPlayers", "ERROR invalid class " + whichClass);
        broadcast("Invalid class! Choose archer, knight or builder.");
        return;
    }

    ConfigFile cfg;
    bool check = cfg.loadFile("../Cache/"+ELO_TABLE_CFG);
    if (!check) {
        log("displayTopPlayers", "Couldn't load ELO cfg");
        broadcast("ERROR loading top players");
        return;
    }

    CBitStream stream;
    cfg.ExtractToBitStream(stream);
    log("displayTopPlayers", stream.read_string());
    */
}

bool isPositiveInteger(string num) {
    for (int i=0; i < num.length; ++i) {
        u8 c = num[i];
        if ("0"[0] <= c && c <= "9"[0]) {
            continue;
        }
        else {
            return false;
        }
    }

    return true;
}
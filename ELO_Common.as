#include "Logging.as"

const string ELO_MATCH_HISTORY_CFG = "ELO_MatchHistory.cfg";
const string ELO_TABLE_CFG = "ELO_Table.cfg";
const string[] ALL_CLASSES = {"archer", "builder", "knight"};

namespace DuelState {
    enum _ {
        NO_DUEL = 0,
        ACTIVE_DUEL
    }
}

shared class Duel {
    string challengerUsername;
    string challengedUsername;
    string whichClass;
    u32    initTime;
    u8     scoreChallenger;
    u8     scoreChallenged;
    u8     duelToScore;

    Duel(string _challengerUsername, string _challengedUsername, string _whichClass, u8 _duelToScore) {
        challengerUsername = _challengerUsername;
        challengedUsername = _challengedUsername;
        whichClass = _whichClass;
        duelToScore = _duelToScore;
        initTime = getGameTime();
        scoreChallenger = 0;
        scoreChallenged = 0;
    }

    int getChallengerTeamNum() {
        CPlayer@ challenger = getPlayerByUsername(challengerUsername);
        if (challenger is null) {
            log("Duel#getChallengerTeamNum", "ERROR couldn't find challenger (" + challengerUsername + ")");
            return -1;
        }
        else {
            return challenger.getTeamNum();
        }
    }

    string serialize() {
        return challengerUsername + ',' + challengedUsername + ',' + whichClass + ',' + scoreChallenger + ',' + scoreChallenged + "," + duelToScore;
    }

    void debug() {
        log("Duel#debug", challengerUsername + " vs. " + challengedUsername
                + ", " + scoreChallenger + "-" + scoreChallenged
                + ", to " + duelToScore
                + ", " + whichClass
                + ", " + initTime
                );
    }
}

// This is the public interface to ELO_Updates
shared s16 getELO(string playerUsername, string whichClass) {
    string playerNameWithClass = playerUsername + "-" + whichClass;
    if (getRules().exists(playerNameWithClass)) {
        return getRules().get_s16(playerNameWithClass);
    }
    else {
        log("getELO", "ERROR no ELO found for " + playerUsername + "-" + whichClass);
        return -1;
    }
}

shared string getPlayerELOTitle(string username) {
    s16 elo_archer = getELO(username, "archer");
    s16 elo_builder = getELO(username, "builder");
    s16 elo_knight = getELO(username, "knight");
    s16 max_elo = Maths::Max(elo_archer, Maths::Max(elo_builder, elo_knight));
    string max_class;
    if (max_elo == elo_archer) max_class = "archer";
    if (max_elo == elo_builder) max_class = "builder";
    if (max_elo == elo_knight) max_class = "knight";
    return getTitleFromELO(max_elo) + " " + max_class;
}

shared string getTitleFromELO(s16 elo) {
    if (elo >= 2600) {
        return "Legendary";
    }
    else if (elo >= 2200) {
        return "Grand-master";
    }
    else if (elo >= 2000) {
        return "Master";
    }
    else if (elo >= 1800) {
        return "Diamond";
    }
    else if (elo >= 1600) {
        return "Platinum";
    }
    else if (elo >= 1400) {
        return "Gold";
    }
    else if (elo >= 1200) {
        return "Silver";
    }
    else if (elo >= 1000) {
        return "Bronze";
    }
    else {
        return "Peasant";
    }
}

shared CPlayer@ getPlayerByIdent(string ident) {
    // Takes an identifier, which is a prefix of the player's character name
    // or username. If there is 1 matching player then they are returned.
    // If 0 or 2+ then a warning is logged.
    ident = ident.toLower();
    log("getPlayerByIdent", "ident = " + ident);
    CPlayer@[] matches; // players matching ident

    for (int i=0; i < getPlayerCount(); i++) {
        CPlayer@ p = getPlayer(i);
        if (p is null) continue;

        string username = p.getUsername().toLower();
        string charname = p.getCharacterName().toLower();

        if (username == ident || charname == ident) {
            log("getPlayerByIdent", "exact match found: " + p.getUsername());
            return p;
        }
        else if (username.find(ident) >= 0 || charname.find(ident) >= 0) {
            matches.push_back(p);
        }
    }

    if (matches.length == 1) {
        log("getPlayerByIdent", "1 match found: " + matches[0].getUsername());
        return matches[0];
    }
    else if (matches.length == 0) {
        broadcast("Couldn't find anyone matching " + ident);
    }
    else {
        broadcast("Multiple people match '" + ident + "', be more specific.");
    }

    return null;
}

shared void displayModHelp() {
    SColor blue = SColor(255, 0, 0, 255);
    client_AddToChat("Welcome to the ELO mod!", blue);
    client_AddToChat("The following commands are available:", blue);
    client_AddToChat("!challenge someone (challenge someone to a knight 1v1)", blue);
    client_AddToChat("!challenge someone 3 (challenge them to 3 wins)", blue);
    client_AddToChat("!challenge someone archer", blue);
    client_AddToChat("!challenge someone builder", blue);
    client_AddToChat("!challenge someone builder 5", blue);
    client_AddToChat("!accept someone (accept a challenge)", blue);
    client_AddToChat("!reject someone (reject a challenge)'", blue);
    client_AddToChat("!cancel (cancels the current duel)", blue);
}
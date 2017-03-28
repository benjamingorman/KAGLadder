#include "Logging.as"


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

    Duel(string _challengerUsername, string _challengedUsername, string _whichClass) {
        challengerUsername = _challengerUsername;
        challengedUsername = _challengedUsername;
        whichClass = _whichClass;
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
        return challengerUsername + ',' + challengedUsername + ',' + whichClass + ',' + scoreChallenger + ',' + scoreChallenged;
    }

    void debug() {
        log("Duel#debug", challengerUsername + " vs. " + challengedUsername
                + ", " + scoreChallenger + "-" + scoreChallenged
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
    if (elo < 900) {
        return "Peasant";
    }
    else if (elo < 1100) {
        return "Bronze";
    }
    else if (elo < 1200) {
        return "Silver";
    }
    else if (elo < 1300) {
        return "Gold";
    }
    else if (elo < 1400) {
        return "Platinum";
    }
    else if (elo < 1500) {
        return "Diamond";
    }
    else if (elo < 1700) {
        return "Master";
    }
    else if (elo < 1800) {
        return "Grand-master";
    }
    else {
        return "Legendary";
    }
}

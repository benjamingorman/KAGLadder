#include "Logging.as"
#include "XMLParser.as"

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
        string ser = "<duel>";
        ser += "<challenger>" + challengerUsername + "</challenger>";
        ser += "<challenged>" + challengedUsername + "</challenged>";
        ser += "<whichclass>" + whichClass  + "</whichclass>";
        ser += "<dueltoscore>" + duelToScore + "</dueltoscore>";
        ser += "</duel>";
        return ser;
    }

    // Returns true/false whether successful
    bool deserialize(XMLElement@ elem) {
        if (elem.name != "duel") {
            log("Duel#deserialize", "ERROR xml doesn't start with duel");
            return false;
        }

        for (int i=0; i < elem.children.length(); ++i) {
            XMLElement@ child = elem.children[i];

            if (child.name == "challenger") {
                challengerUsername = child.value;
            }
            else if (child.name == "challenged") {
                challengedUsername = child.value;
            }
            else if (child.name == "whichclass") {
                whichClass = child.value;
            }
            else if (child.name == "dueltoscore") {
                duelToScore = parseInt(child.value);
            }
            else {
                log("Duel#deserialize", "ERROR weird element name: '" + child.name + "'");
                return false;
            }
        }
        
        return true;
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

shared string getModHelpString() {
    string help = "The following commands are available:\n";
    help += "!challenge someone (challenge someone to a knight duel)\n";
    help += "!challenge someone 3 (challenge them to 3 wins)\n";
    help += "!challenge someone archer\n";
    help += "!challenge someone builder\n";
    help += "!challenge someone builder 5\n";
    help += "!accept someone (accept a challenge)\n";
    help += "!reject someone (reject a challenge)\n";
    help += "!cancel (cancels the current duel)\n";
    return help;
}

shared void sendChat(CRules@ this, CPlayer@ player, string x) {
    sendChat(this, player, x, SColor(255,0,0,255));
}

shared void sendChat(CRules@ this, CPlayer@ player, string x, SColor color) {
    CBitStream params;
    params.write_netid(player.getNetworkID());
    params.write_u8(color.getRed());
    params.write_u8(color.getGreen());
    params.write_u8(color.getBlue());
    params.write_string(x);
    this.SendCommand(this.getCommandID("SEND_CHAT"), params);
}
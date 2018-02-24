#include "Logging.as"
#include "XMLParser.as"
#include "KL_Common.as"

shared class RatedChallenge {
    string challenger;
    string challenged;
    string kagClass;
    u8     duelToScore;
    u32    createdAt;

    RatedChallenge(string _challenger, string _challenged, string _kagClass, u8 _duelToScore) {
        challenger = _challenger;
        challenged = _challenged;
        kagClass = _kagClass;
        duelToScore = _duelToScore;
        createdAt = getGameTime();
    }

    bool isEqualTo(RatedChallenge other) {
        return challenger  == other.challenger
            && challenged  == other.challenged
            && kagClass    == other.kagClass
            && duelToScore == other.duelToScore;
    }

    bool isValid(string &out errMsg) {
        if (getPlayerByUsername(challenger) is null) {
            errMsg = "Challenger doesn't exist.";
            return false;
        }
        else if (getPlayerByUsername(challenged) is null) {
            errMsg = "Challenged player doesn't exist.";
            return false;
        }
        else if (challenger == challenged) {
            errMsg = "You can't challenge yourself!";
            return false;
        }
        else if (!(kagClass == "knight" || kagClass == "builder" || kagClass == "archer")) {
            errMsg = "Pick archer, builder or knight. Not '" + kagClass + "'";
            return false;
        }
        else if (duelToScore < 1 || duelToScore > 11) {
            errMsg = "The minimum you can duel to is 1 and the maximum is 11.";
            return false;
        }

        return true;
    }

    string serialize() {
        string ser = "<ratedchallenge>";
        ser += "<challenger>" + challenger + "</challenger>";
        ser += "<challenged>" + challenged + "</challenged>";
        ser += "<kagclass>" + kagClass  + "</kagclass>";
        ser += "<dueltoscore>" + duelToScore + "</dueltoscore>";
        ser += "<createdat>" + createdAt + "</createdat>";
        ser += "</ratedchallenge>";
        return ser;
    }

    bool deserialize(string ser) {
        XMLParser parser(ser);
        XMLDocument@ doc = parser.parse();
        return deserialize(doc.root);
    }

    // Returns true/false whether successful
    bool deserialize(XMLElement@ elem) {
        if (elem.name != "ratedchallenge") {
            log("RatedChallenge#deserialize", "ERROR xml malformed");
            return false;
        }

        for (int i=0; i < elem.children.length(); ++i) {
            XMLElement@ child = elem.children[i];

            if (child.name == "challenger") {
                challenger = child.value;
            }
            else if (child.name == "challenged") {
                challenged = child.value;
            }
            else if (child.name == "kagclass") {
                kagClass = child.value;
            }
            else if (child.name == "dueltoscore") {
                duelToScore = parseInt(child.value);
            }
            else if (child.name == "createdat") {
                createdAt = parseInt(child.value);
            }
            else {
                log("RatedChallenge#deserialize", "ERROR weird element name: '" + child.name + "'");
                return false;
            }
        }
        
        return true;
    }

    void debug() {
        log("RatedChallenge#debug",
            "challenger: " + challenger
            + ", challenged: " + challenged
            + ", kagClass: " + kagClass
            + ", duelToScore: " + duelToScore
            + ", createdAt: " + createdAt
            );
    }
}

shared class RatedMatch {
    string player1;
    string player2;
    string kagClass;
    u8     duelToScore;
    u8     player1Score;
    u8     player2Score;
    uint   startTime;

    RatedMatch(string _player1, string _player2, string _kagClass, u8 _duelToScore) {
        player1 = _player1;
        player2 = _player2;
        kagClass = _kagClass;
        duelToScore = _duelToScore;
        player1Score = 0;
        player2Score = 0;
        startTime = Time();
    }

    void saveFile() {
        string file = "KL_RecentMatch.cfg";
        ConfigFile cfg();
        cfg.add_string("data", serialize());
        cfg.saveFile(file);
        log("saveFile", "Wrote match to " + file);
    }

    string serialize() {
        string ser = "<ratedmatch>";
        ser += "<player1>" + player1 +"</player1>";
        ser += "<player2>" + player2 +"</player2>";
        ser += "<kagclass>" + kagClass +"</kagclass>";
        ser += "<dueltoscore>" + duelToScore +"</dueltoscore>";
        ser += "<player1score>" + player1Score +"</player1score>";
        ser += "<player2score>" + player2Score +"</player2score>";
        ser += "<starttime>" + startTime +"</starttime>";
        ser += "</ratedmatch>";
        return ser;
    }

    bool deserialize(string ser) {
        XMLParser parser(ser);
        XMLDocument@ doc = parser.parse();
        return deserialize(doc.root);
    }

    // Returns true/false whether successful
    bool deserialize(XMLElement@ elem) {
        if (elem.name != "ratedmatch") {
            log("RatedMatch#deserialize", "ERROR xml malformed");
            return false;
        }

        for (int i=0; i < elem.children.length(); ++i) {
            XMLElement@ child = elem.children[i];

            if (child.name == "player1") {
                player1 = child.value;
            }
            else if (child.name == "player2") {
                player1 = child.value;
            }
            else if (child.name == "kagclass") {
                kagClass = child.value;
            }
            else if (child.name == "dueltoscore") {
                duelToScore = parseInt(child.value);
            }
            else if (child.name == "player1score") {
                player1Score = parseInt(child.value);
            }
            else if (child.name == "player2score") {
                player2Score = parseInt(child.value);
            }
            else if (child.name == "starttime") {
                startTime = parseInt(child.value);
            }
            else {
                log("RatedMatch#deserialize", "ERROR weird element name: '" + child.name + "'");
                return false;
            }
        }
        
        return true;
    }

    void debug() {
        log("RatedMatch#debug", "player1: " + player1
            + "player2: " + player2
            + "kagClass: " + kagClass
            + "duelToScore: " + duelToScore
            + "player1Score: " + player1Score
            + "player2Score: " + player2Score
            + "startTime: " + startTime
            );
    }
}

shared class RatedPlayerInfo {
    string username;
    string region;
    u16 rating_knight;
    u16 wins_knight;
    u16 losses_knight;
    u16 rating_archer;
    u16 wins_archer;
    u16 losses_archer;
    u16 rating_builder;
    u16 wins_builder;
    u16 losses_builder;
    u32 coins;

    string serialize() {
        string xml = "<playerinfo>";
        xml += "<username>" + username + "</username>";
        xml += "<region>" + region + "</region>";
        {
            xml += "<knight>";
            xml += "<rating>" + rating_knight + "</rating>";
            xml += "<wins>" + wins_knight + "</wins>";
            xml += "<losses>" + losses_knight + "</losses>";
            xml += "</knight>";
        }
        {
            xml += "<builder>";
            xml += "<rating>" + rating_builder + "</rating>";
            xml += "<wins>" + wins_builder + "</wins>";
            xml += "<losses>" + losses_builder + "</losses>";
            xml += "</builder>";
        }
        {
            xml += "<archer>";
            xml += "<rating>" + rating_archer + "</rating>";
            xml += "<wins>" + wins_archer + "</wins>";
            xml += "<losses>" + losses_archer + "</losses>";
            xml += "</archer>";
        }
        xml += "<coins>" + coins + "</coins>";
        xml += "</playerinfo>";
        return xml;
    }

    bool deserialize(string ser) {
        XMLParser parser(ser);
        XMLDocument@ doc = parser.parse();
        return deserialize(doc.root);
    }

    // Returns true/false whether successful
    bool deserialize(XMLElement@ elem) {
        if (elem.name != "playerinfo") {
            log("RatedPlayerInfo#deserialize", "ERROR xml malformed");
            return false;
        }

        username = elem.getChildByName("username").value;
        region = elem.getChildByName("region").value;
        rating_knight = parseInt(elem.getChildByName("knight").getChildByName("rating").value);
        wins_knight = parseInt(elem.getChildByName("knight").getChildByName("wins").value);
        losses_knight = parseInt(elem.getChildByName("knight").getChildByName("losses").value);

        rating_archer = parseInt(elem.getChildByName("archer").getChildByName("rating").value);
        wins_archer = parseInt(elem.getChildByName("archer").getChildByName("wins").value);
        losses_archer = parseInt(elem.getChildByName("archer").getChildByName("losses").value);

        rating_builder = parseInt(elem.getChildByName("builder").getChildByName("rating").value);
        wins_builder = parseInt(elem.getChildByName("builder").getChildByName("wins").value);
        losses_builder = parseInt(elem.getChildByName("builder").getChildByName("losses").value);

        coins = parseInt(elem.getChildByName("coins").value);

        return true;
    }
}

shared class RatedMatchPlayerStats {
    string nickname;
    string clantag;
    int head;
    int gender;

    void setStats(CPlayer@ player) {
        nickname = player.getCharacterName();
        clantag = player.getClantag();
        head = player.getHead();
        gender = player.getSex();
    }

    string serialize(int playerNum) {
        string ser = "<player" + playerNum + "stats>";
        ser += "<nickname>" + escapeXMLString(nickname) + "</nickname>";
        ser += "<clantag>" + escapeXMLString(clantag) + "</clantag>";
        ser += "<head>" + head + "</head>";
        ser += "<gender>" + gender + "</gender>";
        ser += "</player" + playerNum + "stats>";
        return ser;
    }
}

shared class RatedMatchRoundStats {
    uint start_time;
    uint end_time;
    string winner;
    MatchEvent[] events;

    RatedMatchRoundStats() {
        start_time = Time();
    }

    void logEvent(MatchEvent evt) {
        //log("logEvent", "Called: " + evt.type);
        events.push_back(evt);
    }

    string serialize() {
        string ser;
        ser += "<roundstats>";
        ser += "<starttime>"+start_time+"</starttime>";
        ser += "<endtime>"+end_time+"</endtime>";
        ser += "<winner>"+winner+"</winner>";
        ser += "<events>";
        for (int i=0; i < events.length; ++i) {
            ser += events[i].serialize();
        }
        ser += "</events>";
        ser += "</roundstats>";
        return ser;
    }
}

shared class RatedMatchStats {
    RatedMatchPlayerStats player1_stats;
    RatedMatchPlayerStats player2_stats;

    void setPlayerStats(CPlayer@ player, int playerNum) {
        if (playerNum == 1) {
            player1_stats.setStats(player);
        }
        else if (playerNum == 2) {
            player2_stats.setStats(player);
        }
        else {
            log("setPlayerStats", "ERROR playerNum should be 1 or 2");
        }
    }

    string serialize() {
        string ser;
        ser += "<ratedmatchstats>";
        ser += player1_stats.serialize(1);
        ser += player2_stats.serialize(2);
        ser += "</ratedmatchstats>";
        return ser;
    }
}

shared enum MatchEventType {
    PLAYER_BLOB_SET,
    KNIGHT_JAB_START,
    KNIGHT_SLASH_START,
    KNIGHT_POWER_SLASH_START,
    KNIGHT_JAB_HIT,
    KNIGHT_SLASH_HIT,
    KNIGHT_POWER_SLASH_HIT,
    KNIGHT_BLOCK_JAB,
    KNIGHT_BLOCK_SLASH,
    KNIGHT_BLOCK_POWER_SLASH,
    KNIGHT_BLOCK_BOMB,
    KNIGHT_SHIELD_BASH_HIT,
    ARCHER_SHOT,
    ARCHER_SHOT_HIT,
    ARCHER_TRIPLE_SHOT,
    BUILDER_PICKAXE_START, // deprecated
    BUILDER_DROP_SPIKES,
    BUILDER_PICKAXE_HIT,
    DEATH,
    STOMP_HIT,
    LIGHT_BOMB,
    THROW_BOMB,
    CATCH_BOMB,
    BOMB_HIT,
    SPIKES_HIT,
    CRUSH_HIT,
    FALL_HIT,
    KNOCKED // deprecated
}

shared string matchEventTypeToString(MatchEventType type) {
    if (type == PLAYER_BLOB_SET) {
        return "PLAYER_BLOB_SET";
    }
    else if (type == KNIGHT_JAB_START) { 
        return "KNIGHT_JAB_START";
    }
    else if (type == KNIGHT_SLASH_START) { 
        return "KNIGHT_SLASH_START";
    }
    else if (type == KNIGHT_POWER_SLASH_START) { 
        return "KNIGHT_POWER_SLASH_START";
    }
    else if (type == KNIGHT_JAB_HIT) {
        return "KNIGHT_JAB_HIT";
    }
    else if (type == KNIGHT_SLASH_HIT) {
        return "KNIGHT_SLASH_HIT";
    }
    else if (type == KNIGHT_POWER_SLASH_HIT) {
        return "KNIGHT_POWER_SLASH_HIT";
    }
    else if (type == KNIGHT_BLOCK_JAB) {
        return "KNIGHT_BLOCK_JAB";
    }
    else if (type == KNIGHT_BLOCK_SLASH) {
        return "KNIGHT_BLOCK_SLASH";
    }
    else if (type == KNIGHT_BLOCK_POWER_SLASH) {
        return "KNIGHT_BLOCK_POWER_SLASH";
    }
    else if (type == KNIGHT_BLOCK_BOMB) {
        return "KNIGHT_BLOCK_BOMB";
    }
    else if (type == KNIGHT_SHIELD_BASH_HIT) {
        return "KNIGHT_SHIELD_BASH_HIT";
    }
    else if (type == ARCHER_SHOT) {
        return "ARCHER_SHOT";
    }
    else if (type == ARCHER_SHOT_HIT) {
        return "ARCHER_SHOT_HIT";
    }
    else if (type == ARCHER_TRIPLE_SHOT) {
        return "ARCHER_TRIPLE_SHOT";
    }
    else if (type == BUILDER_PICKAXE_START) {
        return "BUILDER_PICKAXE_START";
    }
    else if (type == BUILDER_DROP_SPIKES) {
        return "BUILDER_DROP_SPIKES";
    }
    else if (type == BUILDER_PICKAXE_HIT) {
        return "BUILDER_PICKAXE_HIT";
    }
    if (type == DEATH) {
        return "DEATH";
    }
    if (type == STOMP_HIT) {
        return "STOMP_HIT";
    }
    else if (type == LIGHT_BOMB) {
        return "LIGHT_BOMB";
    }
    else if (type == THROW_BOMB) {
        return "THROW_BOMB";
    }
    else if (type == CATCH_BOMB) {
        return "CATCH_BOMB";
    }
    else if (type == BOMB_HIT) {
        return "BOMB_HIT";
    }
    else if (type == SPIKES_HIT) {
        return "SPIKES_HIT";
    }
    else if (type == CRUSH_HIT) {
        return "CRUSH_HIT";
    }
    else if (type == FALL_HIT) {
        return "FALL_HIT";
    }
    else if (type == KNOCKED) {
        return "KNOCKED";
    }
    else {
        return "UNRECOGNIZED_TYPE_" + type;
    }
}

shared class MatchEvent {
    MatchEventType type;
    u16 blob_netid;
    string[] params;
    u32 time;

    MatchEvent(MatchEventType _type, u16 _blob_netid, string[] _params) {
        type = _type;
        blob_netid = _blob_netid;
        params = _params;
        time = getGameTime();
    }

    string serialize() {
        string ser = type + "," + time + "," + blob_netid;
        for (uint i=0; i < params.length; ++i) {
            ser += "," + params[i];
        }
        ser += ";";
        return ser;
    }

    void debug() {
        string msg = "type: " + matchEventTypeToString(type) + ", time: " + time + ", blob_netid: " + blob_netid + ", params: ";
        for (int i=0; i < params.length; ++i) {
            msg += params[i];
            if (i != params.length-1)
                msg += ", ";
        }
        log("MatchEvent", msg);
    }
}

shared class RatedMatchBet {
    string betterUsername;
    string bettedOnUsername;
    u32 betAmount;

    RatedMatchBet(string _betterUsername, string _bettedOnUsername, u32 _betAmount) {
        betterUsername = _betterUsername;
        bettedOnUsername = _bettedOnUsername;
        betAmount = _betAmount;
    }

    string serialize() {
        string ser = "<ratedmatchbet>";
        ser += "<betterusername>" + betterUsername + "</betterusername>";
        ser += "<bettedonusername>" + bettedOnUsername + "</bettedonusername>";
        ser += "<betamount>" + betAmount + "</betamount>";
        ser += "</ratedmatchbet>";
        return ser;
    }

    bool deserialize(string ser) {
        XMLParser parser(ser);
        XMLDocument@ doc = parser.parse();
        return deserialize(doc.root);
    }

    // Returns true/false whether successful
    bool deserialize(XMLElement@ elem) {
        if (elem.name != "ratedmatchbet") {
            log("RatedMatchBet#deserialize", "ERROR xml malformed");
            return false;
        }

        for (int i=0; i < elem.children.length(); ++i) {
            XMLElement@ child = elem.children[i];
            if (child.name == "betterusername") {
                betterUsername = child.value;
            }
            else if (child.name == "bettedonusername") {
                bettedOnUsername = child.value;
            }
            else if (child.name == "betamount") {
                betAmount = parseInt(child.value);
            }
        }

        return true;
    }
}

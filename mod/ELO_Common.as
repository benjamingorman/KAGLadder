#include "Logging.as"
#include "XMLParser.as"

shared bool isRatedMatchInProgress() {
    return getRules().get_bool("VAR_MATCH_IN_PROGRESS");
}

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
        string file = "ELO_RecentMatch.cfg";
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

shared class PlayerRatings {
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

    string serialize() {
        string xml = "<playerratings>";
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
        xml += "</playerratings>";
        return xml;
    }

    bool deserialize(string ser) {
        XMLParser parser(ser);
        XMLDocument@ doc = parser.parse();
        return deserialize(doc.root);
    }

    // Returns true/false whether successful
    bool deserialize(XMLElement@ elem) {
        if (elem.name != "playerratings") {
            log("PlayerRatigns#deserialize", "ERROR xml malformed");
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
        ser += "<nickname>" + nickname + "</nickname>";
        ser += "<clantag>" + clantag + "</clantag>";
        ser += "<head>" + head + "</head>";
        ser += "<gender>" + gender + "</gender>";
        ser += "</player" + playerNum + "stats>";
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
        string ser = "<ratedmatchstats>";
        ser += player1_stats.serialize(1);
        ser += player2_stats.serialize(2);
        ser += "</ratedmatchstats>";
        return ser;
    }
}

// It's a bit weird to need to duplicate this, but since we can't sync PlayerRatings objects directly
// ... we sync the serialized version and then have the clients deserialize them for quick lookup
shared string getSerializedPlayerRatingsRulesProp(string username) {
    return "SER_RATINGS_" + username;
}

// Returns the rules property used for storing the rating of the given player
shared string getPlayerRatingsRulesProp(string username) {
    return "RATINGS_" + username;
}

// Returns the player's rating for the given class or -1 if it's not loaded
shared s16 getPlayerRating(string username, string kagClass) {
    string ser_ratings_prop = getSerializedPlayerRatingsRulesProp(username);
    string ratings_prop = getPlayerRatingsRulesProp(username);

    if (getRules().exists(ratings_prop) || getRules().exists(ser_ratings_prop)) {
        PlayerRatings pr;

        if (getRules().exists(ratings_prop)) {
            getRules().get(ratings_prop, pr);
        }
        else {
            string ser = getRules().get_string(ser_ratings_prop);
            pr.deserialize(ser);
            getRules().set(ratings_prop, pr);
        }

        if (kagClass == "knight")
            return pr.rating_knight;
        else if (kagClass == "archer")
            return pr.rating_archer;
        else if (kagClass == "builder")
            return pr.rating_builder;
    }
    return -1;
}

// Returns a string representation of the player's rating for the given class
shared string getPlayerRatingString(string username, string kagClass) {
    s16 rat = getPlayerRating(username, kagClass);
    if (rat == -1) {
        // Rating can't be loaded
        return "?";
    }
    else {
        return "" + rat;
    }
}

shared string getPlayerRatingTitle(string username) {
    s16 elo_archer = getPlayerRating(username, "archer");
    s16 elo_builder = getPlayerRating(username, "builder");
    s16 elo_knight = getPlayerRating(username, "knight");
    if (elo_archer == -1 && elo_builder == -1 && elo_knight == -1)
        return "Loading...";
    else {
        s16 max_elo = Maths::Max(elo_archer, Maths::Max(elo_builder, elo_knight));
        string max_class;
        if (max_elo == elo_archer) max_class = "archer";
        if (max_elo == elo_builder) max_class = "builder";
        if (max_elo == elo_knight) max_class = "knight";
        return getTitleFromRating(max_elo) + " " + max_class;
    }
}

shared string getTitleFromRating(s16 rat) {
    if (rat >= 2600) {
        return "Legendary";
    }
    else if (rat >= 2200) {
        return "Grand-master";
    }
    else if (rat >= 2000) {
        return "Master";
    }
    else if (rat >= 1800) {
        return "Diamond";
    }
    else if (rat >= 1600) {
        return "Platinum";
    }
    else if (rat >= 1400) {
        return "Gold";
    }
    else if (rat >= 1200) {
        return "Silver";
    }
    else if (rat >= 1000) {
        return "Bronze";
    }
    else {
        return "Peasant";
    }
}

shared void whisper(CPlayer@ player, string msg) {
    SColor color(255, 0, 0, 255);
    whisper(player, msg, color);
}

shared void whisperAll(string msg) {
    SColor color(255, 0, 0, 255);
    for (int i=0; i < getPlayerCount(); ++i) {
        CPlayer@ player = getPlayer(i);
        whisper(player, msg, color);
    }
}

shared void whisper(CPlayer@ player, string msg, SColor color) {
    CBitStream params;
    params.write_netid(player.getNetworkID());
    params.write_u8(color.getRed());
    params.write_u8(color.getGreen());
    params.write_u8(color.getBlue());
    params.write_string(msg);
    getRules().SendCommand(getRules().getCommandID("SEND_CHAT"), params);
}

shared string[] tokenize(string text) {
    string[]@ dirtyTokens = text.split(" "); // there could be 0 length tokens
    string[] tokens;

    for (int i=0; i < dirtyTokens.length; ++i) {
        if (dirtyTokens[i].length > 0) {
            tokens.push_back(dirtyTokens[i]);
        }
    }

    return tokens;
}

shared bool isStringPositiveInteger(string num) {
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

shared CPlayer@ getPlayerByIdent(string ident) {
    string errMsg;
    return getPlayerByIdent(ident, errMsg);
}

shared CPlayer@ getPlayerByIdent(string ident, string &out errMsg) {
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
        errMsg = "Couldn't find anyone matching " + ident;
    }
    else {
        errMsg = "Multiple people match '" + ident + "', be more specific.";
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
    help += "!challenge all\n";
    help += "!accept someone (accept a challenge)\n";
    help += "!reject someone (reject a challenge)\n";
    help += "!cancel (cancels the current duel)\n";
    return help;
}

shared bool randomFlipCoin() {
    return XORRandom(2) == 0;
}

shared void predictRatingChanges(RatedMatch match, u16 p1_rating, u16 p2_rating, int &out change_p1, int &out change_p2) {
    u8 winner = 0;
    if (match.player1Score > match.player2Score) {
        winner = 1;
    }
    else if (match.player2Score > match.player1Score) {
        winner = 2;
    }

    if (winner == 1) {
        change_p1 = 10;
        change_p2 = -10;
    }
    else if (winner == 2) {
        change_p1 = -10;
        change_p2 = 10;
    }
    else {
        change_p1 = 0;
        change_p2 = 0;
    }
}

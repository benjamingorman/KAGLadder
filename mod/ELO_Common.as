#include "Logging.as"
#include "ELO_Types.as"

shared bool isRatedMatchInProgress() {
    return getRules().get_bool("VAR_MATCH_IN_PROGRESS");
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

shared PlayerRatings@ getStoredPlayerRatings(string username) {
    string ser_ratings_prop = getSerializedPlayerRatingsRulesProp(username);
    string ratings_prop = getPlayerRatingsRulesProp(username);

    PlayerRatings pr;
    if (getRules().exists(ratings_prop)) {
        getRules().get(ratings_prop, pr);
        return @pr;
    }
    else if (getRules().exists(ser_ratings_prop)) {
        string ser = getRules().get_string(ser_ratings_prop);
        pr.deserialize(ser);
        getRules().set(ratings_prop, pr);
        return @pr;
    }
    else {
        return null;
    }
}

bool isQueueSystemWaiting() {
    return getRules().get_u32("VAR_QUEUE_WAIT_UNTIL") > Time();
}

uint getQueueSystemWaitSecondsLeft() {
    return getRules().get_u32("VAR_QUEUE_WAIT_UNTIL") - Time();
}

// Returns the player's rating for the given class or -1 if it's not loaded
shared s16 getPlayerRating(string username, string kagClass) {
    PlayerRatings@ pr = getStoredPlayerRatings(username);

    if (pr !is null) {
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

bool isValidKagClass(string x) {
    return x == "archer" || x == "builder" || x == "knight";
}

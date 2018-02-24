// This script prevents players from spamming the chat, by limiting them to 1 message per 0.5secs
#include "Logging.as";

dictionary SPAM_PREVENTION;

// Returns true if the player already sent a message recently
bool spamPrevention(string username) {
    int64 lastChatTime;
    if (SPAM_PREVENTION.get(username, lastChatTime)) {
        // Careful to make sure a 'lastChatTime' value from a previous round 
        // doesn't prevent the player from talking in a future round
        if (getGameTime() > lastChatTime && lastChatTime > getGameTime() - 15)
            return true;
    }
    SPAM_PREVENTION.set(username, getGameTime());
    return false;
}


bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player) {
    if (player is null)
        return true;
    else if (spamPrevention(player.getUsername())) {
        //log("onServerProcessChat", "Prevented spam for " + player.getUsername());
        return false;
    }
    return true;
}

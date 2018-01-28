#include "Logging.as";
#include "TCPR_Common.as";

const int PING_FREQUENCY_SECS = 5;
TCPR::Request[] REQUESTS;

void onInit(CRules@ this) {
    log("onInit", "Called");

    this.set_bool("TCPR_CLIENT_CONNECTED", false);
    for (int i=0; i < TCPR::MAX_REQUESTS; ++i) {
        this.set_string(TCPR::getResponseProp(i), "");
    }
}

void onTick(CRules@ this) {
    TCPR::update(@REQUESTS);
    if (getGameTime() % (PING_FREQUENCY_SECS * 30) == 0) {
        SendPing();
    }
}

void onTCPRConnect(CRules@ this) {
    log("onTCPRConnect", "Client connected.");
    // Assume only 1 client. Could there be more?
    this.set_bool("TCPR_CLIENT_CONNECTED", true);
}

void onTCPRDisconnect(CRules@ this) {
    log("onTCPRDisconnect", "Client disconnected.");
    this.set_bool("TCPR_CLIENT_CONNECTED", false);
}

void SendPing() {
    TCPR::Request req("ping", @PingHandler);
    req.setParam("time", ""+getGameTime());
    string errMsg;
    if (TCPR::makeRequest(@REQUESTS, @req, errMsg))
        log("SendPing", "errMsg: " + errMsg);
    else {
        log("SendPing", "Sent ping request: " + req.id);
    }
}

void PingHandler(int reqID, string response) {
    log("PingHandler", "Received ping (" + reqID + ") response: " + response);
}

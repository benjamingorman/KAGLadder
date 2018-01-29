#include "Logging.as";
#include "TCPR_Common.as";

const int PING_FREQUENCY_SECS = 5;
TCPR::Request[] REQUESTS;

void onInit(CRules@ this) {
    log("onInit", "Called");

    this.set_bool("TCPR_CLIENT_CONNECTED", false);
    for (int i=0; i < TCPR::MAX_REQUESTS; ++i) {
        TCPR::setRequestResponse(i, "");
        TCPR::setRequestState(i, TCPR::REQ_UNUSED);
    }
}

void onTick(CRules@ this) {
    TCPR::update(@REQUESTS);
    /*
    if (getGameTime() % (PING_FREQUENCY_SECS * 30) == 0) {
        SendPing();
    }
    */
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
    TCPR::makeRequest(@REQUESTS, @req);
}

void PingHandler(TCPR::Request req, string response) {
    log("PingHandler", "Received ping (" + req.id + ") response: " + response);
}

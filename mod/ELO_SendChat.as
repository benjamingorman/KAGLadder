// See ELO_Common for sendChat function
#include "Logging.as"
#include "ELO_Common.as"

void onInit(CRules@ this) {
    this.addCommandID("SEND_CHAT");
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params) {
    if (cmd == this.getCommandID("SEND_CHAT") && getNet().isClient()) {
        u16 netID = params.read_netid();
        u8 r = params.read_u8();
        u8 g = params.read_u8();
        u8 b = params.read_u8();
        string text = params.read_string();
        CPlayer@ local_player = getLocalPlayer();
        if(local_player !is null && local_player.getNetworkID() == netID) {
            client_AddToChat(text, SColor(255,r,g,b));
        }
    }
}
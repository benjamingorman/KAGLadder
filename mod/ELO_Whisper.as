/* In order to enable whispers we need a script on the client side that can send and receive
 * whisper commands
 */
void onInit(CRules@ this) {
    this.addCommandID("SEND_CHAT");
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params) {
    if (cmd == this.getCommandID("SEND_CHAT") && getNet().isClient()) {
        u16 netID = params.read_netid();
        u8 r = params.read_u8();
        u8 g = params.read_u8();
        u8 b = params.read_u8();
        string msg = params.read_string();
        CPlayer@ local_player = getLocalPlayer();
        if(local_player !is null && local_player.getNetworkID() == netID) {
            client_AddToChat(msg, SColor(255,r,g,b));
        }
    }
}

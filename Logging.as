shared void log(string func_name, string msg)
{
    string fullScriptName = getCurrentScriptName();
    string[]@ parts = fullScriptName.split("/");
    string shortScriptName = parts[parts.length-1];
    u32 t = getGameTime();

    printf("[KT][" + shortScriptName + "][" + func_name + "][" + t + "] " + msg);
}

// Sends a chat message
shared void broadcast(string msg) {
    getNet().server_SendMsg(msg);
    log("broadcast", msg);
}
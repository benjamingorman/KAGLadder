#include "RulesCore.as";
#include "Logging.as";
#include "ELO_Common.as";

void onRestart(CRules@ this)
{
	this.set_bool("managed teams", true);
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	RulesCore@ core;
	this.get("core", @core);
	
	core.ChangePlayerTeam(player, this.getSpectatorTeamNum());
}

void onPlayerRequestTeamChange(CRules@ this, CPlayer@ player, u8 newTeam)
{
	RulesCore@ core;
	this.get("core", @core);

	if (isRatedMatchInProgress()) {
		log("onPlayerRequestTeamChange", "Blocked player from joining during duel");
		whisper(player, "You can't join while a duel is happening.");
	}
	else {
		core.ChangePlayerTeam(player, newTeam);
	}
}

void onPlayerRequestSpawn(CRules@ this, CPlayer@ player)
{
}

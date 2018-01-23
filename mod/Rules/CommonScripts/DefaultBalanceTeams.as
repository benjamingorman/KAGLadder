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

	if (this.get_u8("CURRENT_DUEL_STATE") == DuelState::ACTIVE_DUEL) {
		log("onPlayerRequestTeamChange", "Blocked player from joining during duel");
		broadcast("You can't join while a duel is happening.");
	}
	else {
		core.ChangePlayerTeam(player, newTeam);
	}
}

void onPlayerRequestSpawn(CRules@ this, CPlayer@ player)
{
}

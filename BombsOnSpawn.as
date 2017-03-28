#include "Logging.as";

bool SetMaterials(CBlob@ blob,  const string &in name, const int quantity)
{
	CInventory@ inv = blob.getInventory();

	//already got them?
	if (inv.isInInventory(name, quantity))
		return false;

	//otherwise...
	inv.server_RemoveItems(name, quantity); //shred any old ones

	CBlob@ mat = server_CreateBlob(name);
	if (mat !is null)
	{
		mat.Tag("do not set materials");
		mat.server_SetQuantity(quantity);
		if (!blob.server_PutInInventory(mat))
		{
			mat.setPosition(blob.getPosition());
		}
	}

	return true;
}

bool GiveSpawnResources(CRules@ this, CBlob@ blob, CPlayer@ player)
{
    bool ret;
	if (blob.getName() == "knight" && !player.hasTag("given bombs"))
	{
        ret = SetMaterials(blob, "mat_bombs", 1);
        player.Tag("given bombs");
	}
	else if (blob.getName() == "builder" && !player.hasTag("given bombs"))
	{
        ret = SetMaterials(blob, "mat_stone", 300);
        player.Tag("given bombs");
	}
    return ret;
}

void onRestart(CRules@ this) {
    for (int i=0; i < getPlayerCount(); i++) {
        CPlayer@ player = getPlayer(i);
        player.Untag("given bombs");
    }
}

//when the player is set, give materials if possible
void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (!getNet().isServer())
		return;

	if (blob !is null && player !is null) 
	{
        GiveSpawnResources(this, blob, player);
	}
}

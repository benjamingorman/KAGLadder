// This script runs last on relevant blobs and allows for events to be captured where
// script order of execution is important
#include "Logging.as"
#include "KL_Common.as"
#include "KL_Types.as"
#include "Hitters.as"

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData) {
    if (!getNet().isServer())
        return damage;

    if (getRules().get_bool("KL_DEBUG"))
        log("onHit", ""+this.getNetworkID()
            + ", hitter: " + hitterBlob.getNetworkID()
            + ", data: " + customData
            + ", damage: " + damage
            );

    u16 netid = this.getNetworkID();
    string hitter_netid = "" + hitterBlob.getNetworkID();
    string hitter_player_username;
    string dmg = ""+damage;

    if (damage == 0 && this.getName() == "knight") {
        // Detect knight shield blocks
        if (customData == Hitters::bomb)
            triggerMatchEvent(MatchEventType::KNIGHT_BLOCK_BOMB, netid, hitter_player_username);
        else if (customData == Hitters::sword) {
            u8 enemyState = getKnightState(hitterBlob);

            if (isJabState(enemyState)) {
                triggerMatchEvent(MatchEventType::KNIGHT_BLOCK_JAB, netid, hitter_netid);
            }
            else if (isSlashState(enemyState)) {
                triggerMatchEvent(MatchEventType::KNIGHT_BLOCK_SLASH, netid, hitter_netid);
            }
            else if (isPowerSlashState(enemyState)) {
                triggerMatchEvent(MatchEventType::KNIGHT_BLOCK_POWER_SLASH, netid, hitter_netid);
            }
        }
    }
    return damage;
}

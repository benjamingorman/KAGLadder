#include "KnightCommon.as"
#include "Hitters.as"
#include "Logging.as"
#include "KL_Common.as"
#include "KL_Types.as"

void onBlobCreated(CRules@ this, CBlob@ blob) {
    if (!getNet().isServer())
        return;

    string name = blob.getName();
    if (name == "archer" || name == "builder" || name == "knight" || name == "bomb") {
        blob.AddScript("KL_MatchEvents.as");
    }
}

void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player) {
    if (!getNet().isServer())
        return;

    if (blob !is null && player !is null) {
        //log("onSetPlayer", this.getName() + "-" + player.getUsername());
        if (isValidKagClass(blob.getName())) {
            triggerMatchEvent(MatchEventType::PLAYER_BLOB_SET, blob.getNetworkID(), player.getUsername());
        }
    }
}

// Blob stuff
void onCommand(CBlob@ this, u8 cmd, CBitStream @params) {
    if (!getNet().isServer())
        return;

	if (this.getName() == "archer") {
        if (cmd == this.getCommandID("shoot arrow")) {
            Vec2f arrowPos = params.read_Vec2f();
            Vec2f arrowVel = params.read_Vec2f();
            u8 arrowType = params.read_u8();
            bool legolas = params.read_bool();

            if (legolas) {
                triggerMatchEvent(MatchEventType::ARCHER_TRIPLE_SHOT, this.getNetworkID(), ""+arrowType);
            }
            else {
                triggerMatchEvent(MatchEventType::ARCHER_SHOT, this.getNetworkID(), ""+arrowVel.Length(), ""+arrowType);
            }
        }
    }
    else if (this.getName() == "builder") {
        if (cmd == this.getCommandID("placeBlob")) {
            CBlob @carryBlob = getBlobByNetworkID(params.read_u16());
            if (carryBlob !is null) {
                if (carryBlob.getName() == "spikes") {
                    triggerMatchEvent(MatchEventType::BUILDER_DROP_SPIKES, this.getNetworkID());
                }
            }
        }
    }
}

void onTick(CBlob@ this) {
    // Detect knight attacks starting
    if (this.getName() == "knight") {
        u16 netid = this.getNetworkID();
        KnightInfo@ info;
        this.get("knightInfo", @info);

        if (info is null) {
            return;
        }
        else {
            u8 state = info.state;
            u8 delta = info.swordTimer; 
            if (delta == DELTA_BEGIN_ATTACK + 1) {
                // It's the first tick of an attack
                if (isJabState(state)) {
                    triggerMatchEvent(MatchEventType::KNIGHT_JAB_START, netid);
                }
                else if (isSlashState(state)) {
                    triggerMatchEvent(MatchEventType::KNIGHT_SLASH_START, netid);
                }
                else if (isPowerSlashState(state)) {
                    triggerMatchEvent(MatchEventType::KNIGHT_POWER_SLASH_START, netid);
                }
            }
        }
    }
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData) {
    if (!getNet().isServer())
        return damage;

    if (getRules().get_bool("KL_DEBUG"))
        log("MatchEvents:onHit", ""+this.getNetworkID()
            + ", hitter: " + hitterBlob.getNetworkID()
            + ", data: " + customData
            + ", damage: " + damage
            );

    u16 netid = this.getNetworkID();
    string hitter_netid = "" + hitterBlob.getNetworkID();
    string hitter_player_username;
    string dmg = ""+damage;

    if (hitterBlob.getDamageOwnerPlayer() !is null) {
        hitter_player_username = hitterBlob.getDamageOwnerPlayer().getUsername();
    }

    if (customData == Hitters::shield) {
        triggerMatchEvent(MatchEventType::KNIGHT_SHIELD_BASH_HIT, netid, hitter_netid);
    }
    else if (damage == 0 && this.getName() == "knight") {
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
    else if (damage > 0) {
        if (customData == Hitters::builder) {
            triggerMatchEvent(MatchEventType::BUILDER_PICKAXE_HIT, netid, hitter_netid);
        }
        else if (customData == Hitters::arrow) {
            triggerMatchEvent(MatchEventType::ARCHER_SHOT_HIT, netid, hitter_player_username, dmg);
        }
        else if (customData == Hitters::stomp) {
            triggerMatchEvent(MatchEventType::STOMP_HIT, netid, hitter_netid, dmg);
        }
        else if (customData == Hitters::bomb) {
            triggerMatchEvent(MatchEventType::BOMB_HIT, netid, hitter_player_username, dmg);
        }
        else if (customData == Hitters::spikes) {
            triggerMatchEvent(MatchEventType::SPIKES_HIT, netid, hitter_player_username, dmg);
        }
        else if (customData == Hitters::crush) {
            triggerMatchEvent(MatchEventType::CRUSH_HIT, netid, dmg);
        }
        else if (customData == Hitters::fall) {
            triggerMatchEvent(MatchEventType::FALL_HIT, netid, dmg);
        }
        else if (customData == Hitters::sword && hitterBlob.getName() == "knight") {
            u8 enemyState = getKnightState(hitterBlob);

            if (isJabState(enemyState)) {
                triggerMatchEvent(MatchEventType::KNIGHT_JAB_HIT, netid, hitter_netid);
            }
            else if (isSlashState(enemyState)) {
                triggerMatchEvent(MatchEventType::KNIGHT_SLASH_HIT, netid, hitter_netid);
            }
            else if (isPowerSlashState(enemyState)) {
                triggerMatchEvent(MatchEventType::KNIGHT_POWER_SLASH_HIT, netid, hitter_netid);
            }
        }
    }

    return damage;
}

void onDie(CBlob@ this) {
    if (!getNet().isServer())
        return;

    if (isValidKagClass(this.getName()))
        triggerMatchEvent(MatchEventType::DEATH, this.getNetworkID());
}

// Bomb stuff
void onAttach( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint ) {
    if (!getNet().isServer())
        return;

    if (this.getName() == "bomb") {
        s32 bombTimer = this.get_s32("bomb_timer");
        bool justLit = bombTimer == getGameTime() + 120;

        //log("onAttach", "bombTimer: " + bombTimer + ", justLit: " + justLit);

        u16 netid = attached.getNetworkID();
        string bomb_owner_username;
        if (this.getDamageOwnerPlayer() !is null) {
            bomb_owner_username = this.getDamageOwnerPlayer().getUsername();
        }

        if (justLit)
            triggerMatchEvent(MatchEventType::LIGHT_BOMB, netid, bomb_owner_username);
        else
            triggerMatchEvent(MatchEventType::CATCH_BOMB, netid, bomb_owner_username);
    }
}

void onDetach( CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint ) {
    if (!getNet().isServer())
        return;

    if (this.getName() == "bomb") {
        triggerMatchEvent(MatchEventType::THROW_BOMB, detached.getNetworkID());
    }
}

u8 getKnightState(CBlob@ knight) {
    if (knight is null || knight.getName() != "knight") {
        log("getKnightState", "ERROR invalid blob");
        return KnightStates::normal;
    }

    KnightInfo@ info;
    knight.get("knightInfo", @info);

    if (info is null) {
        log("getKnightState", "ERROR no knightInfo");
        return KnightStates::normal;
    }

    return info.state;
}

bool isJabState(u8 knightState) {
    return KnightStates::sword_cut_mid <= knightState && knightState <= KnightStates::sword_cut_down;
}

bool isSlashState(u8 knightState) {
    return knightState == KnightStates::sword_power;
}

bool isPowerSlashState(u8 knightState) {
    return knightState == KnightStates::sword_power_super;
}

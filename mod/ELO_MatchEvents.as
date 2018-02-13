#include "KnightCommon.as"
#include "Hitters.as"
#include "Logging.as"
#include "ELO_Common.as"
#include "ELO_Types.as"

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player) {
    if (player is null || !player.isMod())
        return true;

    log("onServerProcessChat", "Got: " + text_in);
    string[] tokens = tokenize(text_in);

    if (tokens.length() == 0) {
        return true;
    }
    else if (tokens[0] == "!shieldbot") {
        Vec2f pos(0,0);
        if (player.getBlob() !is null) {
            pos = player.getBlob().getPosition();
        }
        CBlob@ knight = server_CreateBlob("knight", -1, pos);
        knight.AddScript("ShieldBot.as");
    }
    return true;
}

void onSetPlayer(CBlob@ this, CPlayer@ player) {
    if (getNet().isServer() && this !is null && player !is null) {
        //log("onSetPlayer", this.getName() + "-" + player.getUsername());
        string name = this.getName();
        if (name == "archer" || name == "builder" || name == "knight")
            triggerMatchEvent(MatchEventType::PLAYER_BLOB_SET, this.getNetworkID(), player.getUsername());
    }
}

// Blob stuff
f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData) {
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
            KnightInfo@ knight;

            if (damage == 1.0) {
                // Jab
                triggerMatchEvent(MatchEventType::KNIGHT_JAB_HIT, netid, hitter_netid);
            }
            else if (damage == 2.0) {
                if (hitterBlob.get("knightInfo", @knight)) {
                    if (knight.state == KnightStates::sword_power) {
                        triggerMatchEvent(MatchEventType::KNIGHT_SLASH_HIT, netid, hitter_netid);
                    }
                    else if (knight.state == KnightStates::sword_power_super) {
                        triggerMatchEvent(MatchEventType::KNIGHT_POWER_SLASH_HIT, netid, hitter_netid);
                    }
                }
                else {
                    log("onHit", "Couldn't get hitter knightInfo");
                }
            }
        }
    }

    return damage;
}

/*
void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData ) {
    log("MatchEvents:onHitBlob", ""+this.getNetworkID()
        + ", hit: " + hitBlob.getNetworkID()
        + ", data: " + customData
        + ", damage: " + damage
        );
}
*/

void onDie(CBlob@ this) {
    string name = this.getName();
    if (name == "archer" || name == "builder" || name == "knight")
        triggerMatchEvent(MatchEventType::DEATH, this.getNetworkID());
}

// Bomb stuff
void onAttach( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint ) {
    if (this.getName() == "bomb") {
        s32 bombTimer = this.get_s32("bomb_timer");
        bool justLit = bombTimer == getGameTime() + 120;

        log("onAttach", "bombTimer: " + bombTimer + ", justLit: " + justLit);

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
    if (this.getName() == "bomb") {
        triggerMatchEvent(MatchEventType::THROW_BOMB, detached.getNetworkID());
    }
}

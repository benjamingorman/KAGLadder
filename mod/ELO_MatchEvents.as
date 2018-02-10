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

void onBlobCreated( CRules@ this, CBlob@ blob ) {
    log("onBlobCreated", "Called for: " + blob.getNetworkID() + ", " + blob.getName());
}

// Blob stuff
f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData) {
    log("MatchEvents:onHit", ""+this.getNetworkID()
        + ", hitter: " + hitterBlob.getNetworkID()
        + ", data: " + customData
        + ", damage: " + damage
        );

    string[] params = {""+this.getNetworkID()};
    string hitterID = "" + hitterBlob.getNetworkID();
    string hitterPlayerID;

    if (hitterBlob.getDamageOwnerPlayer() !is null) {
        hitterPlayerID = "" + hitterBlob.getDamageOwnerPlayer().getNetworkID();
    }

    if (customData == Hitters::shield) {
        params.push_back(hitterID);
        triggerMatchEvent(MatchEventType::KNIGHT_SHIELD_BASH_HIT, params);
    }
    else if (damage > 0) {
        if (customData == Hitters::builder) {
            params.push_back(hitterID);
            triggerMatchEvent(MatchEventType::BUILDER_PICKAXE_HIT, params);
        }
        else if (customData == Hitters::arrow) {
            params.push_back(hitterPlayerID);
            triggerMatchEvent(MatchEventType::ARCHER_SHOT_HIT, params);
        }
        else if (customData == Hitters::stomp) {
            params.push_back(hitterID);
            triggerMatchEvent(MatchEventType::STOMP_HIT, params);
        }
        else if (customData == Hitters::bomb) {
            params.push_back(hitterPlayerID);
            triggerMatchEvent(MatchEventType::BOMB_HIT, params);
        }
        else if (customData == Hitters::spikes) {
            params.push_back(hitterPlayerID);
            triggerMatchEvent(MatchEventType::SPIKES_HIT, params);
        }
        else if (customData == Hitters::sword && hitterBlob.getName() == "knight") {
            params.push_back(hitterID);

            KnightInfo@ knight;

            if (damage == 1.0) {
                // Jab
                triggerMatchEvent(MatchEventType::KNIGHT_JAB_HIT, params);
            }
            else if (damage == 2.0) {
                if (hitterBlob.get("knightInfo", @knight)) {
                    if (knight.state == KnightStates::sword_power) {
                        triggerMatchEvent(MatchEventType::KNIGHT_SLASH_HIT, params);
                    }
                    else if (knight.state == KnightStates::sword_power_super) {
                        triggerMatchEvent(MatchEventType::KNIGHT_POWER_SLASH_HIT, params);
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
    string[] params = {""+this.getNetworkID()};
    triggerMatchEvent(MatchEventType::DEATH, params);
}

// Bomb stuff
void onAttach( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint ) {
    if (this.getName() == "bomb") {
        s32 bombTimer = this.get_s32("bomb_timer");
        bool justLit = bombTimer == getGameTime() + 120;

        log("onAttach", "bombTimer: " + bombTimer + ", justLit: " + justLit);

        string[] params = {""+attached.getNetworkID()};
        if (this.getDamageOwnerPlayer() !is null) {
            params.push_back(""+this.getDamageOwnerPlayer().getNetworkID());
        }

        if (justLit)
            triggerMatchEvent(MatchEventType::LIGHT_BOMB, params);
        else
            triggerMatchEvent(MatchEventType::CATCH_BOMB, params);
    }
}

void onDetach( CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint ) {
    if (this.getName() == "bomb") {
        string[] params = {""+detached.getNetworkID()};
        triggerMatchEvent(MatchEventType::THROW_BOMB, params);
    }
}

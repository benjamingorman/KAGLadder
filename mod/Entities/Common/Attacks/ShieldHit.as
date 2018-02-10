// Shield hit - make sure to set up the shield vars elsewhere

#include "ShieldCommon.as";

#include "ParticleSparks.as";

#include "Hitters.as";
#include "Logging.as";
#include "ELO_Common.as";
#include "ELO_Types.as";
#include "KnightCommon.as";

bool canBlockThisType(u8 type) // this function needs to use a tag on the hitterBlob, like ("bypass shield")
{
	return type == Hitters::stomp ||
	       type == Hitters::builder ||
	       type == Hitters::sword ||
	       type == Hitters::shield ||
	       type == Hitters::arrow ||
	       type == Hitters::bite ||
	       type == Hitters::stab ||
	       isExplosionHitter(type);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    //log("ShieldHit:onHit", ""+this.getNetworkID());
	if (this.hasTag("dead") ||
	        !this.hasTag("shielded") ||
	        !canBlockThisType(customData) ||
	        this is hitterBlob)
	{
		//print("dead " + this.hasTag("dead") + "shielded " + this.hasTag("shielded") + "cant " + canBlockThisType(customData));
		return damage;
	}

	//no shield when stunned
	if (this.get_u8("knocked") > 0)
	{
		return damage;
	}

	if (blockAttack(this, velocity, 0.0f))
	{
		if (isExplosionHitter(customData)) //bomb jump
		{
            CPlayer@ bombOwner = hitterBlob.getDamageOwnerPlayer();
            string[] params = {""+this.getNetworkID()};
            if (bombOwner !is null) {
                params.push_back(""+bombOwner.getNetworkID());
            }
            triggerMatchEvent(MatchEventType::KNIGHT_BLOCK_BOMB, params);

			Vec2f vel = this.getVelocity();
			this.setVelocity(Vec2f(0.0f, Maths::Min(0.0f, vel.y)));

			Vec2f bombforce = Vec2f(0.0f, ((velocity.y > 0) ? 0.7f : -1.3f));

			bombforce.Normalize();
			bombforce *= 2.0f * Maths::Sqrt(damage) * this.getMass();
			bombforce.y -= 2;

			if (!this.isOnGround() && !this.isOnLadder())
			{
				if (this.isFacingLeft() && vel.x > 0)
				{
					bombforce.x += 50;
					bombforce.y -= 80;
				}
				else if (!this.isFacingLeft() && vel.x < 0)
				{
					bombforce.x -= 50;
					bombforce.y -= 80;
				}
			}
			else if (this.isFacingLeft() && vel.x > 0)
			{
				bombforce.x += 5;
			}
			else if (!this.isFacingLeft() && vel.x < 0)
			{
				bombforce.x -= 5;
			}

			this.AddForce(bombforce);
			this.Tag("dont stop til ground");

		}
		else if (exceedsShieldBreakForce(this, damage) && customData != Hitters::arrow)
		{
			knockShieldDown(this);
			this.Tag("force_knock");
		}

        if (hitterBlob.getName() == "knight") {
            KnightInfo@ knight;
            string[] params = {""+this.getNetworkID(), ""+hitterBlob.getNetworkID()};
            if (damage == 1.0) {
                // Jab
                triggerMatchEvent(MatchEventType::KNIGHT_BLOCK_JAB, params);
            }
            else if (damage == 2.0) {
                if (hitterBlob.get("knightInfo", @knight)) {
                    if (knight.state == KnightStates::sword_power) {
                        triggerMatchEvent(MatchEventType::KNIGHT_BLOCK_SLASH, params);
                    }
                    else if (knight.state == KnightStates::sword_power_super) {
                        triggerMatchEvent(MatchEventType::KNIGHT_BLOCK_POWER_SLASH, params);
                    }
                }
                else {
                    log("onHit", "Couldn't get hitter knightInfo");
                }
            }
        }

		Sound::Play("Entities/Characters/Knight/ShieldHit.ogg", worldPoint);
		const f32 vellen = velocity.Length();
		sparks(worldPoint, -velocity.Angle(), Maths::Max(vellen * 0.05f, damage));
		return 0.0f;
	}

	return damage; //no block, damage goes through
}

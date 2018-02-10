const int REACTION_SPEED_TICKS = 6;

void onInit(CBlob@ this) {
}

void onTick(CBlob@ this) {
    //log("onTick");
    if (getGameTime() % REACTION_SPEED_TICKS != 0)
        return;
    if (this.getPlayer() !is null) {
        //log("Returning cause player");
        return;
    }
    CBlob@ knight = getNearbyKnight(this);
    if (knight !is null) {
        //log("knight is not null - aiming");
        this.setAimPos(knight.getPosition());
        this.setKeyPressed(key_action2, true);
    }
    else {
        //log("knight is null");
        this.setKeyPressed(key_action2, false);
    }
}

CBlob@ getNearbyKnight(CBlob@ this) {
    CBlob@[] nearbyBlobs;
    CBlob@[] knights;

    getMap().getBlobsInRadius(this.getPosition(), 
                              this.getRadius() + 80.0f,
                              nearbyBlobs);

    for (int i=0; i < nearbyBlobs.length; i++) {
        CBlob@ blob = nearbyBlobs[i];
        if (blob.getName() == "knight" &&
                !blob.hasTag("dead") &&
                blob.getTeamNum() != this.getTeamNum()) {
            // Find insert index (keep sorted by distance)
            int ix;
            for (ix=0; ix < knights.length; ix++) {
                if (blob.getDistanceTo(this) <
                        knights[ix].getDistanceTo(this))
                    break;
            }

            knights.insert(ix, blob);
        }
    }

    if (knights.length > 0) {
        //log("Found knights: " + knights.length);
        return knights[0];
    }

    return null;
}

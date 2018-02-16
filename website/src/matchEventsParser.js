const MatchEventType = {
    PLAYER_BLOB_SET: 0,
    KNIGHT_JAB_START: 1,
    KNIGHT_SLASH_START: 2,
    KNIGHT_POWER_SLASH_START: 3,
    KNIGHT_JAB_HIT: 4,
    KNIGHT_SLASH_HIT: 5,
    KNIGHT_POWER_SLASH_HIT: 6,
    KNIGHT_BLOCK_JAB: 7,
    KNIGHT_BLOCK_SLASH: 8,
    KNIGHT_BLOCK_POWER_SLASH: 9,
    KNIGHT_BLOCK_BOMB: 10,
    KNIGHT_SHIELD_BASH_HIT: 11,
    ARCHER_SHOT: 12,
    ARCHER_SHOT_HIT: 13,
    ARCHER_TRIPLE_SHOT: 14,
    BUILDER_PICKAXE_START: 15,
    BUILDER_DROP_SPIKES: 16,
    BUILDER_PICKAXE_HIT: 17,
    DEATH: 18,
    STOMP_HIT: 19,
    LIGHT_BOMB: 20,
    THROW_BOMB: 21,
    CATCH_BOMB: 22,
    BOMB_HIT: 23,
    SPIKES_HIT: 24,
    CRUSH_HIT: 25,
    FALL_HIT: 26,
    KNOCKED: 27
}

class MatchEvent {
    constructor(eventType, blobNetid, matchTime, params) {
        this.eventType = eventType;
        this.matchTime = matchTime;
        this.blobNetid = blobNetid;
        this.params = params;
    }

    loadFromString(eventStr) {
        let parts = eventStr.split(",");
        this.eventType = parseInt(parts[0], 10);
        this.matchTime = parseInt(parts[1], 10);
        this.blobNetid = parseInt(parts[2], 10);
        let params = [];
        for (let i=3; i < parts.length; ++i) {
            params.push(parts[i]);
        }
        this.params = params;
    }

    describeMatchTime() {
        // Format to 1 d.p.
        return (Math.round((this.matchTime / 30) * 10) / 10).toFixed(1);
    }

    describe(blobToUsernameMapping) {
        // Usually we should have a mapping for every player to the right blob, but if for some reason we don't
        // then fill in the names of players with "blob x"
        let translateBlob = function(blobID) {
            blobID = parseInt(blobID, 10);
            if (blobID in blobToUsernameMapping)
                return blobToUsernameMapping[blobID];
            else
                return "blob " + blobID;
        }

        let ident = translateBlob(this.blobNetid);
        // not every event has this but quite a few do, so it saves some repetition to get it here
        let otherIdent;
        if (this.params.length > 0) {
            otherIdent = translateBlob(this.params[0]);
        }
        let params = this.params;

        let result;
        switch(this.eventType) {
            case MatchEventType.PLAYER_BLOB_SET:
                result = `${ident} spawned.`;
                break;
            case MatchEventType.KNIGHT_JAB_START:
                result = `${ident} jabbed.`;
                break;
            case MatchEventType.KNIGHT_SLASH_START:
                result = `${ident} slashed.`;
                break;
            case MatchEventType.KNIGHT_POWER_SLASH_START:
                result = `${ident} power slashed.`;
                break;
            case MatchEventType.KNIGHT_JAB_HIT:
                result = `${ident} was hit by ${otherIdent}'s jab!`;
                break;
            case MatchEventType.KNIGHT_SLASH_HIT:
                result = `${ident} was hit by ${otherIdent}'s slash!`;
                break;
            case MatchEventType.KNIGHT_POWER_SLASH_HIT:
                result = `${ident} was hit by ${otherIdent}'s power slash!!`;
                break;
            case MatchEventType.KNIGHT_BLOCK_JAB:
                result = `${ident} blocked ${otherIdent}'s jab.`;
                break;
            case MatchEventType.KNIGHT_BLOCK_SLASH:
                result = `${ident} blocked ${otherIdent}'s slash.`;
                break;
            case MatchEventType.KNIGHT_BLOCK_POWER_SLASH:
                result = `${ident} blocked ${otherIdent}'s power slash.`;
                break;
            case MatchEventType.KNIGHT_BLOCK_BOMB:
                result = `${ident} blocked ${params[0]}'s bomb.`;
                break;
            case MatchEventType.KNIGHT_SHIELD_BASH_HIT:
                result = `${ident} was shield bashed by ${otherIdent}.`;
                break;
            case MatchEventType.ARCHER_SHOT:
                result = `${ident} fired an arrow with speed ${params[0]}.`;
                break;
            case MatchEventType.ARCHER_SHOT_HIT:
                result = `${ident} was hit by ${params[0]}'s arrow for ${params[1]} damage!`;
                break;
            case MatchEventType.ARCHER_TRIPLE_SHOT:
                result = `${ident} fired a triple shot!!`;
                break;
            case MatchEventType.BUILDER_PICKAXE_START:
                result = `${ident} swung his pickaxe.`;
                break;
            case MatchEventType.BUILDER_DROP_SPIKES:
                result = `${ident} dropped some spikes.`;
                break;
            case MatchEventType.BUILDER_PICKAXE_HIT:
                result = `${ident} was hit by ${otherIdent}'s pickaxe!`;
                break;
            case MatchEventType.DEATH:
                result = `${ident} died.`;
                break;
            case MatchEventType.STOMP_HIT:
                result = `${ident} was stomped by ${otherIdent} for ${params[1]} damage.`;
                break;
            case MatchEventType.LIGHT_BOMB:
                result = `${ident} lit his bomb.`;
                break;
            case MatchEventType.THROW_BOMB:
                result = `${ident} threw a bomb.`;
                break;
            case MatchEventType.CATCH_BOMB:
                result = `${ident} caught ${params[0]}'s bomb.`;
                break;
            case MatchEventType.BOMB_HIT:
                result = `${ident} was hit by ${params[0]}'s bomb for ${params[1]} damage.`;
                break;
            case MatchEventType.SPIKES_HIT:
                result = `${ident} was hit by ${params[0]}'s spikes for ${params[1]} damage.`;
                break;
            case MatchEventType.CRUSH_HIT:
                result = `${ident} was crushed for ${params[0]} damage.`;
                break;
            case MatchEventType.FALL_HIT:
                result = `${ident} fell, taking ${params[0]} damage.`;
                break;
            case MatchEventType.KNOCKED:
                result = `${ident} was stunned for ${params[0]} ticks`;
                break;
            default:
                result = `Unrecognized event`;
        }
        return result;
    }
}

class MatchEventsParser {
    constructor(eventsData) {
        this.events = [];
        this.blobToUsernameMapping = {};

        let eventsStrings = eventsData.split(";");
        for (let i=0; i < eventsStrings.length; ++i) {
            let eventStr = eventsStrings[i];
            if (eventStr.trim().length === 0) // avoid empty/junk strings
                continue;

            let evt = new MatchEvent();
            evt.loadFromString(eventStr);
            this.events.push(evt);

            if (evt.eventType === MatchEventType.PLAYER_BLOB_SET) {
                this.blobToUsernameMapping[evt.blobNetid] = evt.params[0];
            }
        }
        //console.log("this.events", this.events) ;
    }

    describe(index) {
        let evt = this.events[index];
        return [evt.describeMatchTime(), evt.describe(this.blobToUsernameMapping)];
    }
}

export default MatchEventsParser;

#include "Logging.as"
#include "ELO_Common.as"


const int DEFAULT_ELO = 1000;
const int MIN_ELO = 0;
const float ELO_BASE = 5;
const float ELO_SCALING = 200.0; // how quickly ratings adjust after matches
const float ELO_DIVISOR = 1400.0; // reflects how likely a higher rated player is to beat a lower one
string[] RECENTLY_JOINED_PLAYERS; // save each player when they join in onNewPlayerJoin so that stuff can be synced to them in onTick
uint RECENT_PLAYER_JOIN_TIME = 0; // the game time at which the recent player joined (make sure to wait a bit before trying to sync)


void onInit(CRules@ this) {
    ConfigFile cfg();
    bool check = cfg.loadFile("../Cache/"+ELO_TABLE_CFG);
    if (!check) {
        log("onInit", "Elo table doesn't exist so creating it");
        cfg.saveFile(ELO_TABLE_CFG);
    }

    if (getNet().isClient()) {
        prepareForSyncELO(this);
    }
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player) {
    log("onNewPlayerJoin", "Called");

    if (getNet().isServer()) {
        cachePlayerELO(this, player);
        RECENTLY_JOINED_PLAYERS.push_back(player.getUsername());
        RECENT_PLAYER_JOIN_TIME = getGameTime();
    }
}

void onTick(CRules@ this) {
    if (getGameTime() % 200 == 0 && getGameTime() - RECENT_PLAYER_JOIN_TIME > 10) {
        for (int i=0; i < RECENTLY_JOINED_PLAYERS.length(); ++i) {
            CPlayer@ player = getPlayerByUsername(RECENTLY_JOINED_PLAYERS[i]);

            if (player !is null) {
                syncELOToPlayer(this, player);
            }
        }

        RECENTLY_JOINED_PLAYERS.clear();
    }
}

void onStateChange(CRules@ this, const u8 oldState) {
    if (getNet().isClient() && this.getCurrentState() == GAME_OVER) {
        // When onRestart comes syncELO will be called
        prepareForSyncELO(this);
    }
}

void onRestart(CRules@ this) {
    if (getNet().isServer()) {
        log("onRestart", "Called");

        for (int i=0; i < getPlayerCount(); ++i) {
            syncELOToPlayer(this, getPlayer(i));
        }
    }
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params) {
    if (cmd == this.getCommandID("ON_END_DUEL")) {
        log("onCommand", "Got ON_END_DUEL cmd"); 
        Duel currentDuel;
        this.get("CURRENT_DUEL", currentDuel);
        updateELOAfterDuel(currentDuel);
    }
}

// Reads the player's ELO from the cfg if it exists
// Sets values in rules
void cachePlayerELO(CRules@ this, CPlayer@ player) {
    log("cachePlayerELO", "Called for " + player.getUsername());
    ConfigFile cfg();
    bool check = cfg.loadFile("../Cache/"+ELO_TABLE_CFG);
    if (!check) {
        log("cachePlayerELO", "Couldn't load " + ELO_TABLE_CFG);
        return;
    }

    for (int i=0; i < ALL_CLASSES.length; ++i) {
        string cls = ALL_CLASSES[i];
        string playerNameWithClass = player.getUsername() + "-" + cls;

        if (cfg.exists(playerNameWithClass)) {
            s16 elo = cfg.read_s16(playerNameWithClass);
            this.set_s16(playerNameWithClass, elo);
        }
        else {
            this.set_s16(playerNameWithClass, DEFAULT_ELO);
        }
    }
}

// This is only called client side
// It's used to set up certain rules properties ready for Syncs
// Because the properties need to exist before the Sync is called
void prepareForSyncELO(CRules@ this) {
    log("prepareForSyncELO", "Called");
    for (int i=0; i < getPlayerCount(); ++i) {
        CPlayer@ p = getPlayer(i);

        for (int j=0; j < ALL_CLASSES.length; ++j) {
            string cls = ALL_CLASSES[j];

            string playerNameWithClass = p.getUsername() + "-" + cls;
            if (!this.exists(playerNameWithClass)) {
                this.set_s16(playerNameWithClass, 0);
            }
        }
    }
}

void syncELOToPlayer(CRules@ this, CPlayer@ player) {
    log("syncELOToPlayer", "Called");

    for (int i=0; i < getPlayerCount(); ++i) {
        CPlayer@ p = getPlayer(i);

        for (int j=0; j < ALL_CLASSES.length; ++j) {
            string cls = ALL_CLASSES[j];
            string playerNameWithClass = p.getUsername() + "-" + cls;
            //log("syncELO", "Syncing " + playerNameWithClass);
            if (!this.exists(playerNameWithClass)) {
                log("syncELOToPlayer", "ERROR doesn't exist: " + playerNameWithClass);
            }
            else {
                this.SyncToPlayer(playerNameWithClass, player);
            }
        }
    }
}

void setELO(string playerUsername, string whichClass, s16 elo) {
    log("setELO", "Called for " + playerUsername + "-" + whichClass + ": " + elo);
    // Update the cache
    string playerNameWithClass = playerUsername + "-" + whichClass;
    getRules().set_s16(playerNameWithClass, elo);

    // Update the cfg
    ConfigFile cfg();
    bool check = cfg.loadFile("../Cache/"+ELO_TABLE_CFG);
    if (!check) {
        log("updateELO", "Couldn't load " + ELO_TABLE_CFG);
        return;
    }
    cfg.add_s16(playerNameWithClass, elo);
    cfg.saveFile(ELO_TABLE_CFG);
}

void updateELOAfterDuel(Duel duel) {
    log("updateELOAfterDuel", "Called");
    s16 oldChallengerELO = getELO(duel.challengerUsername, duel.whichClass);
    s16 oldChallengedELO = getELO(duel.challengedUsername, duel.whichClass);

    // TODO: Currently score isn't just a binary win/loss but is affected by win rate. Maybe change this?
    // These score values refer to the score of the challenger
    int eloDelta = oldChallengedELO - oldChallengerELO;
    float score = duel.scoreChallenger / float(duel.scoreChallenger + duel.scoreChallenged);
    float expectedScore = 1.0 / (1.0 + Maths::Pow(ELO_BASE, eloDelta/ELO_DIVISOR));

    // When a player goes up D the opponent goes up -D
    s16 challengerGain = ELO_SCALING * (score - expectedScore);
    if (challengerGain < 0 && duel.scoreChallenger > duel.scoreChallenged ||
        challengerGain > 0 && duel.scoreChallenger < duel.scoreChallenged) {
        // Prevent losing points for a win
        challengerGain = 0;
    }
    s16 challengedGain = -challengerGain;
    s16 newChallengerELO = oldChallengerELO + challengerGain;
    s16 newChallengedELO = oldChallengedELO + challengedGain;
    broadcast("ELO change: " + duel.challengerUsername + " " + challengerGain + ", " + duel.challengedUsername + " " + challengedGain);

    setELO(duel.challengerUsername, duel.whichClass, newChallengerELO);
    setELO(duel.challengedUsername, duel.whichClass, newChallengedELO);
}
#include "Logging.as";
#include "ELO_Common.as";
#include "ELO_Types.as";

void onInit(CRules@ this) {
    runTests();
}

void onReload(CRules@ this) {
    runTests();
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player) {
    whisper(player, "THIS IS A TEST MESSAGE");
    log("ELO_Main", "rating knight: " + getPlayerRating(player.getUsername(), "knight"));
    log("ELO_Main", "rating archer: " + getPlayerRating(player.getUsername(), "knight"));
    log("ELO_Main", "rating builder: " + getPlayerRating(player.getUsername(), "knight"));
    log("ELO_Main", "rating title: " + getPlayerRatingTitle(player.getUsername()));
}

void runTests() {
    test_RatedChallenge();
    log("ELO_Main", "test finished test_RatedChallenge");
}

void test_RatedChallenge() {
    RatedChallenge chal("bob", "sam", "knight", 5);
    string ser = chal.serialize();
    log("ELO_Main", ser);
    RatedChallenge chal2();
    chal2.deserialize(ser);
    if (chal.challenger != chal2.challenger) {
        log("ELO_Main", "test failed: challenger");
    }
    if (chal.challenger != chal2.challenger) {
        log("ELO_Main", "test failed: challenger");
    }
    if (chal.challenged != chal2.challenged) {
        log("ELO_Main", "test failed: challenged");
    }
    if (chal.kagClass != chal2.kagClass) {
        log("ELO_Main", "test failed: kagClass");
    }
    if (chal.duelToScore != chal2.duelToScore) {
        log("ELO_Main", "test failed: duelToScore");
    }
    if (chal.createdAt != chal2.createdAt) {
        log("ELO_Main", "test failed: createdAt");
    }
}

RatedMatch getTestMatch() {
    RatedMatch testMatch;
    testMatch.player1 = "Alice";
    testMatch.player2 = "Bob";
    testMatch.kagClass = "knight";
    testMatch.duelToScore = 5;
    testMatch.player1Score = 5;
    testMatch.player2Score = 1;
    testMatch.startTime = Time();
    return testMatch;
}

void debugHeads() {
    CPlayer@ eluded = getPlayerByUsername("Eluded");
    if (eluded !is null) {
        log("onTick", "Eluded head: " + eluded.getHead());
        log("onTick", "Eluded sex: " + eluded.getSex());
        log("onTick", "Eluded nick: " + eluded.getCharacterName());
    }
}


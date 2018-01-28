#include "Logging.as";
#include "ELO_Common.as";

const SColor TEAM0COLOR(255,25,94,157);
const SColor TEAM1COLOR(255,192,36,36);
const u8 BIG_SCORE_FONT_SIZE = 30;
string SERIALIZED_CHALLENGE_QUEUE = ""; // the client keeps a copy of this so that when it changes we can detect it easily
RatedChallenge[] CHALLENGE_QUEUE;

void onInit(CRules@ this) {
    if (!GUI::isFontLoaded("big score font"))
        GUI::LoadFont("big score font", "GUI/Fonts/AveriaSerif-Bold.ttf", BIG_SCORE_FONT_SIZE, true);
}

void onRender(CRules@ this) {
    GUI::DrawText("test", Vec2f(100,100), SColor(255,25,94,157));

    if (isRatedMatchInProgress()) {
        renderScore();
    }

    if (this.get_string("VAR_SERIALIZED_CHALLENGE_QUEUE") != SERIALIZED_CHALLENGE_QUEUE) {
        SERIALIZED_CHALLENGE_QUEUE = this.get_string("VAR_SERIALIZED_CHALLENGE_QUEUE");
        deserializeChallengeQueue();
    }
    renderChallengeQueue();
}

void deserializeChallengeQueue() {
    CHALLENGE_QUEUE.clear();
    XMLParser parser(SERIALIZED_CHALLENGE_QUEUE);
    XMLDocument@ doc = parser.parse();

    if (doc.root.name != "challengequeue") {
        log("ELO_Interface:deserializeChallengeQueue", "ERROR xml doesn't start with challengequeue");
        return;
    }

    for (int i=0; i < doc.root.children.length; ++i) {
        RatedChallenge chal;
        bool check = chal.deserialize(doc.root.children[i]);
        if (!check) {
            log("ELO_Interface:deserializeChallengeQueue", "ERROR couldn't deserialize challenge");
            return;
        }

        CHALLENGE_QUEUE.push_back(chal);
    }
}

string getIconNameFromClass(string whichClass) {
    if (whichClass == "archer") {
        return "$ARCHER$";
    }
    else if (whichClass == "builder") {
        return "$BUILDER$";
    }
    else {
        return "$KNIGHT$";
    }
}

// Shortens a string, ending it with ...
string shortenString(string original, int maxLength) {
    if (original.length <= maxLength) {
        return original;
    }
    else {
        string keep = original.substr(0, maxLength-3);
        return keep + "...";
    }
}

void renderChallengeQueue() {
    Vec2f titlePaneDims(160, 22);
    Vec2f paneDims(160, 38);
    Vec2f topLeft(10,10);
    Vec2f textPadding(3,3);
    Vec2f iconPadding(4, 0);
    SColor paneColor(125,126,140,121);
    int maxChallenges = 12;
    int maxNameWidth = 90;
    int maxNameChars = 13;
    int nameHeight = 14;
    int classIconWidth = 30;

    GUI::SetFont("menu");
    GUI::DrawPane(topLeft, topLeft+titlePaneDims, paneColor);
    GUI::DrawText("CHALLENGE QUEUE", topLeft+textPadding, color_white);

    for (int i=0; i < CHALLENGE_QUEUE.length; ++i) {
        topLeft = Vec2f(10, 10 + titlePaneDims.y + i*paneDims.y);
        if (i == maxChallenges) {
            GUI::DrawPane(topLeft, topLeft+titlePaneDims, paneColor);
            GUI::DrawText((CHALLENGE_QUEUE.length - maxChallenges) + " more...", topLeft+textPadding, color_white);
            break;
        }

        RatedChallenge chal = CHALLENGE_QUEUE[i];
        string iconName = getIconNameFromClass(chal.kagClass);

        GUI::DrawPane(topLeft, topLeft+paneDims, paneColor);
        GUI::DrawText(shortenString(chal.challenger, maxNameChars), topLeft+textPadding, color_white);
        GUI::DrawText(shortenString(chal.challenged, maxNameChars), topLeft+textPadding+Vec2f(0,nameHeight), color_white);
        GUI::DrawIconByName(iconName, topLeft+iconPadding+Vec2f(maxNameWidth,0));
        GUI::DrawText("to " + chal.duelToScore, topLeft+textPadding+Vec2f(maxNameWidth+classIconWidth,8), color_white);
    }
}

void renderScore() {
    GUI::SetFont("big score font");
    GUI::DrawText("TODO: Score", Vec2f(600, 600), TEAM0COLOR);

    /*
    Duel currentDuel;
    this.get("CURRENT_DUEL", currentDuel);

    u8 team0Score = this.get_u8("CURRENT_DUEL_SCORE_0");
    u8 team1Score = this.get_u8("CURRENT_DUEL_SCORE_1");
    u8 duelToScore = this.get_u8("CURRENT_DUEL_TO_SCORE");

    //log("onRender", "" + team0Score + ", " + team1Score);
    Vec2f team0ScoreDims;
    Vec2f team1ScoreDims;
    Vec2f scoreSeperatorDims;
    GUI::GetTextDimensions("" + team0Score, team0ScoreDims);
    GUI::GetTextDimensions("" + team1Score, team1ScoreDims);
    GUI::GetTextDimensions("-", scoreSeperatorDims);

    Vec2f scoreDisplayCentre(getScreenWidth()/2, getScreenHeight() / 5.0);
    int scoreSpacing = 24;

    Vec2f topLeft0(
            scoreDisplayCentre.x - scoreSpacing - team0ScoreDims.x,
            scoreDisplayCentre.y);
    Vec2f topLeft1(
            scoreDisplayCentre.x + scoreSpacing,
            scoreDisplayCentre.y);
    GUI::DrawText("" + team0Score, topLeft0, TEAM0COLOR);
    GUI::DrawText("-", Vec2f(scoreDisplayCentre.x - scoreSeperatorDims.x/2.0, scoreDisplayCentre.y), color_black);
    GUI::DrawText("" + team1Score, topLeft1, TEAM1COLOR);
    drawRulesFont("First to " + duelToScore, color_white, Vec2f(20, 160), Vec2f(getScreenWidth() - 20, 200), true, false);
    */
}


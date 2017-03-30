#include "Logging.as"
#include "ELO_Common.as"

const SColor TEAM0COLOR(255,25,94,157);
const SColor TEAM1COLOR(255,192,36,36);
const u8 BIG_SCORE_FONT_SIZE = 30;
const u8 LITTLE_SCORE_FONT_SIZE = 18;
string SERIALIZED_DUEL_QUEUE = "";
Duel[] DUEL_QUEUE;


void onInit(CRules@ this) {
    if (!GUI::isFontLoaded("big score font"))
        GUI::LoadFont("big score font", "GUI/Fonts/AveriaSerif-Bold.ttf", BIG_SCORE_FONT_SIZE, true);
    if (!GUI::isFontLoaded("little score font"))
        GUI::LoadFont("little score font", "GUI/Fonts/AveriaSerif-Bold.ttf", LITTLE_SCORE_FONT_SIZE, true);
}

void onRender(CRules@ this) {
    u8 duelState = this.get_u8("CURRENT_DUEL_STATE");

    if (duelState == DuelState::ACTIVE_DUEL) {
        renderScore(this);
    }

    if (this.get_string("SERIALIZED_DUEL_QUEUE") != SERIALIZED_DUEL_QUEUE) {
        SERIALIZED_DUEL_QUEUE = this.get_string("SERIALIZED_DUEL_QUEUE");
        deserializeDuelQueue(SERIALIZED_DUEL_QUEUE);
    }
    renderDuelQueue(this);
    renderHelpText();
}

void renderScore(CRules@ this) {
    GUI::SetFont("big score font");

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
}

void renderDuelQueue(CRules@ this) {
    //log("renderDuelQueue", "Called");
    Vec2f titlePaneDims(160, 22);
    Vec2f paneDims(160, 38);
    Vec2f topLeft(10,10);
    Vec2f textPadding(3,3);
    Vec2f iconPadding(4, 0);
    SColor paneColor(125,126,140,121);
    int maxDuelsToShow = 12;
    int maxNameWidth = 90;
    int maxNameChars = 13;
    int nameHeight = 14;
    int classIconWidth = 30;
    GUI::SetFont("menu");
    GUI::DrawPane(topLeft, topLeft+titlePaneDims, paneColor);
    GUI::DrawText("DUEL QUEUE", topLeft+textPadding, color_white);

    for (int i=0; i < DUEL_QUEUE.length; ++i) {
        topLeft = Vec2f(10, 10 + titlePaneDims.y + i*paneDims.y);
        if (i == maxDuelsToShow) {
            GUI::DrawPane(topLeft, topLeft+titlePaneDims, paneColor);
            GUI::DrawText((DUEL_QUEUE.length - maxDuelsToShow) + " more...", topLeft+textPadding, color_white);
            break;
        }

        Duel duel = DUEL_QUEUE[i];
        string iconName = getIconNameFromClass(duel.whichClass);

        GUI::DrawPane(topLeft, topLeft+paneDims, paneColor);
        GUI::DrawText(shortenString(duel.challengerUsername, maxNameChars), topLeft+textPadding, color_white);
        GUI::DrawText(shortenString(duel.challengedUsername, maxNameChars), topLeft+textPadding+Vec2f(0,nameHeight), color_white);
        GUI::DrawIconByName(iconName, topLeft+iconPadding+Vec2f(maxNameWidth,0));
        GUI::DrawText("to " + duel.duelToScore, topLeft+textPadding+Vec2f(maxNameWidth+classIconWidth,8), color_white);
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

void deserializeDuelQueue(string ser) {
    DUEL_QUEUE.clear();
    XMLParser parser(ser);
    XMLDocument@ doc = parser.parse();

    if (doc.root.name != "duelqueue") {
        log("renderDuelQueue", "ERROR xml doesn't start with duelqueue");
        return;
    }

    for (int i=0; i < doc.root.children.length; ++i) {
        Duel duel;
        bool check = duel.deserialize(doc.root.children[i]);
        if (!check) {
            log("deserializeDuelQueue", "ERROR couldn't deserialize duel");
            return;
        }

        DUEL_QUEUE.push_back(duel);
    }
}

void renderHelpText() {
    GUI::SetFont("menu");
    Vec2f topLeft(10, 760);
    Vec2f paneDims(280, 68);
    Vec2f textPadding(3,3);
    Vec2f lineSpacing(0, 14);
    SColor paneColor(125,126,140,121);

    GUI::DrawPane(topLeft, topLeft+paneDims, paneColor);
    GUI::DrawText("Welcome to Rated 1v1", topLeft+textPadding, color_white);
    GUI::DrawText("Leaderboards are on the KAG forums", topLeft+textPadding+lineSpacing, color_white);
    GUI::DrawText("in the contests section.", topLeft+textPadding+lineSpacing*2, color_white);
    GUI::DrawText("Type !help for available commands", topLeft+textPadding+lineSpacing*3, color_white);
}
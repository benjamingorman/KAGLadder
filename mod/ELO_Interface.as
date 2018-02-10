#define CLIENT_ONLY
#include "Logging.as";
#include "ELO_Common.as";
#include "ELO_Types.as";
#include "Logging.as";

const SColor TEAM0COLOR(255,25,94,157);
const SColor TEAM1COLOR(255,192,36,36);
const u8 BIG_SCORE_FONT_SIZE = 30;
RatedChallenge[] CHALLENGE_QUEUE;
RatedMatch CURRENT_MATCH;

void onInit(CRules@ this) {
    if (!GUI::isFontLoaded("big score font"))
        GUI::LoadFont("big score font", "GUI/Fonts/AveriaSerif-Bold.ttf", BIG_SCORE_FONT_SIZE, true);
    AddIconToken("$LOCK$", "InteractionIcons.png", Vec2f(32,32), 2);
}

void onReload(CRules@ this) {
    log("onReload", "called");
}

// Not using regular .Sync because it can't sync dictionary objects
// In order to render efficiently we don't want to have deserialize every frame
void onCommand(CRules@ this, u8 cmd, CBitStream@ params) {
    if (getNet().isServer())
        return;

    if (cmd == this.getCommandID("CMD_SYNC_CHALLENGE_QUEUE")) {
        log("onCommand", "Got CMD_SYNC_CHALLENGE_QUEUE");
        string ser;
        if (params.saferead_string(ser)) {
            deserializeChallengeQueue(ser);
        }
        else {
            log("onCommand", "ERROR malformed params");
        }
    }
    else if (cmd == this.getCommandID("CMD_SYNC_CURRENT_MATCH")) {
        log("onCommand", "Got CMD_SYNC_CURRENT_MATCH");
        string ser;
        if (params.saferead_string(ser)) {
            deserializeCurrentMatch(ser);
        }
        else {
            log("onCommand", "ERROR malformed params");
        }
    }
    else if (cmd == this.getCommandID("CMD_SYNC_PLAYER_RATINGS")) {
        log("onCommand", "Got CMD_SYNC_PLAYER_RATINGS");
        string ser;
        if (params.saferead_string(ser)) {
            deserializePlayerRatings(ser);
        }
        else {
            log("onCommand", "ERROR malformed params");
        }
    }
    else if (cmd == this.getCommandID("CMD_SYNC_QUEUE_WAIT_UNTIL")) {
        maybePlayQueueAlertSound();
    }
}

void onRender(CRules@ this) {
    if (isRatedMatchInProgress()) {
        renderScore();
    }
    renderChallengeQueue();
}

void onTick(CRules@ this) {
    /*
    if (getGameTime() % 60 == 0) {
        log("onTick", "Match in progress: " + isRatedMatchInProgress());
    }
    */
}

void maybePlayQueueAlertSound() {
    if (CHALLENGE_QUEUE.length > 0 && getLocalPlayer() !is null) {
        string localName = getLocalPlayer().getUsername();
        RatedChallenge chal0 = CHALLENGE_QUEUE[0];

        if (localName == chal0.challenger || localName == chal0.challenged)
            Sound::Play("QueueAlert.ogg");
    }
}

void deserializeChallengeQueue(string serialized) {
    CHALLENGE_QUEUE.clear();
    XMLParser parser(serialized);
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

void deserializeCurrentMatch(string serialized) {
    //log("deserializeCurrentMatch", "Called. " + serialized);
    CURRENT_MATCH.deserialize(serialized);
}

void deserializePlayerRatings(string serialized) {
    log("deserializePlayerRatings", "Called: (" + serialized + ")");
    PlayerRatings pr();

    if (pr.deserialize(serialized)) {
        getRules().set(getPlayerRatingsRulesProp(pr.username), pr);
    }
    else {
        log("deserializePlayerRatings", "ERROR could not deserialize");
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
    SColor highlightedPaneColor(200,255,255,0);
    SColor queueWaitingPaneColor(255,255,255,0);
    int maxChallenges = 12;
    int maxNameWidth = 90;
    int maxNameChars = 13;
    int nameHeight = 14;
    int classIconWidth = 30;

    GUI::SetFont("menu");
    GUI::DrawPane(topLeft, topLeft+titlePaneDims, paneColor);
    GUI::DrawText("CHALLENGE QUEUE", topLeft+textPadding, color_white);

    if (isQueueSystemWaiting()) {
        Vec2f lockTextPos = Vec2f(10 + paneDims.x + 10, 10 + titlePaneDims.y + paneDims.y/2 - 8);
        GUI::DrawIconByName("$LOCK$", lockTextPos - Vec2f(22,22));
        GUI::DrawText(getQueueSystemWaitSecondsLeft() + " seconds", lockTextPos + Vec2f(22, 0), color_white);
    }

    for (int i=0; i < CHALLENGE_QUEUE.length; ++i) {
        topLeft = Vec2f(10, 10 + titlePaneDims.y + i*paneDims.y);
        if (i == maxChallenges) {
            GUI::DrawPane(topLeft, topLeft+titlePaneDims, paneColor);
            GUI::DrawText((CHALLENGE_QUEUE.length - maxChallenges) + " more...", topLeft+textPadding, color_white);
            break;
        }

        RatedChallenge chal = CHALLENGE_QUEUE[i];
        string iconName = getIconNameFromClass(chal.kagClass);

        // Highlight challenges involving the local player
        SColor paneColorToUse = paneColor;
        if (getLocalPlayer() !is null) {
            if (chal.challenger == getLocalPlayer().getUsername() || chal.challenged == getLocalPlayer().getUsername())
                paneColorToUse = highlightedPaneColor;
            else {
                string txt = "(" + getLocalPlayer().getUsername() + " " + chal.challenger + " " + chal.challenged + ")";
                GUI::DrawText(txt, Vec2f(300, 300), color_white);
            }
        }

        if (i == 0 && isQueueSystemWaiting()) {
            paneColorToUse = queueWaitingPaneColor;
        }

        GUI::DrawPane(topLeft, topLeft+paneDims, paneColorToUse);
        GUI::DrawText(shortenString(chal.challenger, maxNameChars), topLeft+textPadding, color_white);
        GUI::DrawText(shortenString(chal.challenged, maxNameChars), topLeft+textPadding+Vec2f(0,nameHeight), color_white);
        GUI::DrawIconByName(iconName, topLeft+iconPadding+Vec2f(maxNameWidth,0));
        GUI::DrawText("to " + chal.duelToScore, topLeft+textPadding+Vec2f(maxNameWidth+classIconWidth,8), color_white);
    }
}

void renderScore() {
    GUI::SetFont("big score font");

    u8 team0Score = CURRENT_MATCH.player1Score;
    u8 team1Score = CURRENT_MATCH.player2Score;
    u8 duelToScore = CURRENT_MATCH.duelToScore;

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

/*
void onClickHelpCloseButton(string id) {
    log("onClickHelpCloseButton", "Called.");
}

void TestLeafWidgets() {
    log("CreateLeafWidgets", "Adding widget");
    Leaf::addWidget(@UI_STATE, Leaf::Button("help_close_button", Vec2f(100, 200), Vec2f(300, 300)));
    log("CreateLeafWidgets", "Adding widget");
    Leaf::addWidget(@UI_STATE, Leaf::Pane("basic_pane", Vec2f(200, 200), Vec2f(300, 500), Leaf::BasicPane));
    log("CreateLeafWidgets", "Adding widget");
    Leaf::addWidget(@UI_STATE, Leaf::Pane("sunken_pane", Vec2f(200, 200), Vec2f(600, 500), Leaf::SunkenPane));
    log("CreateLeafWidgets", "Adding widget");
    Leaf::addWidget(@UI_STATE, Leaf::Pane("window_pane", Vec2f(200, 200), Vec2f(900, 500), Leaf::WindowPane));
    log("CreateLeafWidgets", "Adding widget");
    Leaf::addWidget(@UI_STATE, Leaf::Pane("framed_pane", Vec2f(200, 200), Vec2f(1200, 500), Leaf::FramedPane));
    log("CreateLeafWidgets", "Adding widget");
    Leaf::addWidget(@UI_STATE, Leaf::Pane("rect_pane", Vec2f(200, 200), Vec2f(300, 800), Leaf::RectPane));
}

void CreateELOWidgets() {
    Vec2f screen_center = Leaf::getScreenCenter();

    Leaf::Pane help_pane("help_pane", Vec2f(200, 200), screen_center, Leaf::WindowPane);
    help_pane.offsetCenter();

    Leaf::Button help_pane_close_btn("help_pane_close_btn", Vec2f(100, 50), screen_center);
    Leaf::Text help_pane_close_btn_text("help_pane_close_btn_text", help_pane_close_btn.size, help_pane_close_btn.position, "Close");
    help_pane_close_btn.addChild(@help_pane_close_btn_text);

    help_pane.addChild(@help_pane_close_btn);

    Leaf::addWidget(@UI_STATE, @help_pane);
}
*/

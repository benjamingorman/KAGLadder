#include "Logging.as"
#include "ELO_Common.as"

const SColor TEAM0COLOR(255,25,94,157);
const SColor TEAM1COLOR(255,192,36,36);
const u8 FONT_SIZE = 30;


void onInit(CRules@ this) {
    if (!GUI::isFontLoaded("big score font"))
        GUI::LoadFont("big score font", "GUI/Fonts/AveriaSerif-Bold.ttf", FONT_SIZE, true);
}

void onRender(CRules@ this) {
    GUI::SetFont("big score font");
    u8 duelState = this.get_u8("CURRENT_DUEL_STATE");

    if (duelState != DuelState::ACTIVE_DUEL) return;

    Duel currentDuel;
    this.get("CURRENT_DUEL", currentDuel);

    u8 team0Score = this.get_u8("CURRENT_DUEL_SCORE_0");
    u8 team1Score = this.get_u8("CURRENT_DUEL_SCORE_1");

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
}
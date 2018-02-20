#define CLIENT_ONLY
#include "Logging.as"
#include "KL_Common.as"

bool SHOULD_DRAW = true;
Button[] BUTTONS;
int TITLE_FONT_SIZE = 20;
int SUBTITLE_FONT_SIZE = 18;

class Button {
    string id;
    string text;
    Vec2f upperleft, lowerright;
    Vec2f center;

    Button(string btn_id, string text_to_draw, Vec2f size, Vec2f pos) {
        id = btn_id;
        text = text_to_draw;
        pos.x -= size.x / 2;
        upperleft = pos;
        lowerright = pos + size;
        center = Vec2f(pos.x + size.x / 2, pos.y + size.y / 2);
    }

    bool isHovered() {
        Vec2f cursor_pos = getControls().getMouseScreenPos();
        return (cursor_pos.x > upperleft.x && cursor_pos.x < lowerright.x &&
                cursor_pos.y > upperleft.y && cursor_pos.y < lowerright.y);
    }

    bool isPressed() {
        return getControls().mousePressed1 && isHovered();
    }

    void render() {
        if (isPressed()) {
            GUI::DrawButtonPressed(upperleft, lowerright);
        }
        else if (isHovered()) {
            GUI::DrawButtonHover(upperleft, lowerright);
        }
        else {
            GUI::DrawButton(upperleft, lowerright);
        }

        GUI::DrawTextCentered(text, center, SColor(255,255,255,255));
    }
}

void CreateButtons() {
    BUTTONS.clear();
    Vec2f screen_dim = getDriver().getScreenDimensions();
    Vec2f center = screen_dim / 2;
    BUTTONS.push_back(Button("website-link", "Website", Vec2f(120, 30), center + Vec2f(-80, 206)));
    BUTTONS.push_back(Button("close", "Close", Vec2f(120, 30), center + Vec2f(80, 206)));
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params) {
    if (getNet().isServer())
        return;

    if (cmd == this.getCommandID("CMD_TOGGLE_HELP")) {
        SHOULD_DRAW = !SHOULD_DRAW;
    }
}

void onTick(CRules@ this) {
    if (!SHOULD_DRAW) return;

    if (BUTTONS.length == 0) {
        // Sometimes the buttons just go away for some reason
        CreateButtons();
    }

    string pressed_btn_id = getPressedButtonId();
    if (pressed_btn_id == "website-link") {
        OpenWebsite("https://kagladder.com");
    }
    else if (pressed_btn_id == "close") {
        SHOULD_DRAW = false;
    }
}

void onRender(CRules@ this) {
    if (!SHOULD_DRAW) return;
    
    Vec2f screen_dim = getDriver().getScreenDimensions();
    Vec2f center = screen_dim / 2;
    Vec2f paneDims(360, 500);
    Vec2f topLeft = center - paneDims/2;
    Vec2f topRight = center + Vec2f(paneDims.x, - paneDims.y)/2;
    Vec2f botLeft = center - Vec2f(paneDims.x, - paneDims.y)/2;
    Vec2f botRight = center + paneDims/2;
    int padding = 12;
    int titleHeight = 26;
    int buttonRowHeight = 20;
    SColor commandsColor(255,0,0,255);
    SColor commandsExampleColor(255,0,0,255);

    string[] commands = {
        "!help",
        "!challenge",
        "!accept",
        "!reject",
        "!ratings",
        "!cancelmatch",
        "!cancelchallenge",
        "!coins",
        "!bet"
        };

    string[] commandsHelp = {
        "Toggle this window",
        "Challenge someone",
        "Accept someone's challenge",
        "Reject someone's challenge",
        "Request your ratings",
        "Cancel the current match",
        "Cancel your challenge",
        "Display your coins",
        "Bet on someone"
        };

    string[][] commandsExamples = {
        {},
        {"!challenge Eluded", "!challenge Eluded archer 3", "!chal all"},
        {"!accept Eluded"},
        {"!reject Eluded"},
        {},
        {},
        {"!cancelchallenge Eluded"},
        {},
        {"!bet Eluded 100"}
    };

    GUI::DrawWindow(topLeft, botRight);
    if (!GUI::isFontLoaded("kagladder_title_font"))
        GUI::LoadFont("kagladder_title_font", "GUI/Fonts/AveriaSerif-Bold.ttf", TITLE_FONT_SIZE, true);
    GUI::SetFont("kagladder_title_font");
    GUI::DrawTextCentered("KAGLadder", center - Vec2f(0, paneDims.y/2 - padding - 14), color_white);

    string iconFile = "playercardicons.png";
    Vec2f iconSize(16,16);
    for (int icon=0; icon <= 2; ++icon) {
        GUI::DrawIcon(iconFile, 2-icon, iconSize, topLeft + Vec2f(padding + (iconSize.x+8)*icon, padding), 1.0, 1.0, color_white);
        GUI::DrawIcon(iconFile, 2-icon, iconSize, topRight + Vec2f(-padding - (iconSize.x+8)*icon, padding), -1.0, 1.0, color_white);
    }

    GUI::SetFont("menu");
    string intro = "Fight rated 1v1 matches with any class! All matches and rankings are recorded online.";
    GUI::DrawText(
        intro,
        topLeft + Vec2f(padding, 2*padding + titleHeight),
        botRight - Vec2f(padding, padding),
        color_black, true, true, false
        );

    Vec2f cmdStart = topLeft + Vec2f(padding, 90);
    Vec2f cmdHelpStart = cmdStart + Vec2f(124, 0);
    GUI::DrawText("Commands:", cmdStart, color_black);

    int y = 20;
    for (int i=0; i < commands.length; ++i) {
        GUI::DrawText(commands[i],     cmdStart + Vec2f(0, y), commandsColor);
        GUI::DrawText(commandsHelp[i], cmdHelpStart + Vec2f(0, y), color_black);
        y += 14;

        for (int j=0; j < commandsExamples[i].length; ++j) {
            GUI::DrawText(commandsExamples[i][j], cmdHelpStart + Vec2f(0, y), commandsExampleColor);
            y += 14;
        }

        y += 8;
        Vec2f lineStart = cmdStart + Vec2f(0,y);
        Vec2f lineEnd = lineStart + Vec2f(paneDims.x - padding * 2, 0);
        GUI::DrawLine2D(lineStart, lineEnd, SColor(255,100,100,100));
        y += 5;
    }

    RenderButtons();
}

string getPressedButtonId() {
    if (getControls().isKeyJustReleased(KEY_LBUTTON)) {
        for (uint i = 0; i < BUTTONS.length(); i++) {
            Button btn = BUTTONS[i];
            if (btn.isHovered()) {
                return btn.id;
            }
        }
    }
    return "";
}

void RenderButtons() {
    for (uint i = 0; i < BUTTONS.length(); i++) {
        Button btn = BUTTONS[i];
        btn.render();
    }
}

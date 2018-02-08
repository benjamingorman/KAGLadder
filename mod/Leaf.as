#include "Logging.as";

namespace Leaf {
    UIState state;

    funcdef void CALLBACK(Widget@);

    shared class UIState {
        Container rootWidget; // Every widget in the scene is a descendant of the root widget
        bool setRootWidget;
        bool locked_camera;
        Vec2f locked_camera_pos;

        void reset() {
            locked_camera = false;
            locked_camera_pos = Vec2f(0,0);
        }

        Widget@ getRootWidget() {
            if (!setRootWidget) {
                log("getRootWidget", "Creating root widget");
                rootWidget = Container("__root__", getScreenSize(), Vec2f(0,0));
                setRootWidget = true;
            }
            return cast<Widget>(@rootWidget);
        }
    }

    shared enum WidgetType {
        ContainerType,
        ButtonType,
        PaneType,
        TextType
    }

    shared enum PaneStyle {
        BasicPane,
        SunkenPane,
        WindowPane,
        FramedPane,
        RectPane
    }

    shared enum TextAlign {
        TextAlignBlock,
        TextAlignHeader
    }

    // Used to provide default implementations of each required method
    shared class Widget {
        WidgetType type;
        string id;
        Vec2f size;
        Vec2f position;
        bool draggable;
        bool hidden;
        bool canBeHovered;
        bool canBePressed;
        uint lastTimeHovered;
        uint lastTimePressed;
        CALLBACK@ handleClick;
        Widget@ parent;
        Widget@[] children;

        Widget(WidgetType _type, string _id, Vec2f _size, Vec2f _position) {
            type = _type;
            id = _id;
            size = _size;
            position = _position;
            draggable = false;
            hidden = false;
            canBeHovered = false;
            canBePressed = false;
            lastTimeHovered = 0;
            lastTimePressed = 0;
        }

        void addChild(Widget@ child) {
            log("addChild", "parent: " + id + ", child: " + child.id);
            children.push_back(child);
            //child.parent = this;
        }

        Vec2f getBottomRight() {
            return position + size;
        }

        void setHovered() {
            lastTimeHovered = getGameTime();
        }

        bool isHovered() {
            return lastTimeHovered == getGameTime();
        }

        void setPressed() {
            lastTimePressed = getGameTime();
        }

        bool isPressed() {
            return lastTimePressed == getGameTime();
        }

        bool isHidden() {
            return hidden;
        }

        bool isDraggable() {
            return draggable;
        }

        bool containsPoint(Vec2f point) {
            Vec2f bottomRight = getBottomRight();
            return (position.x < point.x && position.y < point.y &&
                    point.x < bottomRight.x && point.y < bottomRight.y);
        }

        // Moves the widget's position so that the center is where the top-left corner used to be
        void offsetCenter() {
            position -= size/2;
        }

        void onClick() { 
            log("Widget#onClick", id);
            if (handleClick !is null) {
                handleClick(@this);
            }
        }

        void render() {
            log("Widget#render", id);
        }

        Widget@ getChildByID(string childID) {
            for (uint i=0; i < children.length; ++i) {
                Widget@ child = children[i];
                if (child.id == childID)
                    return child;
                else {
                    Widget@ subChild = child.getChildByID(childID);
                    if (subChild !is null)
                        return subChild;
                }
            }

            return null;
        }
    }

    // A widget which is simply used as a container for other widget
    shared class Container : Widget {
        Container(string _id, Vec2f _size, Vec2f _position) {
            super(ContainerType, _id, _size, _position);
        }
    }

    shared class Button : Widget {
        Button(string _id, Vec2f _size, Vec2f _position) {
            super(ButtonType, _id, _size, _position);
            canBeHovered = true;
            canBePressed = true;
        }

        void render() override {
            //log("Button#render", id);
            Vec2f tl = position;
            Vec2f br = getBottomRight();

            if (isPressed()) {
                GUI::DrawButtonPressed(tl, br);
            }
            else if (isHovered()) {
                GUI::DrawButtonHover(tl, br);
            }
            else {
                GUI::DrawButton(tl, br);
            }
        }
    }

    shared class Pane : Widget {
        PaneStyle paneStyle;

        Pane(string _id, Vec2f _size, Vec2f _position, PaneStyle _paneStyle ) {
            super(PaneType, _id, _size, _position);
            paneStyle = _paneStyle;
        }

        void render() override {
            //log("Pane#render", id);
            Vec2f tl = position;
            Vec2f br = getBottomRight();

            if (paneStyle == BasicPane) {
                GUI::DrawPane(tl, br);
            }
            else if (paneStyle == WindowPane) {
                GUI::DrawWindow(tl, br);
            }
            else if (paneStyle == FramedPane) {
                GUI::DrawFramedPane(tl, br);
            }
            else if (paneStyle == SunkenPane) {
                GUI::DrawSunkenPane(tl, br);
            }
            else if (paneStyle == RectPane) {
                GUI::DrawRectangle(tl, br);
            }
        }
    }

    shared class Text : Widget {
        string msg;
        TextAlign alignment;
        SColor color;

        Text(string _id, Vec2f _size, Vec2f _position, string _msg) {
            super(TextType, _id, _size, _position);
            msg = _msg;
            alignment = TextAlignHeader;
            color = color_white;
        }

        void render() override {
            if (alignment == TextAlignHeader) {
                GUI::DrawTextCentered(msg, position + size/2, color);
            }
            else if (alignment == TextAlignBlock) {
                GUI::DrawText(msg, position, position + size, color, true, true, false);
            }
            else {
                log("render", "ERROR unknown text alignment " + alignment + " for " + id);
            }
        }
    }

    shared void addWidget(UIState@ state, Widget@ wgt) {
        log("Leaf#addWidget", wgt.id);
        Widget@ rootWidget = state.getRootWidget();
        rootWidget.addChild(wgt);
        //wgt.parent = rootWidget;
    }

    shared Widget@ getWidget(UIState@ state, string id) {
        log("Leaf#getWidget", id);
        return state.getRootWidget().getChildByID(id);
    }

    // Returns a list of widgets which contain the given point
    // The list is ordered according to depth
    shared Widget@[]@ listWidgetsAtPoint(Widget@ container, Vec2f point) {
        Widget@[] widgets;

        if (!container.containsPoint(point))
            return @widgets;

        for (uint i=0; i < container.children.length; ++i) {
            Widget@ child = container.children[i];

            if (child.containsPoint(point)) {
                widgets.push_back(child);
                Widget@[] subWidgets = listWidgetsAtPoint(child, point);

                for (uint j=0; j < subWidgets.length; ++j) {
                    widgets.push_back(subWidgets[j]);
                }
            }
        }

        return @widgets;
    }

    shared void update(UIState @state) {
        //log("update", "locked camera: " + state.locked_camera + ", " + state.locked_camera_pos);
        CControls@ ctrls = getControls();
        Vec2f cursor = ctrls.getMouseScreenPos();
        bool isMousePressed = ctrls.isKeyPressed(KEY_LBUTTON);
        bool isMouseJustPressed = ctrls.isKeyJustPressed(KEY_LBUTTON);

        if (state.getRootWidget() is null) {
            log("update", "ERROR nothing to upate");
            return;
        }

        Widget@ hoveredWidget = getHoveredWidget(state, cursor);

        if (hoveredWidget !is null) {
            log("update", "hoveredWidget: " + hoveredWidget.id);
            hoveredWidget.setHovered();

            if (isMousePressed)
                hoveredWidget.setPressed();
            if (isMouseJustPressed)
                hoveredWidget.onClick();
        }

        /*
        if (state.locked_camera)
            getCamera().setPosition(state.locked_camera_pos);

        state.locked_camera = false;
        state.locked_camera = true;
        state.locked_camera_pos = getCamera().getPosition();
        */
    }

    shared Widget@ getHoveredWidget(UIState @state, Vec2f cursor) {
        Widget@[]@ widgets = listWidgetsAtPoint(state.getRootWidget(), cursor);

        if (widgets.length == 0)
            return null;

        for (uint i=0; i < widgets.length; ++i) {
            Widget@ wgt = widgets[i];
            if (wgt.canBeHovered) {
                return wgt;
            }
        }

        return null;
    }

    shared void render(UIState@ state) {
        GUI::DrawText("leaf", Vec2f(300, 200), color_white);
        renderWidget(state.getRootWidget());
    }

    shared void renderWidget(Widget@ wgt) {
        //log("renderWidget", wgt.id);
        if (wgt.isHidden())
            return;

        // Can't find a cleaner way to do this polymorphism
        if (wgt.type == ButtonType) {
            Button@ btn = cast<Button>(wgt);
            btn.render();
        }
        else if (wgt.type == PaneType) {
            Pane@ pane = cast<Pane>(wgt);
            pane.render();
        }
        else if (wgt.type == TextType) {
            Text@ text = cast<Text>(wgt);
            text.render();
        }
        else if (wgt.type == ContainerType) {
            // Do nothing
        }
        else {
            log("renderWidget", "ERROR unrecognized widget type " + wgt.type + " for " + wgt.id + ", parent: " + wgt.parent.id);
        }

        for (uint i=0; i < wgt.children.length; ++i) {
            renderWidget(wgt.children[i]);
        }
    }

    shared Vec2f getScreenSize() {
        return getDriver().getScreenDimensions();
    }

    shared Vec2f getScreenCenter() {
        return getScreenSize() / 2;
    }
}

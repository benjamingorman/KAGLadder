// This module provides a class XMLParser capable of parsing a *very* simplified form of xml.
// The xml string must not contain whitespace outside of element values.
//      e.g. this is invalid: "  <html></html>"
// Elements may have values as well as child nodes, but the value must be the first child.
//      e.g. "<html>hello world<body></body></html>"
// XMLParser#parse returns an XMLDocument which represents the tree structure of the data.
// Element attributes like "<p blah='3'></p>" are not yet supported
// All tag names wil be converted to lower-case.
// Whenever a function or class method ends with _ it means it is a private method.
#include "Logging.as";


shared class XMLElement {
    XMLElement@     parent;
    XMLElement@[]   children;
    string          name;
    string          value;

    XMLElement() {
        name = "";
        value = "";
    }

    void setParent(XMLElement@ e) {
        @parent = e;
    }

    void addChild(XMLElement@ e) {
        children.push_back(e);
    }

    bool isRootElement() {
        return parent is null;
    }

    // Returns the first child element with the given name if it exists, else returns null.
    XMLElement@ getChildByName(string childName) {
        //log("XMLElement#getChildByName", "I have " + children.length() + " children");
        for (int i=0; i < children.length(); i++) {
            if (children[i].name == childName) {
                return children[i];
            }
        }

        return null;
    }
}


shared class XMLDocument {
    XMLElement@ root;

    XMLDocument(XMLElement@ e) {
        @root = e;
    }
}


namespace XMLParser {
    enum ParseState {
        DEFAULT = 0,            // at the beginning of parsing and also after finishing parsing a closing tag
        PARSING_OPENING_TAG,    // in the middle of parsing an opening tag
        PARSING_VALUE,          // just finished parsing an opening tag & in the middle of parsing a value
        PARSING_CLOSING_TAG     // in the middle of parsing a closing tag
    }
}

shared class XMLParser {
    string data = "";

    // The data to be parsed can be given as a string argument to the constructor.
    XMLParser(string _data) {
        data = _data;
    }

    // Alternatively a config file may be given, along with the property name that refers to the data string.
    XMLParser(ConfigFile cfg, string property) {
        if (!cfg.exists(property)) {
            log("XMLParser", "Given cfg doesn't have property " + property);
        }
        else {
            data = cfg.read_string(property);
        }
    }

    /* TODO
    dictionary@ parseToDict() {
        XMLDocument@ doc = parse();
        dictionary result;

        return @result;
    }

    dictionary@ _parseToDictRecursive(XMLElement@ elem) {
        dictionary result;
        dictionary sub;
        result[elem.name] = sub;
        for (int i=0; i < elem.children.length(); ++i) {
            XMLElement@ child = elem.children[i];
        }
        return @result;
    }
    */

    // Returns an XMLDocument representing the tree structure of the data
    XMLDocument@ parse() {
        //log("XMLParser#parse", "Starting parse. data length is " + data.length());
        if (data.length() == 0) {
            log("XMLParser#parse", "ERROR: data is empty");
            return null;
        }
        else if (data[0] != "<"[0]) {
            log("XMLParser#parse", "ERROR: data is invalid (doesn't start with <)");
            return null;
        }

        XMLElement@ currentElement;
        int state = XMLParser::DEFAULT;
        string tagName;
        string tagValue;
        uint[] buf;
        uint c;
        uint lookahead;

        for (int i=0; i < data.length(); i++) {
            c = data[i];
            /*
            log("XMLParser#parse", "Iteration " + i +
                ", c = " + charToString_(c) +
                ", buf = " + bufToString_(buf) +
                ", state = " + state
                );
                */

            if (state == XMLParser::DEFAULT) {
                if (c == '<'[0]) {
                    if (i+1 < data.length()) {
                        lookahead = data[i+1];
                        if (lookahead == '/'[0]) { // closing tag
                            state = XMLParser::PARSING_CLOSING_TAG;
                        }
                        else { // opening tag
                            state = XMLParser::PARSING_OPENING_TAG;
                        }
                    }
                }
                else {
                    log("XMLParser#parse", "Parse error at " + i);
                    return null;
                }
            }
            else if (state == XMLParser::PARSING_OPENING_TAG) {
                if (c == ">"[0]) {
                    // End of tag
                    tagName = bufToString_(buf).toLower();

                    XMLElement newElement();
                    newElement.name = tagName;
                    if (currentElement !is null) { // when root element not created yet then currentElement is null
                        currentElement.addChild(@newElement);
                        newElement.setParent(@currentElement);
                    }

                    @currentElement = newElement;

                    //log("XMLParser#parse", "Parsed tag " + tagName);
                    state = XMLParser::PARSING_VALUE;
                    buf.clear();
                }
                else if (isAlphaNum_(c)) {
                    // Valid tag name character
                    buf.push_back(c);
                }
                else {
                    log("XMLParser#parse", "Parse error at " + i + ": invalid char in opening tag: " + charToString_(c));
                    return null;
                }
            }
            else if (state == XMLParser::PARSING_VALUE) {
                if (c == '<'[0]) {
                    tagValue = bufToString_(buf); // might be empty
                    currentElement.value = tagValue;
                    //log("XMLParser#parse", "Parsed tag value: " + tagValue);

                    if (i+1 < data.length()) {
                        lookahead = data[i+1];
                        if (lookahead == '/'[0]) { // closing tag
                            state = XMLParser::PARSING_CLOSING_TAG;
                        }
                        else { // new opening tag
                            state = XMLParser::PARSING_OPENING_TAG;
                        }
                        buf.clear();
                    }
                    else {
                        log("XMLParser#parse", "Parse error at " + i + ": data ends with <");
                        return null;
                    }
                }
                else if (c == '>'[0]) {
                    log("XMLParser#parse", "Parse error at " + i + ": > in tag value");
                    return null;
                }
                else {
                    // Valid value character
                    buf.push_back(c);
                }
            }
            else { // PARSING_CLOSING_TAG
                if (c == '>'[0]) {
                    tagName = bufToString_(buf).toLower();
                    if (tagName != currentElement.name) {
                        log("XMLParser#parse", "Parse error at " + i +
                            ": Closing tag does not match recent opening tag: " + currentElement.name + "/" + tagName);
                        return null;
                    }
                    else {
                        //log("XMLParser#parse", "Parsed closing tag " + tagName);
                        if (currentElement.isRootElement()) {
                            //log("XMLParser#parse", "Root element");
                        }
                        else {
                            //log("XMLParser#parse", "Not root element");
                            @currentElement = currentElement.parent;
                            state = XMLParser::DEFAULT;
                            buf.clear();
                        }
                    }
                }
                else if (isAlphaNum_(c)) {
                    // Valid tag name character
                    buf.push_back(c);
                }
                else if (c == '/'[0]) {
                    continue;
                }
                else {
                    log("XMLParser#parse", "Parse error at " + i + ": invalid char in closing tag: " + charToString_(c));
                    return null;
                }
            }
        }

        //log("XMLParser#parse", "Finished parse!");

        XMLDocument doc(currentElement);
        return @doc;
    }

    // Given a uint representing a character, returns a string with just that character in.
    string charToString_(uint c) {
        uint[] buf;
        buf.push_back(c);
        return bufToString_(buf);
    }

    // Given an array of uints representing characters, returns an actual string with those characters.
    string bufToString_(uint[] buf) {
        string result;
        result.resize(buf.length());
        for (int i = 0; i < buf.length(); i++) {
            result[i] = buf[i];
        }
        return result;
    }

    // Returns true/false whether the given character is in the set [a-zA-Z0-9]
    bool isAlphaNum_(uint c) {
        bool isAlpha = "A"[0] <= c && c <= "z"[0];
        bool isNum = "0"[0] <= c && c <= "9"[0];
        return isAlpha || isNum;
    }
}


// Runs a series of tests across all classes to verify functionality.
// Returns true/false whether all the tests passed.
shared bool XMLTests() {
    log("XMLTests", "Beginning tests.");

    XMLElement e1();
    e1.name = "html";
    XMLElement e2();
    e2.name = "body";
    e2.value = "test1";
    e1.addChild(@e2);
    e2.setParent(@e1);
    XMLElement e3();
    e3.name = "body";
    e3.value = "test2";
    e1.addChild(@e3);
    e3.setParent(@e1);

    log("XMLTests", "Testing XMLElement#addChild sets child properly");
    if (e1.children.length() != 2) { return XMLTestFailed_(); }
    if (e1.children[0] !is @e2) { return XMLTestFailed_(); }
    if (e1.children[1] !is @e3) { return XMLTestFailed_(); }

    log("XMLTests", "Testing XMLElement#addChild sets parent properly2");
    if (e2.parent is null) { return XMLTestFailed_(); }
    if (e2.parent !is @e1) { return XMLTestFailed_(); }
    if (e3.parent is null) { return XMLTestFailed_(); }
    if (e3.parent !is @e1) { return XMLTestFailed_(); }

    log("XMLTests", "Testing XMLElement#isRootElement");
    if (!e1.isRootElement()) { return XMLTestFailed_(); }
    if (e2.isRootElement() || e3.isRootElement()) { return XMLTestFailed_(); }

    log("XMLTests", "Testing XMLElement#getChildByName");
    XMLElement@ e4 = e1.getChildByName("body");
    if (e4 is null) { return XMLTestFailed_(); }
    if (e4.name != "body" ) { return XMLTestFailed_(); }
    if (e4.value != "test1" ) { return XMLTestFailed_(); }
    if (@e4 !is @e2) { return XMLTestFailed_(); }

    XMLDocument@ doc;
    XMLParser parser("");
    log("XMLTests", "Testing XMLParser#parse 1");
    parser.data = "<foo></foo>";
    @doc = parser.parse();
    if (doc is null) { return XMLTestFailed_(); }
    if (doc.root is null) { return XMLTestFailed_(); }
    if (doc.root.name != "foo") { return XMLTestFailed_(); }
    if (doc.root.value != "") { return XMLTestFailed_(); }

    log("XMLTests", "Testing XMLParser#parse 2 (should fail)");
    parser.data = "<foo></bar>";
    @doc = parser.parse();
    if (doc !is null) { return XMLTestFailed_(); }

    log("XMLTests", "Testing XMLParser#parse 3");
    parser.data = "<foo><bar>2</bar><bar>3</bar><quux>1</quux></foo>";
    @doc = parser.parse();
    if (doc is null) { return XMLTestFailed_(); }
    if (doc.root is null) { return XMLTestFailed_(); }
    if (doc.root.name != "foo") { return XMLTestFailed_(); }
    XMLElement@ bar1 = doc.root.getChildByName("bar");
    if (bar1.name != "bar") { return XMLTestFailed_(); }
    if (bar1.value != "2") { return XMLTestFailed_(); }
    XMLElement@ quux1 = doc.root.getChildByName("quux");
    if (quux1.name != "quux") { return XMLTestFailed_(); }
    if (quux1.value != "1") { return XMLTestFailed_(); }

    // Segment of a serialize ActionReplay match with all but one tick removed.
    log("XMLTests", "Testing XMLParser#parse 4");
    parser.data = "<matchrecording><version>1</version><initT>0</initT><endT>173</endT><mapname>Maps/FlatMap.png</mapname><allblobmeta><blobmeta><netid>695</netid><name>knight</name><teamNum>0</teamNum><sexNum>1</sexNum><headNum>255</headNum><playerid>7</playerid><playerusername>Eluded</playerusername><playercharname>Joan of Arc</playercharname></blobmeta><blobmeta><netid>696</netid><name>knight</name><teamNum>1</teamNum><sexNum>0</sexNum><headNum>43</headNum><playerid>4</playerid><playerusername>Cohen</playerusername><playercharname>deynarde</playercharname></blobmeta></allblobmeta><recording><tick><blobdata><netid>695</netid><position>24,104</position><aimpos>0,0</aimpos><keys>0</keys><health>2</health></blobdata><blobdata><netid>696</netid><position>288,104</position><aimpos>0,0</aimpos><keys>0</keys><health>2</health></blobdata></tick></recording></matchrecording>";
    @doc = parser.parse();
    if (doc is null) { return XMLTestFailed_(); }

    log("XMLTests", "All tests passed!");
    return true;
}

// Helper function that logs an error message and returns false
shared bool XMLTestFailed_()  {
    log("XMLTests", "Test failed!");
    return false;
}

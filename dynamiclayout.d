/**
 * DynamicLayout D API — generate layout JSON from D code.
 *
 * Single-file module. Zero dependencies outside Phobos.
 * Works on D 2.080+.
 *
 * Example:
 * ---
 * import dynamiclayout;
 *
 * auto b = dlBegin("My Page");
 * b.dlFieldset("Info");
 * b.dlLabel("Hello from D!");
 * b.dlEndFieldset();
 * b.dlButton("ok", "OK", "primary", true);
 * writeln(b.dlEnd());
 * ---
 */
module dynamiclayout;

import std.array : appender;
import std.format : format;
import std.conv : to;

/// UI element types
enum Type {
    ROW = "ROW", COL = "COL", FIELDSET = "FIELDSET",
    GROUP = "GROUP", INLINE_GROUP = "INLINE_GROUP",
    FRAGMENT = "FRAGMENT", NAMED_CONTAINER = "NAMED_CONTAINER",
    LABEL = "LABEL", INPUT = "INPUT", TEXTAREA = "TEXTAREA",
    CHECKBOX = "CHECKBOX", SELECT = "SELECT",
    CREATABLE_SELECT = "CREATABLE_SELECT", RADIOBUTTON = "RADIOBUTTON",
    RATING = "RATING", READONLY_FIELD = "READONLY_FIELD",
    BUTTON = "BUTTON", ALERT = "ALERT", BADGE = "BADGE",
    BADGE_LIST = "BADGE_LIST", PROGRESS = "PROGRESS",
    SPACER = "SPACER", EDITOR = "EDITOR", LIST = "LIST",
    TABLE = "TABLE", TABLE_COLUMN = "TABLE_COLUMN",
    AG_GRID = "AG_GRID", AG_GRID_LIST_PAGE = "AG_GRID_LIST_PAGE",
    AG_GRID_COLUMN_DEF = "AG_GRID_COLUMN_DEF",
    ATTACHMENT_LIST = "ATTACHMENT_LIST", DROP_AREA = "DROP_AREA",
    CUSTOMIZED = "CUSTOMIZED", FILTER_ELEMENT = "FILTER_ELEMENT"
}

/// Bootstrap colors
enum Color {
    primary = "primary", secondary = "secondary", success = "success",
    danger = "danger", warning = "warning", info = "info",
    light = "light", dark = "dark", link = "link"
}

/// Data types
enum DataType {
    STRING = "STRING", INTEGER = "INTEGER", LONG = "LONG",
    BIG_DECIMAL = "BIG_DECIMAL", DATE = "DATE", TIME = "TIME",
    TIMESTAMP = "TIMESTAMP", BOOLEAN = "BOOLEAN", PASSWORD = "PASSWORD"
}

/// Builder state
struct DLBuilder {
    Appender!(char[]) buf;
    int depth;
    bool comma;
    int keyCounter;
}

private void dlc(DLBuilder* b, char c) {
    b.buf.put(c);
}

private void dls(DLBuilder* b, string s) {
    b.buf.put(s);
}

private void dlIndent(DLBuilder* b) {
    dlc(b, '\n');
    foreach (i; 0 .. b.depth) dls(b, "  ");
}

private void dlComma(DLBuilder* b) {
    if (b.comma) dlc(b, ',');
    b.comma = false;
}

private void dlEscape(DLBuilder* b, string s) {
    dlc(b, '"');
    foreach (c; s) {
        switch (c) {
            case '"':  dls(b, "\\\""); break;
            case '\\': dls(b, "\\\\"); break;
            case '\n': dls(b, "\\n"); break;
            case '\r': dls(b, "\\r"); break;
            case '\t': dls(b, "\\t"); break;
            default:   dlc(b, c); break;
        }
    }
    dlc(b, '"');
}

private void dlKV(DLBuilder* b, string key, string val) {
    if (val is null) return;
    dlComma(b); dlc(b, ','); dlIndent(b);
    dlEscape(b, key); dls(b, ": "); dlEscape(b, val);
    b.comma = true;
}

private void dlKVBool(DLBuilder* b, string key) {
    dlComma(b); dlc(b, ','); dlIndent(b);
    dlEscape(b, key); dls(b, ": true");
    b.comma = true;
}

private void dlKVInt(DLBuilder* b, string key, int val) {
    dlComma(b); dlc(b, ','); dlIndent(b);
    dlEscape(b, key); dls(b, ": " ~ val.to!string);
    b.comma = true;
}

private void dlObj(DLBuilder* b) {
    dlComma(b); dlc(b, ','); dlIndent(b);
    dlc(b, '{'); b.depth++; b.comma = false;
}

private void dlCloseObj(DLBuilder* b) {
    b.depth--; dlIndent(b); dlc(b, '}'); b.comma = true;
}

private void dlArr(DLBuilder* b, string key) {
    dlComma(b); dlc(b, ','); dlIndent(b);
    dlEscape(b, key); dls(b, ": [");
    b.depth++; b.comma = false;
}

private void dlCloseArr(DLBuilder* b) {
    b.depth--; dlIndent(b); dlc(b, ']'); b.comma = true;
}

private string dlKey(DLBuilder* b, string prefix) {
    b.keyCounter++;
    return prefix ~ "_" ~ b.keyCounter.to!string;
}

// ── Public API ──

DLBuilder dlBegin(string title) {
    DLBuilder b;
    b.buf = appender!string();
    b.depth = 0; b.comma = false; b.keyCounter = 0;
    dls(&b, "{\"ui\":{");
    b.depth = 2; b.comma = false;
    dlKV(&b, "title", title);
    dlArr(&b, "layout");
    return b;
}

string dlEnd(DLBuilder* b) {
    dlCloseArr(b);          // close layout array
    b.comma = false; dlc(b, ',');
    dls(b, "\"translations\":{},");
    dls(b, "\"userAccess\":{\"cancel\":true}");
    dls(b, "}}");          // close ui + root
    b.buf.put('\0');
    return b.buf.data[0 .. b.buf.data.length - 1].idup;
}

// ── Containers ──

void dlFieldset(DLBuilder* b, string title, bool collapsed) {
    dlObj(b);
    dlKV(b, "type", Type.FIELDSET);
    dlKV(b, "key", dlKey(b, "fs"));
    dlKV(b, "title", title);
    if (collapsed) dlKVBool(b, "collapsed");
    dlArr(b, "content");
}

void dlFieldsetOpen(DLBuilder* b, string title) { dlFieldset(b, title, false); }
void dlFieldsetCollapsed(DLBuilder* b, string title) { dlFieldset(b, title, true); }
void dlEndFieldset(DLBuilder* b) { dlCloseArr(b); dlCloseObj(b); }

void dlRow(DLBuilder* b) {
    dlObj(b);
    dlKV(b, "type", Type.ROW);
    dlKV(b, "key", dlKey(b, "r"));
    dlArr(b, "content");
}
void dlEndRow(DLBuilder* b) { dlCloseArr(b); dlCloseObj(b); }

void dlCol(DLBuilder* b, int xs, int md) {
    dlObj(b);
    dlKV(b, "type", Type.COL);
    dlKV(b, "key", dlKey(b, "c"));
    if (xs || md) {
        dlComma(b); dlc(b, ','); dlIndent(b);
        dls(b, "\"length\":{");
        if (xs) { dls(b, "\"xs\":" ~ xs.to!string); }
        if (md) { if (xs) dlc(b, ','); dls(b, "\"md\":" ~ md.to!string); }
        dls(b, "}");
        b.comma = true;
    }
    dlArr(b, "content");
}
void dlEndCol(DLBuilder* b) { dlCloseArr(b); dlCloseObj(b); }

// ── Display ──

void dlLabel(DLBuilder* b, string text) {
    dlObj(b); dlKV(b, "type", Type.LABEL);
    dlKV(b, "key", dlKey(b, "l"));
    dlKV(b, "label", text);
    dlCloseObj(b);
}

void dlAlert(DLBuilder* b, string message, string color) {
    dlObj(b); dlKV(b, "type", Type.ALERT);
    dlKV(b, "key", dlKey(b, "a"));
    dlKV(b, "message", message);
    dlKV(b, "color", color);
    dlCloseObj(b);
}

void dlBadge(DLBuilder* b, string title, string color) {
    dlObj(b); dlKV(b, "type", Type.BADGE);
    dlKV(b, "key", dlKey(b, "bd"));
    dlKV(b, "title", title);
    dlKV(b, "color", color);
    dlCloseObj(b);
}

void dlSpacer(DLBuilder* b, int height) {
    dlObj(b); dlKV(b, "type", Type.SPACER);
    dlKV(b, "key", dlKey(b, "sp"));
    dlKVInt(b, "width", height);
    dlCloseObj(b);
}

void dlProgress(DLBuilder* b, string label, int pct, string color) {
    dlObj(b); dlKV(b, "type", Type.PROGRESS);
    dlKV(b, "key", dlKey(b, "pr"));
    if (label) dlKV(b, "label", label);
    dlKVInt(b, "progress", pct);
    if (color) dlKV(b, "color", color);
    dlCloseObj(b);
}

// ── Inputs ──

void dlInput(DLBuilder* b, string id, string label, string dataType, bool required) {
    dlObj(b); dlKV(b, "type", Type.INPUT);
    dlKV(b, "key", dlKey(b, "i"));
    dlKV(b, "id", id);
    dlKV(b, "label", label);
    if (dataType && dataType != "STRING") dlKV(b, "dataType", dataType);
    if (required) dlKVBool(b, "required");
    dlCloseObj(b);
}

void dlTextarea(DLBuilder* b, string id, string label, int rows) {
    dlObj(b); dlKV(b, "type", Type.TEXTAREA);
    dlKV(b, "key", dlKey(b, "ta"));
    dlKV(b, "id", id);
    dlKV(b, "label", label);
    if (rows) dlKVInt(b, "rows", rows);
    dlCloseObj(b);
}

void dlCheckbox(DLBuilder* b, string id, string label) {
    dlObj(b); dlKV(b, "type", Type.CHECKBOX);
    dlKV(b, "key", dlKey(b, "cb"));
    dlKV(b, "id", id);
    dlKV(b, "label", label);
    dlCloseObj(b);
}

void dlSelect(DLBuilder* b, string id, string label, string[] ids, string[] labels) {
    dlObj(b); dlKV(b, "type", Type.SELECT);
    dlKV(b, "key", dlKey(b, "s"));
    dlKV(b, "id", id);
    dlKV(b, "label", label);
    // values array
    dlArr(b, "values");
    foreach (i; 0 .. ids.length) {
        dlObj(b);
        dlKV(b, "id", ids[i]);
        dlKV(b, "displayName", labels[i]);
        dlCloseObj(b);
    }
    dlCloseArr(b);
    dlCloseObj(b);
}

void dlRating(DLBuilder* b, string id, string label) {
    dlObj(b); dlKV(b, "type", Type.RATING);
    dlKV(b, "key", dlKey(b, "rt"));
    dlKV(b, "id", id);
    dlKV(b, "label", label);
    dlCloseObj(b);
}

void dlReadonlyField(DLBuilder* b, string id, string label) {
    dlObj(b); dlKV(b, "type", Type.READONLY_FIELD);
    dlKV(b, "key", dlKey(b, "ro"));
    dlKV(b, "id", id);
    dlKV(b, "label", label);
    dlCloseObj(b);
}

// ── Actions ──

void dlButton(DLBuilder* b, string id, string title, string color, bool isDefault) {
    dlObj(b); dlKV(b, "type", Type.BUTTON);
    dlKV(b, "key", dlKey(b, "btn"));
    dlKV(b, "id", id);
    dlKV(b, "title", title);
    dlKV(b, "color", color);
    if (isDefault) dlKVBool(b, "default");
    dlCloseObj(b);
}

// ── Shortcuts ──

void dlSection(DLBuilder* b, string title, string text) {
    dlFieldsetOpen(b, title);
    dlLabel(b, text);
    dlEndFieldset(b);
}

void dlFeedbackForm(DLBuilder* b) {
    dlFieldsetOpen(b, "Your Details");
    dlInput(b, "name", "Name", DataType.STRING, true);
    dlInput(b, "email", "Email", DataType.STRING, true);
    dlTextarea(b, "message", "Message", 5);
    dlEndFieldset(b);
    dlButton(b, "send", "Send", Color.primary, true);
    dlButton(b, "cancel", "Cancel", Color.secondary, false);
}

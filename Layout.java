// DynamicLayout Java API — generate layout JSON from pure Java code.
//
// Single-file. Zero dependencies (org.json is excluded — manual JSON building).
// Works on Java 11+.
//
// Example:
//   Layout page = Layout.begin("My Page");
//   page.fieldset("Info").label("Hello from Java!").end();
//   page.button("ok", "OK", "primary", true);
//   System.out.println(page.end());

package dynamiclayout;

import java.util.*;

public class Layout {
    private final String title, uid;
    private final List<Map<String, Object>> layout = new ArrayList<>();
    private final List<Map<String, Object>> actions = new ArrayList<>();
    private final Deque<List<Map<String, Object>>> stack = new ArrayDeque<>();
    private int counter;

    private Layout(String title) {
        this.title = title;
        this.uid = "layout_" + System.currentTimeMillis();
        stack.push(layout);
    }

    public static Layout begin(String title) { return new Layout(title); }
    public Layout uid(String uid) { return this; } // uid set by constructor

    private String k(String p) { return p + "_" + (++counter); }
    private List<Map<String, Object>> top() { return stack.peek(); }
    private Layout add(Map<String, Object> el) { top().add(el); return this; }
    private Layout push(Map<String, Object> el) {
        add(el); List<Map<String, Object>> c = new ArrayList<>();
        el.put("content", c); stack.push(c); return this;
    }
    private Layout pop() { stack.pop(); return this; }

    private static Map<String, Object> el(String type, String key, Object... kv) {
        Map<String, Object> m = new LinkedHashMap<>(); m.put("type", type); m.put("key", key);
        for (int i = 0; i + 1 < kv.length; i += 2) m.put((String) kv[i], kv[i + 1]);
        return m;
    }

    // Containers
    public Layout fieldset(String title) { return push(el("FIELDSET", k("fs"), "title", title)); }
    public Layout fieldsetCollapsed(String title) { return push(el("FIELDSET", k("fs"), "title", title, "collapsed", true)); }
    public Layout end() { return pop(); }
    public Layout row() { return push(el("ROW", k("r"))); }
    public Layout endRow() { return pop(); }
    public Layout col(int... sizes) {
        Map<String, Object> e = el("COL", k("c"));
        if (sizes.length > 0) { Map<String, Object> len = new LinkedHashMap<>();
            String[] keys = {"xs", "sm", "md", "lg", "xl"};
            for (int i = 0; i < Math.min(sizes.length, 5); i++) if (sizes[i] > 0) len.put(keys[i], sizes[i]);
            if (!len.isEmpty()) e.put("length", len);
        }
        return push(e);
    }
    public Layout endCol() { return pop(); }

    // Display
    public Layout label(String text) { return add(el("LABEL", k("l"), "label", text)); }
    public Layout alert(String message, String color) { return add(el("ALERT", k("a"), "message", message, "color", color)); }
    public Layout badge(String title, String color) { return add(el("BADGE", k("bd"), "title", title, "color", color)); }
    public Layout spacer(int px) { return add(el("SPACER", k("sp"), "width", px)); }
    public Layout progress(String label, int pct, String color) {
        Map<String, Object> e = el("PROGRESS", k("pr"), "progress", pct);
        if (label != null && !label.isEmpty()) e.put("label", label);
        if (color != null) e.put("color", color);
        return add(e);
    }

    // Inputs
    public Layout input(String id, String label) { return add(el("INPUT", k("i"), "id", id, "label", label)); }
    public Layout inputRequired(String id, String label) { return add(el("INPUT", k("i"), "id", id, "label", label, "required", true)); }
    public Layout textarea(String id, String label, int rows) { return add(el("TEXTAREA", k("ta"), "id", id, "label", label, "rows", rows)); }
    public Layout checkbox(String id, String label) { return add(el("CHECKBOX", k("cb"), "id", id, "label", label)); }
    public Layout select(String id, String label, String[]... pairs) {
        List<Map<String, Object>> vals = new ArrayList<>();
        for (String[] p : pairs) vals.add(el("", "", "id", p[0], "displayName", p[1]));
        return add(el("SELECT", k("s"), "id", id, "label", label, "values", vals));
    }
    public Layout rating(String id, String label) { return add(el("RATING", k("rt"), "id", id, "label", label)); }
    public Layout readonly(String id, String label) { return add(el("READONLY_FIELD", k("ro"), "id", id, "label", label)); }

    // Actions
    public Layout button(String id, String title, String color, boolean isDefault) {
        Map<String, Object> e = el("BUTTON", k("btn"), "id", id, "title", title, "color", color);
        if (isDefault) e.put("default", true);
        actions.add(e); return this;
    }

    // Shortcuts
    public Layout section(String title, String text) { return fieldset(title).label(text).end(); }
    public Layout feedbackForm() {
        return fieldset("Your Details")
            .inputRequired("name", "Name")
            .inputRequired("email", "Email")
            .textarea("message", "Message", 5)
            .end()
            .button("send", "Send", "primary", true)
            .button("cancel", "Cancel", "secondary", false);
    }

    // Output — manual JSON building
    public String endLayout() {
        while (stack.size() > 1) pop();
        StringBuilder sb = new StringBuilder();
        sb.append("{\n  \"ui\": {\n");
        appendStr(sb, 2, "title", title);
        appendStr(sb, 2, "uid", uid);
        appendArr(sb, 2, "layout", layout);
        if (!actions.isEmpty()) appendArr(sb, 2, "actions", actions);
        sb.append("    \"translations\": {},\n");
        sb.append("    \"userAccess\": { \"cancel\": true }\n");
        sb.append("  }\n}");
        return sb.toString();
    }

    private void appendStr(StringBuilder sb, int indent, String key, String val) {
        sb.append("  ".repeat(indent)).append('"').append(key).append("\": \"")
          .append(val.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n")).append("\",\n");
    }

    private void appendArr(StringBuilder sb, int indent, String key, List<Map<String, Object>> arr) {
        sb.append("  ".repeat(indent)).append('"').append(key).append("\": [\n");
        for (int i = 0; i < arr.size(); i++) {
            appendObj(sb, indent + 2, arr.get(i));
            if (i < arr.size() - 1) sb.append(',');
            sb.append('\n');
        }
        sb.append("  ".repeat(indent)).append("],\n");
    }

    private void appendObj(StringBuilder sb, int indent, Map<String, Object> obj) {
        sb.append("  ".repeat(indent)).append("{\n");
        List<String> keys = new ArrayList<>(obj.keySet());
        for (int i = 0; i < keys.size(); i++) {
            String k = keys.get(i);
            Object v = obj.get(k);
            sb.append("  ".repeat(indent + 1)).append('"').append(k).append("\": ");
            appendVal(sb, indent + 1, v);
            if (i < keys.size() - 1) sb.append(',');
            sb.append('\n');
        }
        sb.append("  ".repeat(indent)).append('}');
    }

    private void appendVal(StringBuilder sb, int indent, Object v) {
        if (v instanceof String) sb.append('"').append(((String) v).replace("\\", "\\\\").replace("\"", "\\\"")).append('"');
        else if (v instanceof Integer) sb.append(v);
        else if (v instanceof Boolean) sb.append(v);
        else if (v instanceof List) {
            sb.append('[');
            List<?> lst = (List<?>) v;
            for (int i = 0; i < lst.size(); i++) {
                if (i > 0) sb.append(", ");
                if (lst.get(i) instanceof Map) { appendObj(sb, 0, (Map<String, Object>) lst.get(i)); }
                else appendVal(sb, indent, lst.get(i));
            }
            sb.append(']');
        }
    }
}

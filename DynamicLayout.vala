// DynamicLayout Vala API — generate layout JSON from Vala code.
// Single-file. Zero dependencies. Works on Vala 0.56+.
// Compiles to C, runs anywhere GLib runs.
//
// Example:
//   var b = Builder.begin("My Page");
//   b.fieldset("Info").label("Hello from Vala!").end_fieldset();
//   b.button("ok", "OK", "primary", true);
//   print("%s\n", b.end());

namespace DynamicLayout {
    public class Builder {
        private StringBuilder buf = new StringBuilder();
        private int depth = 0;
        private bool comma = false;
        private int cnt = 0;

        public static Builder begin(string title) {
            var b = new Builder();
            b.puts("{\"ui\":{");
            b.depth = 2; b.comma = false;
            b.kv("title", title);
            b.arr("layout");
            return b;
        }

        private void putc(char c) { buf.append_c(c); }
        private void puts(string s) { buf.append(s); }
        private void indent() { putc('\n'); for (int i = 0; i < depth; i++) puts("  "); }
        private void cm() { if (comma) putc(','); comma = false; }
        private void esc(string s) { putc('"'); for (int i = 0; i < s.length; i++) { var c = s[i]; if (c == '"') puts("\\\""); else if (c == '\\') puts("\\\\"); else if (c == '\n') puts("\\n"); else putc(c); } putc('"'); }
        private void kv(string k, string v) { cm(); putc(','); indent(); esc(k); puts(": "); esc(v); comma = true; }
        private void kvint(string k, int v) { cm(); putc(','); indent(); esc(k); puts(@": $v"); comma = true; }
        private void kvbool(string k) { cm(); putc(','); indent(); esc(k); puts(": true"); comma = true; }
        private void obj() { cm(); putc(','); indent(); putc('{'); depth++; comma = false; }
        private void co() { depth--; indent(); putc('}'); comma = true; }
        private void arr(string k) { cm(); putc(','); indent(); esc(k); puts(": ["); depth++; comma = false; }
        private void ca() { depth--; indent(); putc(']'); comma = true; }
        private string key(string p) { cnt++; return @"$(p)_$cnt"; }

        public Builder fieldset(string title) { obj(); kv("type", "FIELDSET"); kv("key", key("fs")); kv("title", title); arr("content"); return this; }
        public Builder end_fieldset() { ca(); co(); return this; }
        public Builder row() { obj(); kv("type", "ROW"); kv("key", key("r")); arr("content"); return this; }
        public Builder end_row() { ca(); co(); return this; }
        public Builder label(string text) { obj(); kv("type", "LABEL"); kv("key", key("l")); kv("label", text); co(); return this; }
        public Builder alert(string msg, string color = "info") { obj(); kv("type", "ALERT"); kv("key", key("a")); kv("message", msg); kv("color", color); co(); return this; }
        public Builder badge(string title, string color = "primary") { obj(); kv("type", "BADGE"); kv("key", key("bd")); kv("title", title); kv("color", color); co(); return this; }
        public Builder spacer(int px = 20) { obj(); kv("type", "SPACER"); kv("key", key("sp")); kvint("width", px); co(); return this; }
        public Builder input(string id, string label, bool required = false) { obj(); kv("type", "INPUT"); kv("key", key("i")); kv("id", id); kv("label", label); if (required) kvbool("required"); co(); return this; }
        public Builder checkbox(string id, string label = "") { obj(); kv("type", "CHECKBOX"); kv("key", key("cb")); kv("id", id); kv("label", label); co(); return this; }
        public Builder textarea(string id, string label, int rows = 3) { obj(); kv("type", "TEXTAREA"); kv("key", key("ta")); kv("id", id); kv("label", label); if (rows > 0) kvint("rows", rows); co(); return this; }
        public Builder rating(string id, string label = "") { obj(); kv("type", "RATING"); kv("key", key("rt")); kv("id", id); kv("label", label); co(); return this; }
        public Builder button(string id, string title, string color = "primary", bool is_default = false) { obj(); kv("type", "BUTTON"); kv("key", key("btn")); kv("id", id); kv("title", title); kv("color", color); if (is_default) kvbool("default"); co(); return this; }
        public Builder section(string title, string text) { return fieldset(title).label(text).end_fieldset(); }

        public string end() { ca(); comma = false; putc(','); puts("\"translations\":{},"); puts("\"userAccess\":{\"cancel\":true}"); puts("}}"); return buf.str; }
    }
}

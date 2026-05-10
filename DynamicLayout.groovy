// DynamicLayout Groovy API — generate layout JSON from Groovy code.
// Single-file. Zero dependencies. Works on Groovy 3.0+.
// Example:
//   def b = DynamicLayout.begin("My Page")
//   b.fieldset("Info").label("Hello from Groovy!").end()
//   b.button("ok", "OK", "primary", true)
//   println b.end()

class DynamicLayout {
    StringBuilder buf = new StringBuilder()
    int depth = 0
    boolean comma = false
    int cnt = 0

    static DynamicLayout begin(String title) {
        def b = new DynamicLayout()
        b.puts('{"ui":{')
        b.depth = 2; b.comma = false
        b.kv('title', title)
        b.arr('layout')
        b
    }

    private putc(c) { buf.append(c); this }
    private puts(s) { buf.append(s); this }
    private indent() { putc('\n'); depth.times { puts('  ') }; this }
    private cm() { if (comma) putc(','); comma = false; this }
    private esc(s) { putc('"'); s.each { c -> switch (c) { case '"': puts('\\"'); break; case '\\': puts('\\\\'); break; case '\n': puts('\\n'); break; default: putc(c) } }; putc('"') }
    private kv(k, v) { cm(); putc(','); indent(); esc(k); puts(': '); esc(v); comma = true; this }
    private kvint(k, v) { cm(); putc(','); indent(); esc(k); puts(": $v"); comma = true; this }
    private kvbool(k) { cm(); putc(','); indent(); esc(k); puts(': true'); comma = true; this }
    private obj() { cm(); putc(','); indent(); putc('{'); depth++; comma = false; this }
    private co() { depth--; indent(); putc('}'); comma = true; this }
    private arr(k) { cm(); putc(','); indent(); esc(k); puts(': ['); depth++; comma = false; this }
    private ca() { depth--; indent(); putc(']'); comma = true; this }
    private key(p) { cnt++; "${p}_$cnt" }

    DynamicLayout fieldset(title) { obj(); kv('type', 'FIELDSET'); kv('key', key('fs')); kv('title', title); arr('content'); this }
    DynamicLayout endFieldset() { ca(); co(); this }
    DynamicLayout label(text) { obj(); kv('type', 'LABEL'); kv('key', key('l')); kv('label', text); co(); this }
    DynamicLayout alert(msg, color = 'info') { obj(); kv('type', 'ALERT'); kv('key', key('a')); kv('message', msg); kv('color', color); co(); this }
    DynamicLayout badge(title, color = 'primary') { obj(); kv('type', 'BADGE'); kv('key', key('bd')); kv('title', title); kv('color', color); co(); this }
    DynamicLayout spacer(px = 20) { obj(); kv('type', 'SPACER'); kv('key', key('sp')); kvint('width', px); co(); this }
    DynamicLayout input(id, label, required = false) { obj(); kv('type', 'INPUT'); kv('key', key('i')); kv('id', id); kv('label', label); if (required) kvbool('required'); co(); this }
    DynamicLayout checkbox(id, label = '') { obj(); kv('type', 'CHECKBOX'); kv('key', key('cb')); kv('id', id); kv('label', label); co(); this }
    DynamicLayout textarea(id, label, rows = 3) { obj(); kv('type', 'TEXTAREA'); kv('key', key('ta')); kv('id', id); kv('label', label); if (rows > 0) kvint('rows', rows); co(); this }
    DynamicLayout rating(id, label = '') { obj(); kv('type', 'RATING'); kv('key', key('rt')); kv('id', id); kv('label', label); co(); this }
    DynamicLayout button(id, title, color, isDefault = false) { obj(); kv('type', 'BUTTON'); kv('key', key('btn')); kv('id', id); kv('title', title); kv('color', color); if (isDefault) kvbool('default'); co(); this }
    DynamicLayout section(title, text) { fieldset(title).label(text).endFieldset(); this }

    String end() { ca(); comma = false; putc(','); puts('"translations":{},'); puts('"userAccess":{"cancel":true}'); puts('}}'); buf.toString() }
}

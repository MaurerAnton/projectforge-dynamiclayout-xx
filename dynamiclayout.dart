// DynamicLayout Dart API — generate layout JSON from Dart code.
// Single-file. Zero dependencies. Works on Dart 3.0+.

class Layout {
  final StringBuffer _buf = StringBuffer();
  int _depth = 0;
  bool _comma = false;
  int _cnt = 0;

  Layout(String title) {
    _buf.write('{"ui":{');
    _depth = 2; _comma = false;
    _kv("title", title);
    _arr("layout");
  }

  void _putc(String c) => _buf.write(c);
  void _puts(String s) => _buf.write(s);
  void _indent() { _putc('\n'); for (var i = 0; i < _depth; i++) _puts('  '); }
  void _cm() { if (_comma) _putc(','); _comma = false; }
  void _esc(String s) { _putc('"'); for (final c in s.runes) { final ch = String.fromCharCode(c); if (ch == '"') _puts('\\\"'); else if (ch == '\\') _puts('\\\\'); else if (ch == '\n') _puts('\\n'); else _putc(ch); } _putc('"'); }
  void _kv(String k, String v) { _cm(); _putc(','); _indent(); _esc(k); _puts(': '); _esc(v); _comma = true; }
  void _kvint(String k, int v) { _cm(); _putc(','); _indent(); _esc(k); _puts(': $v'); _comma = true; }
  void _kvbool(String k) { _cm(); _putc(','); _indent(); _esc(k); _puts(': true'); _comma = true; }
  void _obj() { _cm(); _putc(','); _indent(); _putc('{'); _depth++; _comma = false; }
  void _co() { _depth--; _indent(); _putc('}'); _comma = true; }
  void _arr(String k) { _cm(); _putc(','); _indent(); _esc(k); _puts(': ['); _depth++; _comma = false; }
  void _ca() { _depth--; _indent(); _putc(']'); _comma = true; }
  String _key(String p) { _cnt++; return '${p}_$_cnt'; }

  Layout fieldset(String title) { _obj(); _kv('type', 'FIELDSET'); _kv('key', _key('fs')); _kv('title', title); _arr('content'); return this; }
  Layout endFieldset() { _ca(); _co(); return this; }
  Layout row() { _obj(); _kv('type', 'ROW'); _kv('key', _key('r')); _arr('content'); return this; }
  Layout endRow() { _ca(); _co(); return this; }
  Layout label(String text) { _obj(); _kv('type', 'LABEL'); _kv('key', _key('l')); _kv('label', text); _co(); return this; }
  Layout alert(String msg, [String color = 'info']) { _obj(); _kv('type', 'ALERT'); _kv('key', _key('a')); _kv('message', msg); _kv('color', color); _co(); return this; }
  Layout badge(String title, [String color = 'primary']) { _obj(); _kv('type', 'BADGE'); _kv('key', _key('bd')); _kv('title', title); _kv('color', color); _co(); return this; }
  Layout spacer([int px = 20]) { _obj(); _kv('type', 'SPACER'); _kv('key', _key('sp')); _kvint('width', px); _co(); return this; }
  Layout input(String id, String label, [bool required = false]) { _obj(); _kv('type', 'INPUT'); _kv('key', _key('i')); _kv('id', id); _kv('label', label); if (required) _kvbool('required'); _co(); return this; }
  Layout checkbox(String id, [String label = '']) { _obj(); _kv('type', 'CHECKBOX'); _kv('key', _key('cb')); _kv('id', id); _kv('label', label); _co(); return this; }
  Layout textarea(String id, String label, [int rows = 3]) { _obj(); _kv('type', 'TEXTAREA'); _kv('key', _key('ta')); _kv('id', id); _kv('label', label); if (rows > 0) _kvint('rows', rows); _co(); return this; }
  Layout rating(String id, [String label = '']) { _obj(); _kv('type', 'RATING'); _kv('key', _key('rt')); _kv('id', id); _kv('label', label); _co(); return this; }
  Layout button(String id, String title, String color, [bool isDefault = false]) { _obj(); _kv('type', 'BUTTON'); _kv('key', _key('btn')); _kv('id', id); _kv('title', title); _kv('color', color); if (isDefault) _kvbool('default'); _co(); return this; }
  Layout section(String title, String text) => fieldset(title).label(text).endFieldset();

  String end() { _ca(); _comma = false; _putc(','); _puts('"translations":{},'); _puts('"userAccess":{"cancel":true}'); _puts('}}'); return _buf.toString(); }
}

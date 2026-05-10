// DynamicLayout TypeScript standalone API — generate layout JSON from TypeScript.
// Single-file. Zero dependencies. Works on Deno, Bun, Node (ESM or CJS).
// This is the standalone version — the playground has a separate JsLayout implementation.

type JsonValue = string | number | boolean | null | JsonValue[] | { [key: string]: JsonValue };

class Layout {
  private buf = '';
  private depth = 0;
  private comma = false;
  private cnt = 0;

  constructor(title: string) {
    this.puts('{"ui":{');
    this.depth = 2; this.comma = false;
    this.kv('title', title);
    this.arr('layout');
  }

  private putc(c: string) { this.buf += c; }
  private puts(s: string) { this.buf += s; }
  private indent() { this.putc('\n'); this.puts('  '.repeat(this.depth)); }
  private cm() { if (this.comma) this.putc(','); this.comma = false; }
  private esc(s: string) { this.putc('"'); for (const c of s) { if (c === '"') this.puts('\\"'); else if (c === '\\') this.puts('\\\\'); else if (c === '\n') this.puts('\\n'); else this.putc(c); } this.putc('"'); }
  private kv(k: string, v: string) { this.cm(); this.putc(','); this.indent(); this.esc(k); this.puts(': '); this.esc(v); this.comma = true; }
  private kvint(k: string, v: number) { this.cm(); this.putc(','); this.indent(); this.esc(k); this.puts(`: ${v}`); this.comma = true; }
  private kvbool(k: string) { this.cm(); this.putc(','); this.indent(); this.esc(k); this.puts(': true'); this.comma = true; }
  private obj() { this.cm(); this.putc(','); this.indent(); this.putc('{'); this.depth++; this.comma = false; }
  private co() { this.depth--; this.indent(); this.putc('}'); this.comma = true; }
  private arr(k: string) { this.cm(); this.putc(','); this.indent(); this.esc(k); this.puts(': ['); this.depth++; this.comma = false; }
  private ca() { this.depth--; this.indent(); this.putc(']'); this.comma = true; }
  private key(p: string) { this.cnt++; return `${p}_${this.cnt}`; }

  fieldset(title: string): Layout { this.obj(); this.kv('type', 'FIELDSET'); this.kv('key', this.key('fs')); this.kv('title', title); this.arr('content'); return this; }
  endFieldset(): Layout { this.ca(); this.co(); return this; }
  row(): Layout { this.obj(); this.kv('type', 'ROW'); this.kv('key', this.key('r')); this.arr('content'); return this; }
  endRow(): Layout { this.ca(); this.co(); return this; }
  label(text: string): Layout { this.obj(); this.kv('type', 'LABEL'); this.kv('key', this.key('l')); this.kv('label', text); this.co(); return this; }
  alert(msg: string, color = 'info'): Layout { this.obj(); this.kv('type', 'ALERT'); this.kv('key', this.key('a')); this.kv('message', msg); this.kv('color', color); this.co(); return this; }
  badge(title: string, color = 'primary'): Layout { this.obj(); this.kv('type', 'BADGE'); this.kv('key', this.key('bd')); this.kv('title', title); this.kv('color', color); this.co(); return this; }
  spacer(px = 20): Layout { this.obj(); this.kv('type', 'SPACER'); this.kv('key', this.key('sp')); this.kvint('width', px); this.co(); return this; }
  input(id: string, label: string, required = false): Layout {
    this.obj(); this.kv('type', 'INPUT'); this.kv('key', this.key('i')); this.kv('id', id); this.kv('label', label);
    if (required) this.kvbool('required');
    this.co(); return this;
  }
  checkbox(id: string, label = ''): Layout { this.obj(); this.kv('type', 'CHECKBOX'); this.kv('key', this.key('cb')); this.kv('id', id); this.kv('label', label); this.co(); return this; }
  textarea(id: string, label: string, rows = 3): Layout { this.obj(); this.kv('type', 'TEXTAREA'); this.kv('key', this.key('ta')); this.kv('id', id); this.kv('label', label); if (rows > 0) this.kvint('rows', rows); this.co(); return this; }
  rating(id: string, label = ''): Layout { this.obj(); this.kv('type', 'RATING'); this.kv('key', this.key('rt')); this.kv('id', id); this.kv('label', label); this.co(); return this; }
  button(id: string, title: string, color = 'primary', isDefault = false): Layout {
    this.obj(); this.kv('type', 'BUTTON'); this.kv('key', this.key('btn')); this.kv('id', id); this.kv('title', title); this.kv('color', color);
    if (isDefault) this.kvbool('default');
    this.co(); return this;
  }
  section(title: string, text: string): Layout { return this.fieldset(title).label(text).endFieldset(); }

  end(): string { this.ca(); this.comma = false; this.putc(','); this.puts('"translations":{},'); this.puts('"userAccess":{"cancel":true}'); this.puts('}}'); return this.buf; }
}

export default Layout;

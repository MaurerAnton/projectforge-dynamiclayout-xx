// DynamicLayout V API — generate layout JSON from V code.
// Single-file. Zero dependencies. Works on V 0.4+.
// Example:
//   mut b := dynamiclayout.begin('My Page')
//   b.fieldset('Info')
//   b.label('Hello from V!')
//   b.end_fieldset()
//   b.button('ok', 'OK', 'primary', true)
//   println(b.end())

module dynamiclayout

import strings

pub struct Builder {
mut:
	buf    strings.Builder = strings.new_builder(4096)
	depth  int
	comma  bool
	cnt    int
}

pub fn begin(title string) &Builder {
	mut b := &Builder{depth: 0, comma: false, cnt: 0}
	b.puts('{"ui":{')
	b.depth = 2; b.comma = false
	b.kv('title', title)
	b.arr('layout')
	return b
}

fn (mut b Builder) putc(c u8) { b.buf.write_b(c) }
fn (mut b Builder) puts(s string) { b.buf.write_string(s) }
fn (mut b Builder) indent() { b.putc(`\n`); for _ in 0 .. b.depth { b.puts('  ') } }
fn (mut b Builder) cm() { if b.comma { b.putc(`,`) }; b.comma = false }
fn (mut b Builder) esc(s string) {
	b.putc(`"`)
	for c in s {
		match c {
			`"`  { b.puts('\\"') }  `\\` { b.puts('\\\\') }
			`\n` { b.puts('\\n') }  `\r` { b.puts('\\r') }  `\t` { b.puts('\\t') }
			else { b.buf.write_rune(c) }
		}
	}
	b.putc(`"`)
}
fn (mut b Builder) kv(k string, v string) { b.cm(); b.putc(`,`); b.indent(); b.esc(k); b.puts(': '); b.esc(v); b.comma = true }
fn (mut b Builder) kvint(k string, v int) { b.cm(); b.putc(`,`); b.indent(); b.esc(k); b.puts(': ${v}'); b.comma = true }
fn (mut b Builder) kvbool(k string) { b.cm(); b.putc(`,`); b.indent(); b.esc(k); b.puts(': true'); b.comma = true }
fn (mut b Builder) obj() { b.cm(); b.putc(`,`); b.indent(); b.putc(`{`); b.depth++; b.comma = false }
fn (mut b Builder) co() { b.depth--; b.indent(); b.putc(`}`); b.comma = true }
fn (mut b Builder) arr(k string) { b.cm(); b.putc(`,`); b.indent(); b.esc(k); b.puts(': ['); b.depth++; b.comma = false }
fn (mut b Builder) ca() { b.depth--; b.indent(); b.putc(`]`); b.comma = true }
fn (mut b Builder) key(prefix string) string { b.cnt++; return '${prefix}_${b.cnt}' }

pub fn (mut b Builder) fieldset(title string) &Builder { b.obj(); b.kv('type', 'FIELDSET'); b.kv('key', b.key('fs')); b.kv('title', title); b.arr('content'); return b }
pub fn (mut b Builder) end_fieldset() &Builder { b.ca(); b.co(); return b }
pub fn (mut b Builder) row() &Builder { b.obj(); b.kv('type', 'ROW'); b.kv('key', b.key('r')); b.arr('content'); return b }
pub fn (mut b Builder) end_row() &Builder { b.ca(); b.co(); return b }
pub fn (mut b Builder) label(text string) &Builder { b.obj(); b.kv('type', 'LABEL'); b.kv('key', b.key('l')); b.kv('label', text); b.co(); return b }
pub fn (mut b Builder) alert(msg string, color string) &Builder { b.obj(); b.kv('type', 'ALERT'); b.kv('key', b.key('a')); b.kv('message', msg); b.kv('color', color); b.co(); return b }
pub fn (mut b Builder) badge(title string, color string) &Builder { b.obj(); b.kv('type', 'BADGE'); b.kv('key', b.key('bd')); b.kv('title', title); b.kv('color', color); b.co(); return b }
pub fn (mut b Builder) spacer(px int) &Builder { b.obj(); b.kv('type', 'SPACER'); b.kv('key', b.key('sp')); b.kvint('width', px); b.co(); return b }
pub fn (mut b Builder) input(id string, label string, required bool) &Builder {
	b.obj(); b.kv('type', 'INPUT'); b.kv('key', b.key('i')); b.kv('id', id); b.kv('label', label)
	if required { b.kvbool('required') }; b.co(); return b
}
pub fn (mut b Builder) checkbox(id string, label string) &Builder { b.obj(); b.kv('type', 'CHECKBOX'); b.kv('key', b.key('cb')); b.kv('id', id); b.kv('label', label); b.co(); return b }
pub fn (mut b Builder) textarea(id string, label string, rows int) &Builder {
	b.obj(); b.kv('type', 'TEXTAREA'); b.kv('key', b.key('ta')); b.kv('id', id); b.kv('label', label)
	if rows > 0 { b.kvint('rows', rows) }; b.co(); return b
}
pub fn (mut b Builder) rating(id string, label string) &Builder { b.obj(); b.kv('type', 'RATING'); b.kv('key', b.key('rt')); b.kv('id', id); b.kv('label', label); b.co(); return b }
pub fn (mut b Builder) button(id string, title string, color string, is_default bool) &Builder {
	b.obj(); b.kv('type', 'BUTTON'); b.kv('key', b.key('btn')); b.kv('id', id); b.kv('title', title); b.kv('color', color)
	if is_default { b.kvbool('default') }; b.co(); return b
}
pub fn (mut b Builder) section(title string, text string) &Builder { b.fieldset(title).label(text).end_fieldset(); return b }
pub fn (mut b Builder) end() string { b.ca(); b.comma = false; b.putc(`,`); b.puts('"translations":{},'); b.puts('"userAccess":{"cancel":true}'); b.puts('}}'); return b.buf.str() }

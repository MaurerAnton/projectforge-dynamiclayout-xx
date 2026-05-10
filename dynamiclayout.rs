// DynamicLayout Rust API — generate layout JSON from Rust code.
// Single-file crate module. Zero dependencies outside std. Works on Rust 1.65+.
//
// Example:
//   use dynamiclayout::Builder;
//   let mut b = Builder::begin("My Page");
//   b.fieldset("Info").label("Hello from Rust!").end_fieldset();
//   b.button("ok", "OK", "primary", true);
//   println!("{}", b.end());

use std::fmt::Write;

pub struct Builder {
    buf: String,
    depth: usize,
    comma: bool,
    cnt: usize,
}

impl Builder {
    pub fn begin(title: &str) -> Self {
        let mut b = Builder { buf: String::with_capacity(4096), depth: 0, comma: false, cnt: 0 };
        b.puts("{\"ui\":{");
        b.depth = 2; b.comma = false;
        b.kv("title", title);
        b.arr("layout");
        b
    }

    fn putc(&mut self, c: char) -> &mut Self { self.buf.push(c); self }
    fn puts(&mut self, s: &str) -> &mut Self { self.buf.push_str(s); self }
    fn indent(&mut self) -> &mut Self { self.putc('\n'); for _ in 0..self.depth { self.puts("  "); } self }
    fn cm(&mut self) -> &mut Self { if self.comma { self.putc(','); } self.comma = false; self }
    fn esc(&mut self, s: &str) -> &mut Self {
        self.putc('"');
        for c in s.chars() { match c { '"' => self.puts("\\\""), '\\' => self.puts("\\\\"), '\n' => self.puts("\\n"), '\r' => self.puts("\\r"), '\t' => self.puts("\\t"), _ => { self.putc(c); } } }
        self.putc('"')
    }
    fn kv(&mut self, k: &str, v: &str) -> &mut Self { self.cm(); self.putc(','); self.indent(); self.esc(k); self.puts(": "); self.esc(v); self.comma = true; self }
    fn kvint(&mut self, k: &str, v: i32) -> &mut Self { self.cm(); self.putc(','); self.indent(); self.esc(k); write!(self.buf, ": {}", v).unwrap(); self.comma = true; self }
    fn kvbool(&mut self, k: &str) -> &mut Self { self.cm(); self.putc(','); self.indent(); self.esc(k); self.puts(": true"); self.comma = true; self }
    fn obj(&mut self) -> &mut Self { self.cm(); self.putc(','); self.indent(); self.putc('{'); self.depth += 1; self.comma = false; self }
    fn co(&mut self) -> &mut Self { self.depth -= 1; self.indent(); self.putc('}'); self.comma = true; self }
    fn arr(&mut self, k: &str) -> &mut Self { self.cm(); self.putc(','); self.indent(); self.esc(k); self.puts(": ["); self.depth += 1; self.comma = false; self }
    fn ca(&mut self) -> &mut Self { self.depth -= 1; self.indent(); self.putc(']'); self.comma = true; self }
    fn key(&mut self, p: &str) -> String { self.cnt += 1; format!("{}_{}", p, self.cnt) }

    pub fn fieldset(&mut self, title: &str) -> &mut Self { let k = self.key("fs"); self.obj(); self.kv("type", "FIELDSET"); self.kv("key", &k); self.kv("title", title); self.arr("content"); self }
    pub fn end_fieldset(&mut self) -> &mut Self { self.ca(); self.co() }
    pub fn row(&mut self) -> &mut Self { let k = self.key("r"); self.obj(); self.kv("type", "ROW"); self.kv("key", &k); self.arr("content"); self }
    pub fn end_row(&mut self) -> &mut Self { self.ca(); self.co() }
    pub fn col(&mut self, xs: i32, md: i32) -> &mut Self { let k = self.key("c"); self.obj(); self.kv("type", "COL"); self.kv("key", &k); if xs > 0 || md > 0 { self.cm(); self.putc(','); self.indent(); self.puts("\"length\":{"); if xs > 0 { self.puts("\"xs\":"); write!(self.buf, "{}", xs).unwrap(); if md > 0 { self.putc(','); } } if md > 0 { self.puts("\"md\":"); write!(self.buf, "{}", md).unwrap(); } self.puts("}"); self.comma = true; } self.arr("content"); self }
    pub fn end_col(&mut self) -> &mut Self { self.ca(); self.co() }
    pub fn label(&mut self, text: &str) -> &mut Self { let k = self.key("l"); self.obj(); self.kv("type", "LABEL"); self.kv("key", &k); self.kv("label", text); self.co() }
    pub fn alert(&mut self, msg: &str, color: &str) -> &mut Self { let k = self.key("a"); self.obj(); self.kv("type", "ALERT"); self.kv("key", &k); self.kv("message", msg); self.kv("color", color); self.co() }
    pub fn badge(&mut self, title: &str, color: &str) -> &mut Self { let k = self.key("bd"); self.obj(); self.kv("type", "BADGE"); self.kv("key", &k); self.kv("title", title); self.kv("color", color); self.co() }
    pub fn spacer(&mut self, px: i32) -> &mut Self { let k = self.key("sp"); self.obj(); self.kv("type", "SPACER"); self.kv("key", &k); self.kvint("width", px); self.co() }
    pub fn input(&mut self, id: &str, label: &str, required: bool) -> &mut Self { let k = self.key("i"); self.obj(); self.kv("type", "INPUT"); self.kv("key", &k); self.kv("id", id); self.kv("label", label); if required { self.kvbool("required"); } self.co() }
    pub fn checkbox(&mut self, id: &str, label: &str) -> &mut Self { let k = self.key("cb"); self.obj(); self.kv("type", "CHECKBOX"); self.kv("key", &k); self.kv("id", id); self.kv("label", label); self.co() }
    pub fn textarea(&mut self, id: &str, label: &str, rows: i32) -> &mut Self { let k = self.key("ta"); self.obj(); self.kv("type", "TEXTAREA"); self.kv("key", &k); self.kv("id", id); self.kv("label", label); if rows > 0 { self.kvint("rows", rows); } self.co() }
    pub fn rating(&mut self, id: &str, label: &str) -> &mut Self { let k = self.key("rt"); self.obj(); self.kv("type", "RATING"); self.kv("key", &k); self.kv("id", id); self.kv("label", label); self.co() }
    pub fn button(&mut self, id: &str, title: &str, color: &str, is_default: bool) -> &mut Self { let k = self.key("btn"); self.obj(); self.kv("type", "BUTTON"); self.kv("key", &k); self.kv("id", id); self.kv("title", title); self.kv("color", color); if is_default { self.kvbool("default"); } self.co() }
    pub fn section(&mut self, title: &str, text: &str) -> &mut Self { self.fieldset(title).label(text).end_fieldset() }

    pub fn end(&mut self) -> &str { self.ca(); self.comma = false; self.putc(','); self.puts("\"translations\":{},"); self.puts("\"userAccess\":{\"cancel\":true}"); self.puts("}}"); &self.buf }
}

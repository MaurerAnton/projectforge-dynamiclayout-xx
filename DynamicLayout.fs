// DynamicLayout F# API — generate layout JSON from F# code.
// Single-file. Zero dependencies. Works on .NET 6+.
// Example:
//   open DynamicLayout
//   let b = Layout.begin "My Page"
//   b.fieldset("Info").label("Hello from F#!").endFieldset()
//   b.button("ok", "OK", "primary", true) |> ignore
//   printfn "%s" (b.end())

module DynamicLayout

open System.Text

type Builder() =
    let sb = StringBuilder()
    let mutable depth = 0
    let mutable comma = false
    let mutable cnt = 0

    member private _.putc(c: char) = sb.Append(c) |> ignore
    member private _.puts(s: string) = sb.Append(s) |> ignore
    member private b.indent() = b.putc('\n'); for _ in 1..depth do b.puts("  ")
    member private b.cm() = if comma then b.putc(','); comma <- false
    member private b.esc(s: string) =
        b.putc('"')
        for c in s do match c with '"' -> b.puts("\\\"") | '\\' -> b.puts("\\\\") | '\n' -> b.puts("\\n") | _ -> b.putc(c)
        b.putc('"')
    member private b.kv(k, v) = b.cm(); b.putc(','); b.indent(); b.esc(k); b.puts(": "); b.esc(v); comma <- true
    member private b.kvint(k, v) = b.cm(); b.putc(','); b.indent(); b.esc(k); b.puts(sprintf ": %d" v); comma <- true
    member private b.kvbool(k) = b.cm(); b.putc(','); b.indent(); b.esc(k); b.puts(": true"); comma <- true
    member private b.obj() = b.cm(); b.putc(','); b.indent(); b.putc('{'); depth <- depth + 1; comma <- false
    member private b.co() = depth <- depth - 1; b.indent(); b.putc('}'); comma <- true
    member private b.arr(k) = b.cm(); b.putc(','); b.indent(); b.esc(k); b.puts(": ["); depth <- depth + 1; comma <- false
    member private b.ca() = depth <- depth - 1; b.indent(); b.putc(']'); comma <- true
    member private b.key(p) = cnt <- cnt + 1; sprintf "%s_%d" p cnt

    member b.fieldset(title) = b.obj(); b.kv("type", "FIELDSET"); b.kv("key", b.key("fs")); b.kv("title", title); b.arr("content"); b
    member b.endFieldset() = b.ca(); b.co(); b
    member b.row() = b.obj(); b.kv("type", "ROW"); b.kv("key", b.key("r")); b.arr("content"); b
    member b.endRow() = b.ca(); b.co(); b
    member b.label(text) = b.obj(); b.kv("type", "LABEL"); b.kv("key", b.key("l")); b.kv("label", text); b.co(); b
    member b.alert(msg, ?color) = let c = defaultArg color "info" in b.obj(); b.kv("type", "ALERT"); b.kv("key", b.key("a")); b.kv("message", msg); b.kv("color", c); b.co(); b
    member b.badge(title, ?color) = let c = defaultArg color "primary" in b.obj(); b.kv("type", "BADGE"); b.kv("key", b.key("bd")); b.kv("title", title); b.kv("color", c); b.co(); b
    member b.spacer(?px) = let p = defaultArg px 20 in b.obj(); b.kv("type", "SPACER"); b.kv("key", b.key("sp")); b.kvint("width", p); b.co(); b
    member b.input(id, label, ?required) = b.obj(); b.kv("type", "INPUT"); b.kv("key", b.key("i")); b.kv("id", id); b.kv("label", label); if defaultArg required false then b.kvbool("required"); b.co(); b
    member b.checkbox(id, ?label) = let l = defaultArg label "" in b.obj(); b.kv("type", "CHECKBOX"); b.kv("key", b.key("cb")); b.kv("id", id); b.kv("label", l); b.co(); b
    member b.textarea(id, label, ?rows) = let r = defaultArg rows 3 in b.obj(); b.kv("type", "TEXTAREA"); b.kv("key", b.key("ta")); b.kv("id", id); b.kv("label", label); if r > 0 then b.kvint("rows", r); b.co(); b
    member b.rating(id, ?label) = let l = defaultArg label "" in b.obj(); b.kv("type", "RATING"); b.kv("key", b.key("rt")); b.kv("id", id); b.kv("label", l); b.co(); b
    member b.button(id, title, color, ?isDefault) = b.obj(); b.kv("type", "BUTTON"); b.kv("key", b.key("btn")); b.kv("id", id); b.kv("title", title); b.kv("color", color); if defaultArg isDefault false then b.kvbool("default"); b.co(); b
    member b.section(title, text) = b.fieldset(title).label(text).endFieldset()
    member b.end() = b.ca(); comma <- false; b.putc(','); b.puts("\"translations\":{},"); b.puts("\"userAccess\":{\"cancel\":true}"); b.puts("}}"); sb.ToString()
    static member begin title = let b = Builder() in b.puts("{\"ui\":{"); b.depth <- 2; b.comma <- false; b.kv("title", title); b.arr("layout"); b

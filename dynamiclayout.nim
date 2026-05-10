# DynamicLayout Nim API — generate layout JSON from Nim code.
#
# Single-file. Zero dependencies outside the standard library.
# Works on Nim 2.0+.
#
# Example:
#   import dynamiclayout
#   var b = begin("My Page")
#   b.fieldset("Info")
#   b.label("Hello from Nim!")
#   b.endFieldset()
#   b.button("ok", "OK", "primary", true)
#   echo b.endLayout()

import std/strutils

type
  Builder* = ref object
    buf: string
    depth: int
    comma: bool
    counter: int

proc put(b: Builder, c: char) = b.buf.add(c)
proc puts(b: Builder, s: string) = b.buf.add(s)
proc indent(b: Builder) =
  b.put('\n')
  for _ in 0..<b.depth: b.puts("  ")

proc cm(b: Builder) =
  if b.comma: b.put(','); b.comma = false

proc escape(b: Builder, s: string) =
  b.put('"')
  for c in s:
    case c
    of '"': b.puts("\\\"")
    of '\\': b.puts("\\\\")
    of '\n': b.puts("\\n")
    of '\r': b.puts("\\r")
    of '\t': b.puts("\\t")
    else: b.put(c)
  b.put('"')

proc kv(b: Builder, key, val: string) =
  b.cm(); b.put(','); b.indent()
  b.escape(key); b.puts(": "); b.escape(val)
  b.comma = true

proc kvint(b: Builder, key: string, val: int) =
  b.cm(); b.put(','); b.indent()
  b.escape(key); b.puts(": "); b.puts($val)
  b.comma = true

proc kvbool(b: Builder, key: string) =
  b.cm(); b.put(','); b.indent()
  b.escape(key); b.puts(": true")
  b.comma = true

proc obj(b: Builder) =
  b.cm(); b.put(','); b.indent()
  b.put('{'); inc b.depth; b.comma = false

proc closeObj(b: Builder) =
  dec b.depth; b.indent(); b.put('}'); b.comma = true

proc arr(b: Builder, key: string) =
  b.cm(); b.put(','); b.indent()
  b.escape(key); b.puts(": [")
  inc b.depth; b.comma = false

proc closeArr(b: Builder) =
  dec b.depth; b.indent(); b.put(']'); b.comma = true

proc key(b: Builder, prefix: string): string =
  inc b.counter; result = prefix & "_" & $b.counter

# Public API

proc begin*(title: string): Builder =
  result = Builder(depth: 0, comma: false, counter: 0)
  result.puts("{\"ui\":{")
  result.depth = 2; result.comma = false
  result.kv("title", title)
  result.arr("layout")

proc endLayout*(b: Builder): string =
  b.closeArr()
  b.comma = false; b.put(',')
  b.puts("\"translations\":{},")
  b.puts("\"userAccess\":{\"cancel\":true}")
  b.puts("}}")
  result = b.buf

# Containers

proc fieldset*(b: Builder, title: string) =
  b.obj(); b.kv("type", "FIELDSET"); b.kv("key", b.key("fs")); b.kv("title", title); b.arr("content")

proc endFieldset*(b: Builder) = b.closeArr(); b.closeObj()

proc row*(b: Builder) =
  b.obj(); b.kv("type", "ROW"); b.kv("key", b.key("r")); b.arr("content")

proc endRow*(b: Builder) = b.closeArr(); b.closeObj()

proc col*(b: Builder, xs: int = 0, md: int = 0) =
  b.obj(); b.kv("type", "COL"); b.kv("key", b.key("c"))
  if xs > 0 or md > 0:
    b.cm(); b.put(','); b.indent()
    b.puts("\"length\":{")
    if xs > 0:
      b.puts("\"xs\":"); b.puts($xs)
      if md > 0: b.put(',')
    if md > 0:
      b.puts("\"md\":"); b.puts($md)
    b.puts("}")
    b.comma = true
  b.arr("content")

proc endCol*(b: Builder) = b.closeArr(); b.closeObj()

# Display

proc label*(b: Builder, text: string) =
  b.obj(); b.kv("type", "LABEL"); b.kv("key", b.key("l")); b.kv("label", text); b.closeObj()

proc alert*(b: Builder, message, color: string) =
  b.obj(); b.kv("type", "ALERT"); b.kv("key", b.key("a")); b.kv("message", message); b.kv("color", color); b.closeObj()

proc badge*(b: Builder, title, color: string) =
  b.obj(); b.kv("type", "BADGE"); b.kv("key", b.key("bd")); b.kv("title", title); b.kv("color", color); b.closeObj()

proc spacer*(b: Builder, px: int) =
  b.obj(); b.kv("type", "SPACER"); b.kv("key", b.key("sp")); b.kvint("width", px); b.closeObj()

# Inputs

proc input*(b: Builder, id, label: string, required: bool = false) =
  b.obj(); b.kv("type", "INPUT"); b.kv("key", b.key("i")); b.kv("id", id); b.kv("label", label)
  if required: b.kvbool("required")
  b.closeObj()

proc textarea*(b: Builder, id, label: string, rows: int = 3) =
  b.obj(); b.kv("type", "TEXTAREA"); b.kv("key", b.key("ta")); b.kv("id", id); b.kv("label", label)
  if rows > 0: b.kvint("rows", rows)
  b.closeObj()

proc checkbox*(b: Builder, id, label: string) =
  b.obj(); b.kv("type", "CHECKBOX"); b.kv("key", b.key("cb")); b.kv("id", id); b.kv("label", label); b.closeObj()

proc rating*(b: Builder, id, label: string) =
  b.obj(); b.kv("type", "RATING"); b.kv("key", b.key("rt")); b.kv("id", id); b.kv("label", label); b.closeObj()

# Actions

proc button*(b: Builder, id, title, color: string, isDefault: bool = false) =
  b.obj(); b.kv("type", "BUTTON"); b.kv("key", b.key("btn")); b.kv("id", id); b.kv("title", title); b.kv("color", color)
  if isDefault: b.kvbool("default")
  b.closeObj()

# Shortcuts

proc section*(b: Builder, title, text: string) =
  b.fieldset(title); b.label(text); b.endFieldset()

proc feedbackForm*(b: Builder) =
  b.fieldset("Your Details")
  b.input("name", "Name", true)
  b.input("email", "Email", true)
  b.textarea("message", "Message", 5)
  b.endFieldset()
  b.button("send", "Send", "primary", true)
  b.button("cancel", "Cancel", "secondary")

// DynamicLayout Scala API — generate layout JSON from Scala code.
// Single-file. Zero dependencies outside stdlib. Works on Scala 2.13+ / 3.x.

package dynamiclayout

class Builder(private val sb: StringBuilder = new StringBuilder(), private var depth: Int = 0, private var comma: Boolean = false, private var cnt: Int = 0):
  private def putc(c: Char) = { sb.append(c); this }
  private def puts(s: String) = { sb.append(s); this }
  private def indent = { putc('\n'); (0 until depth).foreach(_ => puts("  ")); this }
  private def cm = { if comma then putc(',') else this; comma = false; this }
  private def esc(s: String) = { putc('"'); s.foreach { case '"' => puts("\\\""); case '\\' => puts("\\\\"); case '\n' => puts("\\n"); case c => putc(c) }; putc('"') }
  private def kv(k: String, v: String) = { cm; putc(','); indent; esc(k); puts(": "); esc(v); comma = true; this }
  private def kvint(k: String, v: Int) = { cm; putc(','); indent; esc(k); puts(s": $v"); comma = true; this }
  private def kvbool(k: String) = { cm; putc(','); indent; esc(k); puts(": true"); comma = true; this }
  private def obj = { cm; putc(','); indent; putc('{'); depth += 1; comma = false; this }
  private def closeObj = { depth -= 1; indent; putc('}'); comma = true; this }
  private def arr(k: String) = { cm; putc(','); indent; esc(k); puts(": ["); depth += 1; comma = false; this }
  private def closeArr = { depth -= 1; indent; putc(']'); comma = true; this }
  private def key(p: String) = { cnt += 1; s"${p}_$cnt" }

  def fieldset(title: String): Builder = { obj; kv("type", "FIELDSET"); kv("key", key("fs")); kv("title", title); arr("content") }
  def endFieldset: Builder = { closeArr; closeObj }
  def row: Builder = { obj; kv("type", "ROW"); kv("key", key("r")); arr("content") }
  def endRow: Builder = { closeArr; closeObj }
  def label(text: String): Builder = { obj; kv("type", "LABEL"); kv("key", key("l")); kv("label", text); closeObj }
  def alert(msg: String, color: String = "info"): Builder = { obj; kv("type", "ALERT"); kv("key", key("a")); kv("message", msg); kv("color", color); closeObj }
  def badge(title: String, color: String = "primary"): Builder = { obj; kv("type", "BADGE"); kv("key", key("bd")); kv("title", title); kv("color", color); closeObj }
  def spacer(px: Int = 20): Builder = { obj; kv("type", "SPACER"); kv("key", key("sp")); kvint("width", px); closeObj }
  def input(id: String, label: String, required: Boolean = false): Builder =
    val b = { obj; kv("type", "INPUT"); kv("key", key("i")); kv("id", id); kv("label", label) }
    if required then b.kvbool("required").closeObj else b.closeObj
  def checkbox(id: String, label: String = ""): Builder = { obj; kv("type", "CHECKBOX"); kv("key", key("cb")); kv("id", id); kv("label", label); closeObj }
  def textarea(id: String, label: String = "", rows: Int = 3): Builder =
    val b = { obj; kv("type", "TEXTAREA"); kv("key", key("ta")); kv("id", id); kv("label", label) }
    if rows > 0 then b.kvint("rows", rows).closeObj else b.closeObj
  def rating(id: String, label: String = ""): Builder = { obj; kv("type", "RATING"); kv("key", key("rt")); kv("id", id); kv("label", label); closeObj }
  def button(id: String, title: String, color: String = "primary", isDefault: Boolean = false): Builder =
    val b = { obj; kv("type", "BUTTON"); kv("key", key("btn")); kv("id", id); kv("title", title); kv("color", color) }
    if isDefault then b.kvbool("default").closeObj else b.closeObj
  def section(title: String, text: String): Builder = fieldset(title).label(text).endFieldset
  def result: String = sb.toString()

object Layout:
  def begin(title: String): Builder =
    val b = Builder()
    b.puts("{\"ui\":{"); b.depth = 2; b.comma = false
    b.kv("title", title); b.arr("layout")
  def end(b: Builder): String =
    b.closeArr; b.comma = false; b.putc(',')
    b.puts("\"translations\":{},")
    b.puts("\"userAccess\":{\"cancel\":true}")
    b.puts("}}"); b.result

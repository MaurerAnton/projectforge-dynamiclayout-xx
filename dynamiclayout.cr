# DynamicLayout Crystal API — generate layout JSON from Crystal code.
# Single-file. Zero dependencies outside stdlib. Works on Crystal 1.10+.
#
# Example:
#   require "./dynamiclayout"
#   b = DynamicLayout.begin("My Page")
#   b.fieldset("Info").label("Hello from Crystal!").end_fieldset
#   b.button("ok", "OK", "primary", is_default: true)
#   puts b.end

module DynamicLayout
  class Builder
    @buf = IO::Memory.new
    @depth = 0
    @comma = false
    @cnt = 0

    def self.begin(title : String) : Builder
      b = Builder.new
      b.puts("{\"ui\":{")
      b.@depth = 2; b.@comma = false
      b.kv("title", title)
      b.arr("layout")
      b
    end

    private def putc(c : Char) : self; @buf << c; self end
    private def puts(s : String) : self; @buf << s; self end
    private def indent : self; putc('\n'); @depth.times { puts("  ") }; self end
    private def cm : self; putc(',') if @comma; @comma = false; self end
    private def esc(s : String) : self
      putc('"')
      s.each_char do |c|
        case c
        when '"'  then puts("\\\"")
        when '\\' then puts("\\\\")
        when '\n' then puts("\\n")
        when '\r' then puts("\\r")
        when '\t' then puts("\\t")
        else putc(c)
        end
      end
      putc('"')
    end

    private def kv(k : String, v : String) : self
      cm; putc(','); indent; esc(k); puts(": "); esc(v); @comma = true; self
    end
    private def kvint(k : String, v : Int32) : self
      cm; putc(','); indent; esc(k); puts(": #{v}"); @comma = true; self
    end
    private def kvbool(k : String) : self
      cm; putc(','); indent; esc(k); puts(": true"); @comma = true; self
    end
    private def obj : self; cm; putc(','); indent; putc('{'); @depth += 1; @comma = false; self end
    private def co : self; @depth -= 1; indent; putc('}'); @comma = true; self end
    private def arr(k : String) : self; cm; putc(','); indent; esc(k); puts(": ["); @depth += 1; @comma = false; self end
    private def ca : self; @depth -= 1; indent; putc(']'); @comma = true; self end
    private def key(prefix : String) : String; @cnt += 1; "#{prefix}_#{@cnt}" end

    def fieldset(title : String) : self; obj; kv("type", "FIELDSET"); kv("key", key("fs")); kv("title", title); arr("content"); self end
    def end_fieldset : self; ca; co; self end
    def row : self; obj; kv("type", "ROW"); kv("key", key("r")); arr("content"); self end
    def end_row : self; ca; co; self end
    def label(text : String) : self; obj; kv("type", "LABEL"); kv("key", key("l")); kv("label", text); co; self end
    def alert(msg : String, color : String = "info") : self; obj; kv("type", "ALERT"); kv("key", key("a")); kv("message", msg); kv("color", color); co; self end
    def badge(title : String, color : String = "primary") : self; obj; kv("type", "BADGE"); kv("key", key("bd")); kv("title", title); kv("color", color); co; self end
    def spacer(px : Int32 = 20) : self; obj; kv("type", "SPACER"); kv("key", key("sp")); kvint("width", px); co; self end
    def input(id : String, label : String, required : Bool = false) : self
      obj; kv("type", "INPUT"); kv("key", key("i")); kv("id", id); kv("label", label)
      kvbool("required") if required; co; self
    end
    def checkbox(id : String, label : String = "") : self; obj; kv("type", "CHECKBOX"); kv("key", key("cb")); kv("id", id); kv("label", label); co; self end
    def textarea(id : String, label : String, rows : Int32 = 3) : self
      obj; kv("type", "TEXTAREA"); kv("key", key("ta")); kv("id", id); kv("label", label)
      kvint("rows", rows) if rows > 0; co; self
    end
    def rating(id : String, label : String = "") : self; obj; kv("type", "RATING"); kv("key", key("rt")); kv("id", id); kv("label", label); co; self end
    def button(id : String, title : String, color : String = "primary", is_default : Bool = false) : self
      obj; kv("type", "BUTTON"); kv("key", key("btn")); kv("id", id); kv("title", title); kv("color", color)
      kvbool("default") if is_default; co; self
    end

    def section(title : String, text : String) : self; fieldset(title).label(text).end_fieldset; self end

    def end : String
      ca; @comma = false; putc(','); puts("\"translations\":{},")
      puts("\"userAccess\":{\"cancel\":true}"); puts("}}")
      @buf.to_s
    end
  end
end

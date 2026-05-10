# DynamicLayout Julia API — generate layout JSON from Julia code.
# Single-file module. Zero dependencies outside Base Julia.
# Works on Julia 1.9+.
#
# Example:
#   include("dynamiclayout.jl")
#   b = dl_begin("My Page")
#   dl_fieldset(b, "Info")
#   dl_label(b, "Hello from Julia!")
#   dl_endfieldset(b)
#   dl_button(b, "ok", "OK", "primary", true)
#   println(dl_end(b))

module DynamicLayout

mutable struct Builder
    buf::IOBuffer
    depth::Int
    comma::Bool
    cnt::Int
end

export dl_begin, dl_end, dl_fieldset, dl_endfieldset, dl_label, dl_alert, dl_badge, dl_spacer
export dl_input, dl_checkbox, dl_textarea, dl_rating, dl_button, dl_section

function dl_begin(title::String)
    b = Builder(IOBuffer(), 0, false, 0)
    write(b.buf, "{\"ui\":{")
    b.depth = 2; b.comma = false
    dl_kv(b, "title", title)
    dl_arr(b, "layout")
    return b
end

function dl_end(b::Builder)
    dl_ca(b)
    b.comma = false; write(b.buf, ',')
    write(b.buf, "\"translations\":{},")
    write(b.buf, "\"userAccess\":{\"cancel\":true}")
    write(b.buf, "}}")
    return String(take!(b.buf))
end

dl_putc(b::Builder, c::Char) = (write(b.buf, c); b)
dl_puts(b::Builder, s::String) = (write(b.buf, s); b)
function dl_indent(b::Builder)
    write(b.buf, '\n')
    for _ in 1:b.depth write(b.buf, "  ") end
    b
end
function dl_cm(b::Builder)
    if b.comma write(b.buf, ',') end
    b.comma = false; b
end
function dl_esc(b::Builder, s::String)
    write(b.buf, '"')
    for c in s
        if c == '"' write(b.buf, "\\\"") elseif c == '\\' write(b.buf, "\\\\")
        elseif c == '\n' write(b.buf, "\\n") else write(b.buf, c) end
    end
    write(b.buf, '"'); b
end
function dl_kv(b::Builder, k::String, v::String)
    dl_cm(b); write(b.buf, ','); dl_indent(b); dl_esc(b, k); write(b.buf, ": "); dl_esc(b, v); b.comma = true; b
end
function dl_kvint(b::Builder, k::String, v::Int)
    dl_cm(b); write(b.buf, ','); dl_indent(b); dl_esc(b, k); write(b.buf, ": $v"); b.comma = true; b
end
function dl_kvbool(b::Builder, k::String)
    dl_cm(b); write(b.buf, ','); dl_indent(b); dl_esc(b, k); write(b.buf, ": true"); b.comma = true; b
end
function dl_obj(b::Builder)
    dl_cm(b); write(b.buf, ','); dl_indent(b); write(b.buf, '{'); b.depth += 1; b.comma = false; b
end
function dl_co(b::Builder)
    b.depth -= 1; dl_indent(b); write(b.buf, '}'); b.comma = true; b
end
function dl_arr(b::Builder, k::String)
    dl_cm(b); write(b.buf, ','); dl_indent(b); dl_esc(b, k); write(b.buf, ": ["); b.depth += 1; b.comma = false; b
end
function dl_ca(b::Builder)
    b.depth -= 1; dl_indent(b); write(b.buf, ']'); b.comma = true; b
end
function dl_key(b::Builder, p::String)
    b.cnt += 1; "$(p)_$(b.cnt)"
end

function dl_fieldset(b::Builder, title::String)
    k = dl_key(b, "fs"); dl_obj(b); dl_kv(b, "type", "FIELDSET"); dl_kv(b, "key", k); dl_kv(b, "title", title); dl_arr(b, "content"); b
end
dl_endfieldset(b::Builder) = (dl_ca(b); dl_co(b))
function dl_label(b::Builder, text::String)
    k = dl_key(b, "l"); dl_obj(b); dl_kv(b, "type", "LABEL"); dl_kv(b, "key", k); dl_kv(b, "label", text); dl_co(b)
end
function dl_alert(b::Builder, msg::String, color::String="info")
    k = dl_key(b, "a"); dl_obj(b); dl_kv(b, "type", "ALERT"); dl_kv(b, "key", k); dl_kv(b, "message", msg); dl_kv(b, "color", color); dl_co(b)
end
function dl_badge(b::Builder, title::String, color::String="primary")
    k = dl_key(b, "bd"); dl_obj(b); dl_kv(b, "type", "BADGE"); dl_kv(b, "key", k); dl_kv(b, "title", title); dl_kv(b, "color", color); dl_co(b)
end
dl_spacer(b::Builder, px::Int=20) = (k = dl_key(b, "sp"); dl_obj(b); dl_kv(b, "type", "SPACER"); dl_kv(b, "key", k); dl_kvint(b, "width", px); dl_co(b))
function dl_input(b::Builder, id::String, label::String, required::Bool=false)
    k = dl_key(b, "i"); dl_obj(b); dl_kv(b, "type", "INPUT"); dl_kv(b, "key", k); dl_kv(b, "id", id); dl_kv(b, "label", label)
    if required dl_kvbool(b, "required") end; dl_co(b)
end
function dl_checkbox(b::Builder, id::String, label::String="")
    k = dl_key(b, "cb"); dl_obj(b); dl_kv(b, "type", "CHECKBOX"); dl_kv(b, "key", k); dl_kv(b, "id", id); dl_kv(b, "label", label); dl_co(b)
end
function dl_textarea(b::Builder, id::String, label::String, rows::Int=3)
    k = dl_key(b, "ta"); dl_obj(b); dl_kv(b, "type", "TEXTAREA"); dl_kv(b, "key", k); dl_kv(b, "id", id); dl_kv(b, "label", label)
    if rows > 0 dl_kvint(b, "rows", rows) end; dl_co(b)
end
function dl_rating(b::Builder, id::String, label::String="")
    k = dl_key(b, "rt"); dl_obj(b); dl_kv(b, "type", "RATING"); dl_kv(b, "key", k); dl_kv(b, "id", id); dl_kv(b, "label", label); dl_co(b)
end
function dl_button(b::Builder, id::String, title::String, color::String, is_default::Bool=false)
    k = dl_key(b, "btn"); dl_obj(b); dl_kv(b, "type", "BUTTON"); dl_kv(b, "key", k); dl_kv(b, "id", id); dl_kv(b, "title", title); dl_kv(b, "color", color)
    if is_default dl_kvbool(b, "default") end; dl_co(b)
end
dl_section(b::Builder, title::String, text::String) = dl_endfieldset(dl_label(dl_fieldset(b, title), text))

end

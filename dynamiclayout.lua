-- DynamicLayout Lua API — generate layout JSON from Lua code.
--
-- Single-file. Zero dependencies outside Lua 5.1+ stdlib.
-- Works in Lua, LuaJIT, embedded (nginx, Redis, WoW, Roblox).
--
-- Example:
--   local dl = require("dynamiclayout")
--   local b = dl.begin("My Page")
--   b:fieldset("Info"):label("Hello from Lua!"):endfieldset()
--   b:button("ok", "OK", "primary", true)
--   print(b:_end())

local M = {}

-- Internal JSON builder (manual — zero deps)
local function escape(s) return (s:gsub('[\\"\n\r\t]', {
    ['\\'] = '\\\\', ['"'] = '\\"', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t'
})) end

local Builder = {}
Builder.__index = Builder

function M.begin(title)
    local b = setmetatable({
        _buf = {},
        _depth = 0,
        _comma = false,
        _counter = 0,
    }, Builder)
    b:_puts('{"ui":{')
    b._depth = 2; b._comma = false
    b:_kv("title", title)
    b:_arr("layout")
    return b
end

-- internal
function Builder:_put(c) table.insert(self._buf, c) end
function Builder:_puts(s) table.insert(self._buf, s) end
function Builder:_indent() self:_put('\n'); for _ = 1, self._depth do self:_puts('  ') end end
function Builder:_cm() if self._comma then self:_put(','); self._comma = false end end
function Builder:_kv(key, val)
    self:_cm(); self:_put(','); self:_indent()
    self:_put('"'); self:_puts(key); self:_puts('": "'); self:_puts(escape(val)); self:_put('"')
    self._comma = true
end
function Builder:_kvint(key, val)
    self:_cm(); self:_put(','); self:_indent()
    self:_put('"'); self:_puts(key); self:_puts('": '); self:_puts(tostring(val))
    self._comma = true
end
function Builder:_kvbool(key)
    self:_cm(); self:_put(','); self:_indent()
    self:_put('"'); self:_puts(key); self:_puts('": true')
    self._comma = true
end
function Builder:_obj()
    self:_cm(); self:_put(','); self:_indent()
    self:_put('{'); self._depth = self._depth + 1; self._comma = false
end
function Builder:_co()
    self._depth = self._depth - 1; self:_indent(); self:_put('}'); self._comma = true
end
function Builder:_arr(key)
    self:_cm(); self:_put(','); self:_indent()
    self:_put('"'); self:_puts(key); self:_puts('": [')
    self._depth = self._depth + 1; self._comma = false
end
function Builder:_ca()
    self._depth = self._depth - 1; self:_indent(); self:_put(']'); self._comma = true
end
function Builder:_key(prefix)
    self._counter = self._counter + 1
    return prefix .. '_' .. self._counter
end

-- Containers
function Builder:fieldset(title)
    self:_obj(); self:_kv("type", "FIELDSET"); self:_kv("key", self:_key("fs")); self:_kv("title", title); self:_arr("content")
    return self
end
function Builder:endfieldset() self:_ca(); self:_co(); return self end
function Builder:row() self:_obj(); self:_kv("type", "ROW"); self:_kv("key", self:_key("r")); self:_arr("content"); return self end
function Builder:endrow() self:_ca(); self:_co(); return self end

-- Display
function Builder:label(text) self:_obj(); self:_kv("type", "LABEL"); self:_kv("key", self:_key("l")); self:_kv("label", text); self:_co(); return self end
function Builder:alert(message, color) color = color or "info"
    self:_obj(); self:_kv("type", "ALERT"); self:_kv("key", self:_key("a")); self:_kv("message", message); self:_kv("color", color); self:_co(); return self
end
function Builder:badge(title, color) color = color or "primary"
    self:_obj(); self:_kv("type", "BADGE"); self:_kv("key", self:_key("bd")); self:_kv("title", title); self:_kv("color", color); self:_co(); return self
end
function Builder:spacer(px) px = px or 20
    self:_obj(); self:_kv("type", "SPACER"); self:_kv("key", self:_key("sp")); self:_kvint("width", px); self:_co(); return self
end

-- Inputs
function Builder:input(id, label, required, dataType)
    self:_obj(); self:_kv("type", "INPUT"); self:_kv("key", self:_key("i")); self:_kv("id", id); self:_kv("label", label or "")
    if required then self:_kvbool("required") end
    if dataType and dataType ~= "STRING" then self:_kv("dataType", dataType) end
    self:_co(); return self
end
function Builder:textarea(id, label, rows)
    self:_obj(); self:_kv("type", "TEXTAREA"); self:_kv("key", self:_key("ta")); self:_kv("id", id); self:_kv("label", label or "")
    if rows then self:_kvint("rows", rows) end
    self:_co(); return self
end
function Builder:checkbox(id, label)
    self:_obj(); self:_kv("type", "CHECKBOX"); self:_kv("key", self:_key("cb")); self:_kv("id", id); self:_kv("label", label or ""); self:_co(); return self
end
function Builder:select(id, label, pairs)
    self:_obj(); self:_kv("type", "SELECT"); self:_kv("key", self:_key("s")); self:_kv("id", id); self:_kv("label", label)
    self:_arr("values")
    for _, p in ipairs(pairs) do self:_obj(); self:_kv("id", p[1]); self:_kv("displayName", p[2]); self:_co() end
    self:_ca(); self:_co(); return self
end
function Builder:rating(id, label)
    self:_obj(); self:_kv("type", "RATING"); self:_kv("key", self:_key("rt")); self:_kv("id", id); self:_kv("label", label or ""); self:_co(); return self
end

-- Actions
function Builder:button(id, title, color, isDefault)
    self:_obj(); self:_kv("type", "BUTTON"); self:_kv("key", self:_key("btn")); self:_kv("id", id); self:_kv("title", title); self:_kv("color", color or "primary")
    if isDefault then self:_kvbool("default") end
    self:_co(); return self
end

-- Shortcuts
function Builder:section(title, text) self:fieldset(title):label(text):endfieldset(); return self end
function Builder:feedbackform()
    self:fieldset("Your Details")
        :input("name", "Name", true)
        :input("email", "Email", true)
        :textarea("message", "Message", 5)
        :endfieldset()
        :button("send", "Send", "primary", true)
        :button("cancel", "Cancel", "secondary")
    return self
end

-- Output
function Builder:_end()
    self:_ca() -- layout
    self._comma = false; self:_put(',')
    self:_puts('"translations":{},')
    self:_puts('"userAccess":{"cancel":true}')
    self:_puts('}}')
    self:_put('\0')
    return table.concat(self._buf):sub(1, -2) -- strip null terminator
end

return M

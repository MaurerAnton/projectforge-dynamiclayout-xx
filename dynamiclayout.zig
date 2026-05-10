// DynamicLayout Zig API — generate layout JSON from Zig code.
//
// Single-file module. Zero dependencies outside the standard library.
// Works on Zig 0.13+.
//
// Example:
//   const dl = @import("dynamiclayout.zig");
//   var b = try dl.begin(allocator, "My Page");
//   try b.fieldset("Info");
//   try b.label("Hello from Zig!");
//   try b.endFieldset();
//   try b.button("ok", "OK", "primary", true);
//   const json = try b.end();
//   defer allocator.free(json);

const std = @import("std");

const Allocator = std.mem.Allocator;

// ── Builder State ──

pub const Builder = struct {
    buf: std.ArrayList(u8),
    depth: usize = 0,
    comma: bool = false,
    counter: usize = 0,
    allocator: Allocator,

    const Self = @This();

    fn put(self: *Self, c: u8) !void { try self.buf.append(c); }
    fn puts(self: *Self, s: []const u8) !void { try self.buf.appendSlice(s); }

    fn indent(self: *Self) !void {
        try self.put('\n');
        var i: usize = 0;
        while (i < self.depth) : (i += 1) try self.puts("  ");
    }

    fn cm(self: *Self) !void {
        if (self.comma) try self.put(',');
        self.comma = false;
    }

    fn escape(self: *Self, s: []const u8) !void {
        try self.put('"');
        for (s) |c| {
            switch (c) {
                '"' => try self.puts("\\\""),
                '\\' => try self.puts("\\\\"),
                '\n' => try self.puts("\\n"),
                '\r' => try self.puts("\\r"),
                '\t' => try self.puts("\\t"),
                else => try self.put(c),
            }
        }
        try self.put('"');
    }

    fn kv(self: *Self, key: []const u8, val: []const u8) !void {
        try self.cm(); try self.put(','); try self.indent();
        try self.escape(key); try self.puts(": "); try self.escape(val);
        self.comma = true;
    }

    fn kvbool(self: *Self, key: []const u8) !void {
        try self.cm(); try self.put(','); try self.indent();
        try self.escape(key); try self.puts(": true");
        self.comma = true;
    }

    fn kvint(self: *Self, key: []const u8, val: usize) !void {
        var buf: [16]u8 = undefined;
        const s = try std.fmt.bufPrint(&buf, "{d}", .{val});
        try self.cm(); try self.put(','); try self.indent();
        try self.escape(key); try self.puts(": "); try self.puts(s);
        self.comma = true;
    }

    fn obj(self: *Self) !void {
        try self.cm(); try self.put(','); try self.indent();
        try self.put('{'); self.depth += 1; self.comma = false;
    }

    fn closeObj(self: *Self) !void {
        self.depth -= 1; try self.indent(); try self.put('}'); self.comma = true;
    }

    fn arr(self: *Self, key: []const u8) !void {
        try self.cm(); try self.put(','); try self.indent();
        try self.escape(key); try self.puts(": [");
        self.depth += 1; self.comma = false;
    }

    fn closeArr(self: *Self) !void {
        self.depth -= 1; try self.indent(); try self.put(']'); self.comma = true;
    }

    fn key(self: *Self, prefix: []const u8) ![]const u8 {
        self.counter += 1;
        return std.fmt.allocPrint(self.allocator, "{s}_{d}", .{ prefix, self.counter }) catch
            std.fmt.allocPrint(self.allocator, "el_{d}", .{self.counter}) catch "el";
    }

    // ── Public API ──

    pub fn begin(alloc: Allocator, title: []const u8) !Self {
        var b = Self{ .buf = std.ArrayList(u8).init(alloc), .allocator = alloc };
        try b.puts("{\"ui\":{");
        b.depth = 2; b.comma = false;
        try b.kv("title", title);
        try b.arr("layout");
        return b;
    }

    pub fn end(self: *Self) ![]u8 {
        try self.closeArr(); // layout
        self.comma = false; try self.put(',');
        try self.puts("\"translations\":{},");
        try self.puts("\"userAccess\":{\"cancel\":true}");
        try self.puts("}}"); // close ui + root
        try self.put('\x00');
        return self.buf.items[0 .. self.buf.items.len - 1];
    }

    pub fn deinit(self: *Self) void {
        self.buf.deinit();
    }

    // ── Containers ──

    pub fn fieldset(self: *Self, title: []const u8) !void {
        try self.obj();
        try self.kv("type", "FIELDSET");
        try self.kv("key", try self.key("fs"));
        try self.kv("title", title);
        try self.arr("content");
    }

    pub fn fieldsetCollapsed(self: *Self, title: []const u8) !void {
        try self.obj();
        try self.kv("type", "FIELDSET");
        try self.kv("key", try self.key("fs"));
        try self.kv("title", title);
        try self.kvbool("collapsed");
        try self.arr("content");
    }

    pub fn endFieldset(self: *Self) !void { try self.closeArr(); try self.closeObj(); }

    pub fn row(self: *Self) !void {
        try self.obj();
        try self.kv("type", "ROW");
        try self.kv("key", try self.key("r"));
        try self.arr("content");
    }
    pub fn endRow(self: *Self) !void { try self.closeArr(); try self.closeObj(); }

    pub fn col(self: *Self, xs: usize, md: usize) !void {
        try self.obj();
        try self.kv("type", "COL");
        try self.kv("key", try self.key("c"));
        if (xs > 0 or md > 0) {
            try self.cm(); try self.put(','); try self.indent();
            try self.puts("\"length\":{");
            if (xs > 0) { try self.puts("\"xs\":"); try self.kvint("", xs); }
            if (md > 0) { if (xs > 0) try self.put(','); try self.puts("\"md\":"); try self.kvint("", md); }
            try self.puts("}");
            self.comma = true;
        }
        try self.arr("content");
    }
    pub fn endCol(self: *Self) !void { try self.closeArr(); try self.closeObj(); }

    // ── Display ──

    pub fn label(self: *Self, text: []const u8) !void {
        try self.obj(); try self.kv("type", "LABEL");
        try self.kv("key", try self.key("l"));
        try self.kv("label", text);
        try self.closeObj();
    }

    pub fn alert(self: *Self, message: []const u8, color: []const u8) !void {
        try self.obj(); try self.kv("type", "ALERT");
        try self.kv("key", try self.key("a"));
        try self.kv("message", message);
        try self.kv("color", color);
        try self.closeObj();
    }

    pub fn badge(self: *Self, title: []const u8, color: []const u8) !void {
        try self.obj(); try self.kv("type", "BADGE");
        try self.kv("key", try self.key("bd"));
        try self.kv("title", title);
        try self.kv("color", color);
        try self.closeObj();
    }

    pub fn spacer(self: *Self, height: usize) !void {
        try self.obj(); try self.kv("type", "SPACER");
        try self.kv("key", try self.key("sp"));
        try self.kvint("width", height);
        try self.closeObj();
    }

    pub fn progress(self: *Self, label: []const u8, pct: usize, color: []const u8) !void {
        try self.obj(); try self.kv("type", "PROGRESS");
        try self.kv("key", try self.key("pr"));
        if (label.len > 0) try self.kv("label", label);
        try self.kvint("progress", pct);
        if (color.len > 0) try self.kv("color", color);
        try self.closeObj();
    }

    // ── Inputs ──

    pub fn input(self: *Self, id: []const u8, label_: []const u8) !void {
        try self.obj(); try self.kv("type", "INPUT");
        try self.kv("key", try self.key("i"));
        try self.kv("id", id);
        try self.kv("label", label_);
        try self.closeObj();
    }

    pub fn inputOpts(self: *Self, id: []const u8, label_: []const u8, dataType: []const u8, required: bool) !void {
        try self.obj(); try self.kv("type", "INPUT");
        try self.kv("key", try self.key("i"));
        try self.kv("id", id);
        try self.kv("label", label_);
        if (!std.mem.eql(u8, dataType, "STRING")) try self.kv("dataType", dataType);
        if (required) try self.kvbool("required");
        try self.closeObj();
    }

    pub fn textarea(self: *Self, id: []const u8, label_: []const u8, rows: usize) !void {
        try self.obj(); try self.kv("type", "TEXTAREA");
        try self.kv("key", try self.key("ta"));
        try self.kv("id", id);
        try self.kv("label", label_);
        if (rows > 0) try self.kvint("rows", rows);
        try self.closeObj();
    }

    pub fn checkbox(self: *Self, id: []const u8, label_: []const u8) !void {
        try self.obj(); try self.kv("type", "CHECKBOX");
        try self.kv("key", try self.key("cb"));
        try self.kv("id", id);
        try self.kv("label", label_);
        try self.closeObj();
    }

    pub fn select(self: *Self, id: []const u8, label_: []const u8, ids: []const []const u8, display_names: []const []const u8) !void {
        try self.obj(); try self.kv("type", "SELECT");
        try self.kv("key", try self.key("s"));
        try self.kv("id", id);
        try self.kv("label", label_);
        try self.arr("values");
        for (ids, 0..) |vid, i| {
            try self.obj();
            try self.kv("id", vid);
            try self.kv("displayName", display_names[i]);
            try self.closeObj();
        }
        try self.closeArr();
        try self.closeObj();
    }

    pub fn rating(self: *Self, id: []const u8, label_: []const u8) !void {
        try self.obj(); try self.kv("type", "RATING");
        try self.kv("key", try self.key("rt"));
        try self.kv("id", id);
        try self.kv("label", label_);
        try self.closeObj();
    }

    pub fn readonlyField(self: *Self, id: []const u8, label_: []const u8) !void {
        try self.obj(); try self.kv("type", "READONLY_FIELD");
        try self.kv("key", try self.key("ro"));
        try self.kv("id", id);
        try self.kv("label", label_);
        try self.closeObj();
    }

    // ── Actions ──

    pub fn button(self: *Self, id: []const u8, title: []const u8, color: []const u8, is_default: bool) !void {
        try self.obj(); try self.kv("type", "BUTTON");
        try self.kv("key", try self.key("btn"));
        try self.kv("id", id);
        try self.kv("title", title);
        try self.kv("color", color);
        if (is_default) try self.kvbool("default");
        try self.closeObj();
    }

    // ── Shortcuts ──

    pub fn section(self: *Self, title: []const u8, text: []const u8) !void {
        try self.fieldset(title);
        try self.label(text);
        try self.endFieldset();
    }

    pub fn feedbackForm(self: *Self) !void {
        try self.fieldset("Your Details");
        try self.input("name", "Name");
        try self.input("email", "Email");
        try self.textarea("message", "Message", 5);
        try self.endFieldset();
        try self.button("send", "Send", "primary", true);
        try self.button("cancel", "Cancel", "secondary", false);
    }
};

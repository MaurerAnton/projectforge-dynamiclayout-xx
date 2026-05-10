// DynamicLayout C# API — generate layout JSON from C# code.
//
// Single-file. Zero dependencies (System.Text.Json is built-in).
// Works on .NET 6+, .NET Framework 4.7.2+.
//
// Example:
//   var page = DL.Begin("My Page");
//   page.Fieldset("Info").Label("Hello from C#!").End();
//   page.Button("ok", "OK", Color.Primary, isDefault: true);
//   Console.WriteLine(page.End());

using System;
using System.Collections.Generic;
using System.Text.Json;

namespace DynamicLayout
{
    public enum Color { Primary = 0, Secondary, Success, Danger, Warning, Info }

    public enum DataType { STRING, INTEGER, LONG, BIG_DECIMAL, DATE, TIME, TIMESTAMP, BOOLEAN, PASSWORD }

    public class Length
    {
        public int? xs { get; set; } public int? sm { get; set; }
        public int? md { get; set; } public int? lg { get; set; } public int? xl { get; set; }
    }

    public class SelectValue
    {
        public object id { get; set; }
        public string displayName { get; set; }
        [System.Text.Json.Serialization.JsonIgnore(Condition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingDefault)]
        public int order { get; set; }
    }

    public class ResponseAction
    {
        public string type { get; set; }
        public string url { get; set; }
        public string method { get; set; }
        public string targetType { get; set; }
        public string targetUrl { get; set; }
        public string message { get; set; }
        public string color { get; set; }
    }

    public class Builder
    {
        private string _title, _uid;
        private List<Dictionary<string, object>> _layout = new();
        private List<Dictionary<string, object>> _actions = new();
        private Stack<List<Dictionary<string, object>>> _stack = new();
        private int _counter;

        private Builder(string title)
        {
            _title = title; _uid = $"layout_{Environment.TickCount64}";
            _stack.Push(_layout);
        }

        public static Builder Begin(string title) => new(title);
        public Builder UID(string uid) { _uid = uid; return this; }

        private string K(string p) => $"{p}_{++_counter}";
        private List<Dictionary<string, object>> Top => _stack.Peek();
        private Builder Add(Dictionary<string, object> el) { Top.Add(el); return this; }
        private Builder Push(Dictionary<string, object> el) { Add(el); var c = new List<Dictionary<string, object>>(); el["content"] = c; _stack.Push(c); return this; }
        private Builder Pop() { _stack.Pop(); return this; }

        // Containers
        public Builder Fieldset(string title) => Push(D("FIELDSET", K("fs"), ("title", title)));
        public Builder FieldsetCollapsed(string title) => Push(D("FIELDSET", K("fs"), ("title", title), ("collapsed", true)));
        public Builder End() => Pop();
        public Builder Row() => Push(D("ROW", K("r")));
        public Builder EndRow() => Pop();
        public Builder Col(int xs = 0, int md = 0, int lg = 0, int xl = 0)
        {
            var el = D("COL", K("c"));
            if (xs + md + lg + xl > 0) el["length"] = new Length { xs = xs > 0 ? xs : null, md = md > 0 ? md : null, lg = lg > 0 ? lg : null, xl = xl > 0 ? xl : null };
            return Push(el);
        }
        public Builder EndCol() => Pop();

        // Display
        public Builder Label(string text) => Add(D("LABEL", K("l"), ("label", text)));
        public Builder Alert(string message, string c = "info") => Add(D("ALERT", K("a"), ("message", message), ("color", c)));
        public Builder Badge(string title, string c = "primary") => Add(D("BADGE", K("bd"), ("title", title), ("color", c)));
        public Builder Spacer(int px) => Add(D("SPACER", K("sp"), ("width", px)));
        public Builder Progress(int pct, string label = null, string c = null)
        {
            var el = D("PROGRESS", K("pr"), ("progress", pct));
            if (label != null) el["label"] = label; if (c != null) el["color"] = c;
            return Add(el);
        }

        // Inputs
        public Builder Input(string id, string label = "", bool required = false, DataType? dt = null, int maxLength = 0)
        {
            var el = D("INPUT", K("i"), ("id", id), ("label", label));
            if (required) el["required"] = true;
            if (dt != null && dt != DataType.STRING) el["dataType"] = dt.ToString();
            if (maxLength > 0) el["maxLength"] = maxLength;
            return Add(el);
        }
        public Builder Textarea(string id, string label = "", int rows = 3) => Add(D("TEXTAREA", K("ta"), ("id", id), ("label", label), ("rows", rows)));
        public Builder Checkbox(string id, string label = "") => Add(D("CHECKBOX", K("cb"), ("id", id), ("label", label)));
        public Builder Select(string id, string label, params (object id, string name)[] options)
        {
            var vals = new List<SelectValue>();
            foreach (var o in options) vals.Add(new SelectValue { id = o.id, displayName = o.name });
            return Add(D("SELECT", K("s"), ("id", id), ("label", label), ("values", vals)));
        }
        public Builder Radio(string id, string label, params (object id, string name)[] options)
        {
            var vals = new List<SelectValue>();
            foreach (var o in options) vals.Add(new SelectValue { id = o.id, displayName = o.name });
            return Add(D("RADIOBUTTON", K("rb"), ("id", id), ("label", label), ("values", vals)));
        }
        public Builder Rating(string id, string label = "") => Add(D("RATING", K("rt"), ("id", id), ("label", label)));
        public Builder Readonly(string id, string label = "") => Add(D("READONLY_FIELD", K("ro"), ("id", id), ("label", label)));

        // Actions
        public Builder Button(string id, string title, string c = "primary", bool isDefault = false, ResponseAction action = null)
        {
            var el = D("BUTTON", K("btn"), ("id", id), ("title", title), ("color", c));
            if (isDefault) el["default"] = true;
            if (action != null) el["responseAction"] = action;
            _actions.Add(el); return this;
        }

        // Shortcuts
        public Builder Section(string title, string text) => Fieldset(title).Label(text).End();
        public Builder FeedbackForm() =>
            Fieldset("Your Details")
                .Input("name", "Name", required: true)
                .Input("email", "Email", required: true)
                .Textarea("message", "Message", 5).End()
                .Button("send", "Send", "primary", isDefault: true)
                .Button("cancel", "Cancel", "secondary");

        // Output
        public string EndLayout()
        {
            while (_stack.Count > 1) Pop();
            var obj = new { ui = new { title = _title, uid = _uid, layout = _layout, actions = _actions.Count > 0 ? _actions : null, translations = new Dictionary<string, string>(), userAccess = new { cancel = true } } };
            return JsonSerializer.Serialize(obj, new JsonSerializerOptions { WriteIndented = true });
        }

        private static Dictionary<string, object> D(string type, string key, params (string, object)[] fields)
        {
            var d = new Dictionary<string, object> { ["type"] = type, ["key"] = key };
            foreach (var (k, v) in fields) d[k] = v;
            return d;
        }
    }
}

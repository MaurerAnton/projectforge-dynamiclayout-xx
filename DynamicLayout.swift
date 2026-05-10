// DynamicLayout Swift API — generate layout JSON from Swift code.
//
// Single-file. Zero dependencies (Foundation is built-in).
// Works on Swift 5.5+, iOS 15+, macOS 12+.
//
// Example:
//   let page = Layout("My Page")
//   page.fieldset("Info").label("Hello from Swift!").endFieldset()
//   page.button("ok", "OK", "primary", isDefault: true)
//   print(page.end())

import Foundation

public class Layout {
    private var title: String
    private var uid: String
    private var layout: [[String: Any]] = []
    private var actions: [[String: Any]] = []
    private var stack: [[[String: Any]]] = []
    private var counter = 0

    public init(_ title: String) {
        self.title = title
        self.uid = "layout_\(Int(Date().timeIntervalSince1970 * 1000))"
        stack = [layout]
    }

    private func k(_ prefix: String) -> String { counter += 1; return "\(prefix)_\(counter)" }
    private var top: [[String: Any]] {
        get { stack[stack.count - 1] }
        set { stack[stack.count - 1] = newValue }
    }
    @discardableResult private func add(_ el: [String: Any]) -> Layout { top.append(el); return self }
    @discardableResult private func push(_ el: [String: Any]) -> Layout {
        var e = el; e["content"] = [[String: Any]](); add(e); stack.append(e["content"] as! [[String: Any]]); return self
    }
    @discardableResult private func pop() -> Layout { stack.removeLast(); return self }

    // Containers
    @discardableResult public func fieldset(_ title: String, collapsed: Bool? = nil) -> Layout {
        var el: [String: Any] = ["type": "FIELDSET", "key": k("fs"), "title": title]
        if let c = collapsed { el["collapsed"] = c }
        return push(el)
    }
    @discardableResult public func endFieldset() -> Layout { return pop() }
    @discardableResult public func row() -> Layout { return push(["type": "ROW", "key": k("r")]) }
    @discardableResult public func endRow() -> Layout { return pop() }
    @discardableResult public func col(xs: Int = 0, sm: Int = 0, md: Int = 0, lg: Int = 0, xl: Int = 0) -> Layout {
        var el: [String: Any] = ["type": "COL", "key": k("c")]
        var len = [String: Int]()
        if xs > 0 { len["xs"] = xs }; if sm > 0 { len["sm"] = sm }; if md > 0 { len["md"] = md }
        if lg > 0 { len["lg"] = lg }; if xl > 0 { len["xl"] = xl }
        if !len.isEmpty { el["length"] = len }
        return push(el)
    }
    @discardableResult public func endCol() -> Layout { return pop() }

    // Display
    @discardableResult public func label(_ text: String) -> Layout { return add(["type": "LABEL", "key": k("l"), "label": text]) }
    @discardableResult public func alert(_ message: String, color: String = "info") -> Layout { return add(["type": "ALERT", "key": k("a"), "message": message, "color": color]) }
    @discardableResult public func badge(_ title: String, color: String = "primary") -> Layout { return add(["type": "BADGE", "key": k("bd"), "title": title, "color": color]) }
    @discardableResult public func spacer(_ px: Int = 20) -> Layout { return add(["type": "SPACER", "key": k("sp"), "width": px]) }
    @discardableResult public func progress(_ pct: Int, label: String? = nil, color: String? = nil) -> Layout {
        var el: [String: Any] = ["type": "PROGRESS", "key": k("pr"), "progress": pct]
        if let l = label { el["label"] = l }; if let c = color { el["color"] = c }
        return add(el)
    }

    // Inputs
    @discardableResult public func input(_ id: String, label: String = "", required: Bool = false, dataType: String = "STRING") -> Layout {
        var el: [String: Any] = ["type": "INPUT", "key": k("i"), "id": id, "label": label]
        if required { el["required"] = true }; if dataType != "STRING" { el["dataType"] = dataType }
        return add(el)
    }
    @discardableResult public func textarea(_ id: String, label: String = "", rows: Int = 3) -> Layout { return add(["type": "TEXTAREA", "key": k("ta"), "id": id, "label": label, "rows": rows]) }
    @discardableResult public func checkbox(_ id: String, label: String = "") -> Layout { return add(["type": "CHECKBOX", "key": k("cb"), "id": id, "label": label]) }
    @discardableResult public func select(_ id: String, label: String, values: [(String, String)]) -> Layout {
        let vals = values.map { ["id": $0.0, "displayName": $0.1] as [String: Any] }
        return add(["type": "SELECT", "key": k("s"), "id": id, "label": label, "values": vals])
    }
    @discardableResult public func rating(_ id: String, label: String = "") -> Layout { return add(["type": "RATING", "key": k("rt"), "id": id, "label": label]) }
    @discardableResult public func readonly(_ id: String, label: String = "") -> Layout { return add(["type": "READONLY_FIELD", "key": k("ro"), "id": id, "label": label]) }

    // Actions
    @discardableResult public func button(_ id: String, _ title: String, _ color: String = "primary", isDefault: Bool = false) -> Layout {
        var el: [String: Any] = ["type": "BUTTON", "key": k("btn"), "id": id, "title": title, "color": color]
        if isDefault { el["default"] = true }
        actions.append(el); return self
    }

    // Shortcuts
    @discardableResult public func section(_ title: String, _ text: String) -> Layout { return fieldset(title).label(text).endFieldset() }
    @discardableResult public func feedbackForm() -> Layout {
        return fieldset("Your Details")
            .input("name", label: "Name", required: true)
            .input("email", label: "Email", required: true)
            .textarea("message", label: "Message", rows: 5)
            .endFieldset()
            .button("send", "Send", "primary", isDefault: true)
            .button("cancel", "Cancel", "secondary")
    }

    // Output
    public func end() -> String {
        while stack.count > 1 { pop() }
        var root: [String: Any] = ["title": title, "uid": uid, "layout": layout, "translations": [String: String](), "userAccess": ["cancel": true]]
        if !actions.isEmpty { root["actions"] = actions }
        let dict: [String: Any] = ["ui": root]
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
           let json = String(data: data, encoding: .utf8) { return json }
        return "{}"
    }
}

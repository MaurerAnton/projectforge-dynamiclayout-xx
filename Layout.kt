// DynamicLayout Kotlin standalone API — generate layout JSON from Kotlin code.
//
// Single-file. Zero dependencies outside Kotlin stdlib.
// Works on Kotlin 1.8+ (JVM, JS, Native via kotlinx.serialization optional).
//
// Example:
//   val page = Layout("My Page")
//   page.fieldset("Info") { label("Hello from Kotlin!") }
//   page.button("ok", "OK", "primary", isDefault = true)
//   println(page.json())

package dynamiclayout

import kotlin.collections.*

// Types
typealias El = MutableMap<String, Any?>

class Layout(private val title: String, private val uid: String = "layout_${System.currentTimeMillis()}") {
    private val layout = mutableListOf<El>()
    private val actions = mutableListOf<El>()
    private val stack = mutableListOf(layout)
    private var counter = 0

    private fun k(p: String) = "${p}_${++counter}"
    private fun top() = stack.last()
    private fun add(el: El): Layout { top().add(el); return this }

    private fun push(el: El): Layout {
        val content = mutableListOf<El>()
        el["content"] = content; add(el); stack.add(content); return this
    }

    private fun pop(): Layout { stack.removeLast(); return this }

    // Containers
    fun fieldset(title: String, collapsed: Boolean? = null, block: Layout.() -> Unit = {}): Layout {
        val el = mutableMapOf<String, Any?>("type" to "FIELDSET", "key" to k("fs"), "title" to title)
        if (collapsed != null) el["collapsed"] = collapsed
        push(el); block(); pop(); return this
    }

    fun row(block: Layout.() -> Unit): Layout {
        push(mutableMapOf("type" to "ROW", "key" to k("r"))); block(); pop(); return this
    }

    fun col(xs: Int = 0, sm: Int = 0, md: Int = 0, lg: Int = 0, xl: Int = 0, block: Layout.() -> Unit = {}): Layout {
        val el = mutableMapOf<String, Any?>("type" to "COL", "key" to k("c"))
        val len = mutableMapOf<String, Int>()
        if (xs > 0) len["xs"] = xs; if (sm > 0) len["sm"] = sm; if (md > 0) len["md"] = md
        if (lg > 0) len["lg"] = lg; if (xl > 0) len["xl"] = xl
        if (len.isNotEmpty()) el["length"] = len
        push(el); block(); pop(); return this
    }

    fun inline(block: Layout.() -> Unit): Layout {
        push(mutableMapOf("type" to "INLINE_GROUP", "key" to k("ig"))); block(); pop(); return this
    }

    // Display
    fun label(text: String): Layout = add(mutableMapOf("type" to "LABEL", "key" to k("l"), "label" to text))
    fun alert(message: String, color: String = "info"): Layout = add(mutableMapOf("type" to "ALERT", "key" to k("a"), "message" to message, "color" to color))
    fun badge(title: String, color: String = "primary"): Layout = add(mutableMapOf("type" to "BADGE", "key" to k("bd"), "title" to title, "color" to color))
    fun spacer(px: Int = 20): Layout = add(mutableMapOf("type" to "SPACER", "key" to k("sp"), "width" to px))
    fun progress(pct: Int, label: String? = null, color: String? = null): Layout {
        val el = mutableMapOf<String, Any?>("type" to "PROGRESS", "key" to k("pr"), "progress" to pct)
        label?.let { el["label"] = it }; color?.let { el["color"] = it }
        return add(el)
    }

    // Inputs
    fun input(id: String, label: String = "", required: Boolean = false, dataType: String = "STRING", maxLength: Int = 0): Layout {
        val el = mutableMapOf<String, Any?>("type" to "INPUT", "key" to k("i"), "id" to id, "label" to label)
        if (required) el["required"] = true
        if (dataType != "STRING") el["dataType"] = dataType
        if (maxLength > 0) el["maxLength"] = maxLength
        return add(el)
    }
    fun textarea(id: String, label: String = "", rows: Int = 3): Layout = add(mutableMapOf("type" to "TEXTAREA", "key" to k("ta"), "id" to id, "label" to label, "rows" to rows))
    fun checkbox(id: String, label: String = ""): Layout = add(mutableMapOf("type" to "CHECKBOX", "key" to k("cb"), "id" to id, "label" to label))
    fun select(id: String, label: String, vararg pairs: Pair<String, String>): Layout {
        val vals = pairs.map { mapOf("id" to it.first, "displayName" to it.second) }
        return add(mutableMapOf("type" to "SELECT", "key" to k("s"), "id" to id, "label" to label, "values" to vals))
    }
    fun radio(id: String, label: String, vararg pairs: Pair<String, String>): Layout {
        val vals = pairs.map { mapOf("id" to it.first, "displayName" to it.second) }
        return add(mutableMapOf("type" to "RADIOBUTTON", "key" to k("rb"), "id" to id, "label" to label, "values" to vals))
    }
    fun rating(id: String, label: String = ""): Layout = add(mutableMapOf("type" to "RATING", "key" to k("rt"), "id" to id, "label" to label))
    fun readonly(id: String, label: String = ""): Layout = add(mutableMapOf("type" to "READONLY_FIELD", "key" to k("ro"), "id" to id, "label" to label))

    // Actions
    fun button(id: String, title: String, color: String = "primary", isDefault: Boolean = false): Layout {
        val el = mutableMapOf<String, Any?>("type" to "BUTTON", "key" to k("btn"), "id" to id, "title" to title, "color" to color)
        if (isDefault) el["default"] = true
        actions.add(el); return this
    }

    // Shortcuts
    fun section(title: String, text: String): Layout = fieldset(title) { label(text) }
    fun feedbackForm(): Layout {
        fieldset("Your Details") {
            input("name", "Name", required = true)
            input("email", "Email", required = true)
            textarea("message", "Message", 5)
        }
        button("send", "Send", "primary", isDefault = true)
        button("cancel", "Cancel", "secondary")
        return this
    }

    // Output
    fun toMap(): Map<String, Any?> {
        while (stack.size > 1) pop()
        val ui = mutableMapOf<String, Any?>(
            "title" to title, "uid" to uid, "layout" to layout,
            "translations" to emptyMap<String, String>(), "userAccess" to mapOf("cancel" to true)
        )
        if (actions.isNotEmpty()) ui["actions"] = actions
        return mapOf("ui" to ui)
    }

    fun json(): String {
        val sb = StringBuilder()
        appendMap(sb, 0, toMap())
        return sb.toString()
    }

    private fun appendMap(sb: StringBuilder, indent: Int, map: Map<String, Any?>) {
        sb.append("{\n")
        val entries = map.entries.toList()
        entries.forEachIndexed { i, (k, v) ->
            sb.append("  ".repeat(indent + 1))
            sb.append("\"$k\": ")
            appendVal(sb, indent + 1, v)
            if (i < entries.size - 1) sb.append(',')
            sb.append('\n')
        }
        sb.append("  ".repeat(indent)); sb.append('}')
    }

    private fun appendVal(sb: StringBuilder, indent: Int, v: Any?) {
        when (v) {
            null -> sb.append("null")
            is String -> {
                sb.append('"')
                sb.append(v.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n"))
                sb.append('"')
            }
            is Number -> sb.append(v)
            is Boolean -> sb.append(v)
            is Map<*, *> -> @Suppress("UNCHECKED_CAST") appendMap(sb, indent, v as Map<String, Any?>)
            is List<*> -> {
                sb.append('[')
                v.forEachIndexed { i, item ->
                    if (i > 0) sb.append(", ")
                    appendVal(sb, indent, item)
                }
                sb.append(']')
            }
            else -> sb.append('"').append(v.toString()).append('"')
        }
    }
}

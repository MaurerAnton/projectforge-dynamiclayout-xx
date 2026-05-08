package org.dynamiclayout.core.json

import org.dynamiclayout.core.FormLayoutData
import org.dynamiclayout.core.ui.*

/**
 * JSON serialization for DynamicLayout.
 * Builds JSON manually to avoid polymorphism issues with kotlinx.serialisation
 * (UIElement subclasses have open inheritance with type discriminator).
 */
object DynamicLayoutJson {
    fun encode(layout: UILayout): String {
        val sb = StringBuilder()
        appendObject(layout.toMap(), sb)
        return sb.toString()
    }

    fun encodeFormData(data: FormLayoutData): String {
        val sb = StringBuilder()
        val map = mutableMapOf<String, Any?>(
            "data" to data.data,
            "ui" to data.ui?.toMap(),
        )
        appendObject(map.filterValues { it != null }, sb)
        return sb.toString()
    }

    private fun UILayout.toMap(): Map<String, Any?> {
        return mutableMapOf<String, Any?>(
            "title" to title,
            "uid" to uid,
            "translations" to translations,
            "userAccess" to mapOf(
                "cancel" to userAccess.cancel,
            ),
            "layout" to layout.map { it.toElementMap() },
        ).apply {
            if (actions.isNotEmpty()) put("actions", actions.map { it.toElementMap() })
            if (layoutBelowActions.isNotEmpty()) put("layoutBelowActions", layoutBelowActions.map { it.toElementMap() })
            if (namedContainers.isNotEmpty()) put("namedContainers", namedContainers.map { it.toElementMap() })
            userAccess.history?.let { put("showHistory", it) }
            userAccess.insert?.let { (this["userAccess"] as MutableMap<String, Any?>)["insert"] = it }
            userAccess.update?.let { (this["userAccess"] as MutableMap<String, Any?>)["update"] = it }
            userAccess.delete?.let { (this["userAccess"] as MutableMap<String, Any?>)["delete"] = it }
        }
    }

    private fun UIElement.toElementMap(): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>(
            "type" to elementType.name,
            "key" to key,
        )
        cssClass?.let { map["cssClass"] = it }

        when (this) {
            is UIRow -> map["content"] = content.map { it.toElementMap() }
            is UICol -> {
                length?.let { map["length"] = it.toMap() }
                offset?.let { map["offset"] = it.toMap() }
                map["content"] = content.map { it.toElementMap() }
                collapseTitle?.let { map["collapseTitle"] = it }
            }
            is UIFieldset -> {
                title?.let { map["title"] = it }
                collapsed?.let { map["collapsed"] = it }
                map["content"] = content.map { it.toElementMap() }
            }
            is UIGroup -> map["content"] = content.map { it.toElementMap() }
            is UIInlineGroup -> map["content"] = content.map { it.toElementMap() }
            is UILabel -> {
                label?.let { map["label"] = it }
                tooltip?.let { map["tooltip"] = it }
            }
            is UIInput -> {
                map["id"] = id
                label?.let { map["label"] = it }
                map["dataType"] = dataType.name
                required?.let { map["required"] = it }
                maxLength?.let { map["maxLength"] = it }
                focus?.let { map["focus"] = it }
                tooltip?.let { map["tooltip"] = it }
            }
            is UITextArea -> {
                map["id"] = id; label?.let { map["label"] = it }
                rows?.let { map["rows"] = it }; maxLength?.let { map["maxLength"] = it }
            }
            is UICheckbox -> {
                map["id"] = id; label?.let { map["label"] = it }
            }
            is UISelect<*> -> {
                map["id"] = id; label?.let { map["label"] = it }
                required?.let { map["required"] = it }
                values?.let { map["values"] = it.map { v -> mapOf("id" to v.id, "displayName" to v.displayName) } }
            }
            is UIButton -> {
                map["id"] = id; title?.let { map["title"] = it }
                color?.let { map["color"] = it }; default?.let { map["default"] = it }
            }
            is UIAlert -> {
                message?.let { map["message"] = it }
                title?.let { map["title"] = it }
                color?.let { map["color"] = it }
            }
            is UIList -> {
                map["listId"] = listId
                map["elementVar"] = elementVar
                content.let { map["content"] = it.map { e -> e.toElementMap() } }
                positionLabel?.let { map["positionLabel"] = it }
            }
            is UINamedContainer -> {
                map["id"] = id; map["content"] = content.map { it.toElementMap() }
            }
            is UIDropArea -> {
                title?.let { map["title"] = it }
                map["uploadUrl"] = uploadUrl
                tooltip?.let { map["tooltip"] = it }
            }
            is UIEditor -> {
                map["id"] = id; map["mode"] = mode
                height?.let { map["height"] = it }
            }
            is UIBadge -> {
                title?.let { map["title"] = it }
                color?.let { map["color"] = it }
            }
            is UIProgress -> {
                map["id"] = id; title?.let { map["title"] = it }
                value?.let { map["value"] = it }
                color?.let { map["color"] = it }
            }
            is UISpacer -> width?.let { map["width"] = it }
        }
        return map
    }

    private fun UILength.toMap(): Map<String, Int?> = mutableMapOf<String, Int?>(
        "xs" to xs, "sm" to sm, "md" to md, "lg" to lg, "xl" to xl
    ).filterValues { it != null }.mapValues { it.value!! }

    @Suppress("UNCHECKED_CAST")
    private fun appendObject(obj: Map<String, Any?>, sb: StringBuilder) {
        sb.append('{')
        var first = true
        for ((key, value) in obj) {
            if (!first) sb.append(',')
            first = false
            sb.append('"'); appendString(key, sb); sb.append('"')
            sb.append(':')
            appendValue(value, sb)
        }
        sb.append('}')
    }

    private fun appendValue(value: Any?, sb: StringBuilder) {
        when (value) {
            null -> sb.append("null")
            is Boolean -> sb.append(if (value) "true" else "false")
            is Number -> sb.append(value.toString())
            is String -> { sb.append('"'); appendString(value, sb); sb.append('"') }
            is Map<*, *> -> appendObject(value as Map<String, Any?>, sb)
            is List<*> -> {
                sb.append('[')
                var first = true
                for (item in value) {
                    if (!first) sb.append(',')
                    first = false
                    appendValue(item, sb)
                }
                sb.append(']')
            }
            else -> { sb.append('"'); appendString(value.toString(), sb); sb.append('"') }
        }
    }

    private fun appendString(s: String, sb: StringBuilder) {
        for (c in s) when (c) {
            '"' -> sb.append("\\\"")
            '\\' -> sb.append("\\\\")
            '\n' -> sb.append("\\n")
            '\r' -> sb.append("\\r")
            '\t' -> sb.append("\\t")
            else -> sb.append(c)
        }
    }
}

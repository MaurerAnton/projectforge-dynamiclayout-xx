package org.dynamiclayout.core.util

import org.dynamiclayout.core.provider.I18nProvider
import org.dynamiclayout.core.provider.addTranslations
import org.dynamiclayout.core.ui.*

/**
 * Post-processes a UILayout: assigns element keys, translates labels, adds common translations.
 * This is the extracted version without Spring/JPA dependencies.
 * Accepts an I18nProvider for all translation needs.
 */
object LayoutUtils {

    private var counter = 0
    private var ncCounter = 0

    fun process(layout: UILayout, i18n: I18nProvider) {
        counter = 0
        ncCounter = 0

        addCommonTranslations(layout.translations, i18n)
        processAllElements(layout, i18n)

        layout.namedContainers.forEach { container ->
            container.key = "nc-${++ncCounter}"
        }
    }

    private fun addCommonTranslations(translations: MutableMap<String, String>, i18n: I18nProvider) {
        i18n.addTranslations(translations, "calendar.today", "cancel", "finish", "save", "select.placeholder", "yes")
    }

    private fun processAllElements(layout: UILayout, i18n: I18nProvider) {
        val elements = getAllElements(layout)
        elements.forEach { element ->
            if (element is UIElement) {
                element.key = "el-${++counter}"
            }
            processElement(element, i18n)
        }
    }

    private fun processElement(element: UIElement, i18n: I18nProvider) {
        when (element) {
            is UIFieldset -> {
                element.title = translateLabel(element.title, i18n)
            }
            is UIAlert -> {
                element.title = translateLabel(element.title, i18n)
                element.message = translateLabel(element.message, i18n)
            }
            is UIButton -> {
                if (element.title == null) {
                    element.title = autoButtonTitle(element.id, i18n)
                } else {
                    element.title = translateLabel(element.title, i18n)
                }
                element.tooltip = translateLabel(element.tooltip, i18n)
            }
            is UILabel -> {
                element.label = translateLabel(element.label, i18n)
                element.tooltip = translateLabel(element.tooltip, i18n)
            }
            is UILabelledElement -> {
                val labelled = element as UILabelledElement
                labelled.label = translateLabel(labelled.label, i18n)
                labelled.additionalLabel = translateLabel(labelled.additionalLabel, i18n)
                labelled.tooltip = translateLabel(labelled.tooltip, i18n)
            }
            is UITableColumn -> {
                element.title = translateLabel(element.title, i18n)
                element.tooltip = translateLabel(element.tooltip, i18n)
            }
            is UIAgGridColumnDef -> {
                element.headerName = translateLabel(element.headerName, i18n)
                element.headerTooltip = translateLabel(element.headerTooltip, i18n)
            }
            is UIDropArea -> {
                element.title = translateLabel(element.title, i18n)
                element.tooltip = translateLabel(element.tooltip, i18n)
            }
            is UIList -> {
                element.positionLabel = translateLabel(element.positionLabel, i18n)
            }
        }
    }

    private fun translateLabel(label: String?, i18n: I18nProvider): String? {
        if (label == null) return null
        if (label.startsWith("'")) return label.removePrefix("'")
        return i18n.translate(label)
    }

    private fun autoButtonTitle(id: String, i18n: I18nProvider): String {
        val key = when (id) {
            "cancel" -> "cancel"
            "clone" -> "clone"
            "create" -> "create"
            "deleteIt" -> "delete"
            "forceDelete" -> "forceDelete"
            "markAsDeleted" -> "markAsDeleted"
            "reset" -> "reset"
            "save", "update" -> "save"
            "search" -> "search"
            "undelete" -> "undelete"
            else -> id
        }
        return i18n.translate(key)
    }

    private fun getAllElements(layout: UILayout): List<UIElement> {
        val result = mutableListOf<UIElement>()
        result.addAll(layout.layout)
        result.addAll(layout.layoutBelowActions)
        result.addAll(layout.actions)
        layout.namedContainers.forEach { container ->
            result.addAll(container.content)
        }
        addNestedElements(result, layout.layout)
        addNestedElements(result, layout.layoutBelowActions)
        return result
    }

    private fun addNestedElements(result: MutableList<UIElement>, elements: List<UIElement>) {
        elements.forEach { element ->
            val content = getContent(element)
            if (content != null) {
                result.addAll(content)
                addNestedElements(result, content)
            }
            when (element) {
                is UISelect<*> -> {
                    element.favorites?.let { result.add(element) }
                }
                is UITable -> {
                    result.addAll(element.columns)
                }
                is UIAgGrid -> {
                    // UIAgGridColumnDef is not a UIElement, skip
                }
                is UIList -> {
                    result.addAll(element.content)
                    addNestedElements(result, element.content)
                }
            }
        }
    }

    private fun getContent(element: UIElement): List<UIElement>? {
        return when (element) {
            is UIRow -> element.content
            is UICol -> element.content
            is UIGroup -> element.content
            is UIInlineGroup -> element.content
            is UIFieldset -> element.content
            is UINamedContainer -> element.content
            else -> null
        }
    }
}

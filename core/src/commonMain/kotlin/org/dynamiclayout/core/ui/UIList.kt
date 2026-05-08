package org.dynamiclayout.core.ui
data class UIList(
    var listId: String = "",
    var elementVar: String = "",
    var content: MutableList<UIElement> = mutableListOf(),
    var positionLabel: String? = "label.position.short",
) : UIElement(UIElementType.LIST) {
    fun add(element: UIElement): UIList {
        content.add(element)
        return this
    }
}

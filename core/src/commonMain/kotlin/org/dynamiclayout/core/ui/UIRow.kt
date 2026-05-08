package org.dynamiclayout.core.ui
data class UIRow(
    val content: MutableList<UIElement> = mutableListOf(),
) : UIElement(UIElementType.ROW), IUIContainer {
    override fun add(el: UIElement): IUIContainer {
        content.add(el)
        return this
    }
}

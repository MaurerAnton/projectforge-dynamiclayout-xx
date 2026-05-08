package org.dynamiclayout.core.ui
data class UIGroup(
    val content: MutableList<UIElement> = mutableListOf(),
) : UIElement(UIElementType.GROUP), IUIContainer {
    override fun add(el: UIElement): IUIContainer {
        content.add(el)
        return this
    }
}

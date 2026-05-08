package org.dynamiclayout.core.ui
data class UIInlineGroup(
    val content: MutableList<UIElement> = mutableListOf(),
) : UIElement(UIElementType.INLINE_GROUP), IUIContainer {
    override fun add(el: UIElement): IUIContainer {
        content.add(el)
        return this
    }
}

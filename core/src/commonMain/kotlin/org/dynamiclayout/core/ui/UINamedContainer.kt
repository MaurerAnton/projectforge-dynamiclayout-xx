package org.dynamiclayout.core.ui
data class UINamedContainer(
    override var id: String,
    val content: MutableList<UIElement> = mutableListOf(),
) : UIElement(UIElementType.NAMED_CONTAINER), IUIId, IUIContainer {
    override fun add(el: UIElement): IUIContainer {
        content.add(el)
        return this
    }
}

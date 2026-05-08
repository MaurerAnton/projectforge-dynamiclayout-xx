package org.dynamiclayout.core.ui
open class UICol(
    var length: UILength? = null,
    var offset: UILength? = null,
    val content: MutableList<UIElement> = mutableListOf(),
    var collapseTitle: String? = null,
    elementType: UIElementType = UIElementType.COL,
) : UIElement(elementType), IUIContainer {
    constructor(vararg lengths: Int) : this(
        length = UILength(xs = lengths.getOrNull(0), sm = lengths.getOrNull(1),
            md = lengths.getOrNull(2), lg = lengths.getOrNull(3), xl = lengths.getOrNull(4))
    )
    override fun add(el: UIElement): IUIContainer {
        content.add(el)
        return this
    }
}

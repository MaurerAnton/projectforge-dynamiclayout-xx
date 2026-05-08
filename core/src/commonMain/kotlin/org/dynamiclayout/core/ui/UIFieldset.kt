package org.dynamiclayout.core.ui
class UIFieldset(
    var title: String? = null,
    var collapsed: Boolean? = null,
    length: UILength? = null,
    offset: UILength? = null,
    content: MutableList<UIElement> = mutableListOf()
) : UICol(length = length, offset = offset, content = content,
    elementType = UIElementType.FIELDSET)

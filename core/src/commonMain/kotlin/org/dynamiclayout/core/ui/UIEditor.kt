package org.dynamiclayout.core.ui
class UIEditor(
    override var id: String,
    var mode: String = "kotlin",
    var height: String? = null,
) : UIElement(UIElementType.EDITOR), IUIId

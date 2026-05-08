package org.dynamiclayout.core.ui
data class UICustomized(
    override var id: String,
    var values: MutableMap<String, Any>? = null,
) : UIElement(UIElementType.CUSTOMIZED), IUIId

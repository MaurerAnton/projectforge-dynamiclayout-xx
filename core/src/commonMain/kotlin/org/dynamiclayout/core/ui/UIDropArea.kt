package org.dynamiclayout.core.ui
data class UIDropArea(
    var title: String? = null,
    var uploadUrl: String = "",
    override var tooltip: String? = null,
    override var id: String = "dropArea",
) : UIElement(UIElementType.DROP_AREA), UILabelledElement, IUIId {
    override var label: String? = null
    override var additionalLabel: String? = null
}

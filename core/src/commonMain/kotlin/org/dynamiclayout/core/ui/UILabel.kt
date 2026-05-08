package org.dynamiclayout.core.ui
data class UILabel(
    override var label: String? = null,
    var labelFor: String? = null,
    override var additionalLabel: String? = null,
    override var tooltip: String? = null,
    var dataType: UIDataType? = null,
) : UIElement(UIElementType.LABEL), UILabelledElement

package org.dynamiclayout.core.ui
data class UIReadOnlyField(
    var id: String? = null,
    var dataType: UIDataType = UIDataType.STRING,
    override var label: String? = null,
    override var additionalLabel: String? = null,
    override var tooltip: String? = null,
    var canCopy: Boolean? = null,
    var coverUp: Boolean? = null,
    var value: String? = null,
) : UIElement(UIElementType.READONLY_FIELD), UILabelledElement

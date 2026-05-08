package org.dynamiclayout.core.ui
data class UITextArea(
    override var id: String,
    var maxLength: Int? = null,
    var rows: Int? = 3,
    var maxRows: Int? = 10,
    override var label: String? = null,
    override var additionalLabel: String? = null,
    override var tooltip: String? = null,
) : UIElement(UIElementType.TEXTAREA), UILabelledElement, IUIId

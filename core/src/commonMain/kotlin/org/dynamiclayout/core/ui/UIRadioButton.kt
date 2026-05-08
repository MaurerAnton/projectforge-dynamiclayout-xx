package org.dynamiclayout.core.ui
data class UIRadioButton(
    override var id: String,
    var value: Any? = null,
    var name: String? = null,
    override var label: String? = null,
    override var additionalLabel: String? = null,
    override var tooltip: String? = null,
) : UIElement(UIElementType.RADIOBUTTON), UILabelledElement, IUIId

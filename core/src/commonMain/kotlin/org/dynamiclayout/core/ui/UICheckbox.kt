package org.dynamiclayout.core.ui
data class UICheckbox(
    override var id: String,
    var color: String? = null,
    var inline: Boolean = false,
    override var label: String? = null,
    override var additionalLabel: String? = null,
    override var tooltip: String? = null,
) : UIElement(UIElementType.CHECKBOX), UILabelledElement, IUIId

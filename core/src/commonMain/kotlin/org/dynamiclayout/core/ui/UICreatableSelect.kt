package org.dynamiclayout.core.ui
data class UICreatableSelect(
    override var id: String,
    override var label: String? = null,
    override var additionalLabel: String? = null,
    override var tooltip: String? = null,
    var required: Boolean? = null,
) : UIElement(UIElementType.CREATABLE_SELECT), UILabelledElement, IUIId

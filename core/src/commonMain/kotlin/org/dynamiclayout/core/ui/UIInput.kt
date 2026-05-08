package org.dynamiclayout.core.ui
data class UIInput(
    override var id: String,
    var maxLength: Int? = null,
    var required: Boolean? = null,
    var focus: Boolean? = null,
    var color: String? = null,
    var dataType: UIDataType = UIDataType.STRING,
    override var label: String? = null,
    override var additionalLabel: String? = null,
    override var tooltip: String? = null,
    var autoComplete: String? = null,
    var inputMode: String? = null,
    var pattern: String? = null,
    var autoCompletionUrl: String? = null,
    var autoCompletionUrlParams: Map<String, String>? = null,
) : UIElement(UIElementType.INPUT), UILabelledElement, IUIId

package org.dynamiclayout.core.ui
class UISelect<T>(
    override var id: String,
    var values: List<UISelectValue<T>>? = null,
    var required: Boolean? = null,
    var multi: Boolean? = null,
    override var label: String? = null,
    override var additionalLabel: String? = null,
    override var tooltip: String? = null,
    var valueProperty: String = "id",
    var labelProperty: String = "displayName",
    var favorites: List<Favorite<T>>? = null,
    var autoCompletion: AutoCompletion? = null,
) : UIElement(UIElementType.SELECT), UILabelledElement, IUIId {
    data class Favorite<T>(
        val id: T,
        val name: String
    )
    data class AutoCompletion(
        var type: String? = null,
        var url: String? = null,
        var urlParams: Map<String, String>? = null,
        var minChars: Int? = 2,
        var values: List<AutoCompletionEntry>? = null
    )
    data class AutoCompletionEntry(
        val value: Any?,
        val label: String,
        var allSearchableFields: String? = null
    )
}

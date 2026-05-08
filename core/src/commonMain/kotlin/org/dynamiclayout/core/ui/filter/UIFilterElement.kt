package org.dynamiclayout.core.ui.filter
import org.dynamiclayout.core.ui.*
open class UIFilterElement(
    override var id: String = "",
    var filterType: FilterType? = null,
    override var label: String? = null,
    override var additionalLabel: String? = null,
    override var tooltip: String? = null,
    var defaultFilter: Boolean? = null,
) : UIElement(UIElementType.FILTER_ELEMENT), UILabelledElement, IUIId {
    enum class FilterType {
        STRING, DATE, TIMESTAMP, BOOLEAN, OBJECT, LIST
    }
}

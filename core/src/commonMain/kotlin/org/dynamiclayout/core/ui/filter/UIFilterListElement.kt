package org.dynamiclayout.core.ui.filter
import org.dynamiclayout.core.ui.UISelectValue
class UIFilterListElement(
    override var id: String = "",
    var values: List<UISelectValue<String>>? = null,
    var multi: Boolean? = true,
    label: String? = null,
    additionalLabel: String? = null,
    tooltip: String? = null,
    defaultFilter: Boolean? = null
) : UIFilterElement(id = id, filterType = FilterType.LIST, label = label,
    additionalLabel = additionalLabel, tooltip = tooltip, defaultFilter = defaultFilter)

package org.dynamiclayout.core.ui.filter
import org.dynamiclayout.core.ui.UISelect
class UIFilterObjectElement(
    override var id: String = "",
    var autoCompletion: UISelect.AutoCompletion? = null,
    label: String? = null,
    additionalLabel: String? = null,
    tooltip: String? = null,
    defaultFilter: Boolean? = null
) : UIFilterElement(id = id, filterType = FilterType.OBJECT, label = label,
    additionalLabel = additionalLabel, tooltip = tooltip, defaultFilter = defaultFilter)

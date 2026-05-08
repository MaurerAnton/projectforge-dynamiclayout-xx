package org.dynamiclayout.core.ui.filter
class UIFilterBooleanElement(
    override var id: String = "",
    label: String? = null,
    additionalLabel: String? = null,
    tooltip: String? = null,
    defaultFilter: Boolean? = null
) : UIFilterElement(id = id, filterType = FilterType.BOOLEAN, label = label,
    additionalLabel = additionalLabel, tooltip = tooltip, defaultFilter = defaultFilter)

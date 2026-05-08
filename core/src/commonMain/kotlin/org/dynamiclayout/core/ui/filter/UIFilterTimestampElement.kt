package org.dynamiclayout.core.ui.filter
class UIFilterTimestampElement(
    override var id: String = "",
    var openInterval: Boolean = true,
    var selectors: List<QuickSelector>? = null,
    label: String? = null,
    additionalLabel: String? = null,
    tooltip: String? = null,
    defaultFilter: Boolean? = null
) : UIFilterElement(id = id, filterType = FilterType.TIMESTAMP, label = label,
    additionalLabel = additionalLabel, tooltip = tooltip, defaultFilter = defaultFilter) {
    enum class QuickSelector { YEAR, MONTH, WEEK, DAY, UNTIL_NOW }
}

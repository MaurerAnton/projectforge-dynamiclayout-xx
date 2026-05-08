package org.dynamiclayout.core.ui
data class UITableColumn(
    override var id: String,
    var title: String? = null,
    var titleIcon: List<String>? = null,
    var tooltip: String? = null,
    var dataType: UIDataType = UIDataType.STRING,
    var sortable: Boolean = true,
    var formatter: String? = null,
    var valueIconMap: Map<Any, String>? = null,
) : UIElement(UIElementType.TABLE_COLUMN), IUIId

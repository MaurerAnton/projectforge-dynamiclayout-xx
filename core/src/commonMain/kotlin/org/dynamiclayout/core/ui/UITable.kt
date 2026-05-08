package org.dynamiclayout.core.ui
open class UITable(
    override var id: String,
    var columns: MutableList<UITableColumn> = mutableListOf(),
    var listPageTable: Boolean = false,
    var rowClickPostUrl: String? = null,
    var refreshUrl: String? = null,
    var refreshMethod: RefreshMethod = RefreshMethod.POST,
    var refreshIntervalSeconds: Int? = null,
    var autoRefreshFlag: String? = null,
) : UIElement(if (listPageTable) UIElementType.TABLE_LIST_PAGE else UIElementType.TABLE), IUIId {
    enum class RefreshMethod { POST, GET, SSE }
}

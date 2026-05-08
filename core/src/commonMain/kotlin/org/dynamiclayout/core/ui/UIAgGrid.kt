package org.dynamiclayout.core.ui
open class UIAgGrid(
    override var id: String,
    var columnDefs: MutableList<UIAgGridColumnDef> = mutableListOf(),
    var listPageTable: Boolean = false,
    var rowSelection: RowSelection? = null,
    var selectionColumnDef: UIAgGridColumnDef? = null,
    var multiSelectButtonTitle: String? = null,
    var multiSelectButtonConfirmMessage: String? = null,
    var sortModel: List<SortModelEntry>? = null,
    var filterModel: Map<String, Any>? = null,
    var urlAfterMultiSelect: String? = null,
    var rowClickPostUrl: String? = null,
    var rowClickRedirectUrl: String? = null,
    var rowClickOpenModal: Boolean? = null,
    var rowClickFunction: String? = null,
    var handleCancelUrl: String? = null,
    var pagination: Boolean? = null,
    var paginationPageSize: Int? = null,
    var paginationPageSizeSelector: IntArray = intArrayOf(25, 50, 100, 200, 500, 1000),
    var height: String? = null,
    var onColumnStatesChangedUrl: String? = null,
    var resetGridStateUrl: String? = null,
) : UIElement(if (listPageTable) UIElementType.AG_GRID_LIST_PAGE else UIElementType.AG_GRID), IUIId {
    data class RowSelection(
        var mode: String = "multiRow",
        var enableClickSelection: Boolean? = null,
        var enableSelectionWithoutKeys: Boolean? = null
    )
    data class SortModelEntry(
        var colId: String? = null,
        var sort: String? = null,
        var sortIndex: Int? = null
    )
}

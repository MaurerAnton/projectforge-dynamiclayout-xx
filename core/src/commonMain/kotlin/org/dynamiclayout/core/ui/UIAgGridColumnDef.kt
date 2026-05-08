package org.dynamiclayout.core.ui
data class UIAgGridColumnDef(
    var field: String? = null,
    var headerName: String? = null,
    var headerTooltip: String? = null,
    var sortable: Boolean = false,
    var filter: Any? = true,
    var valueGetter: String? = null,
    var type: String? = null,
    var minWidth: Int? = null,
    var maxWidth: Int? = null,
    var width: Int? = null,
    var hide: Boolean? = null,
    var resizable: Boolean? = true,
    var valueFormatter: String? = null,
    var cellRenderer: String? = null,
    var wrapText: Boolean? = null,
    var autoHeight: Boolean? = null,
    var pinned: String? = null,
    var cellRendererParams: Map<String, Any>? = null,
    var headerClass: Array<String>? = null,
    var tooltipField: String? = null,
    var suppressSizeToFit: Boolean? = null,
    var lockPosition: String? = null,
    var filterParams: FilterParams? = null
) {
    data class FilterParams(
        var buttons: Array<String>? = null
    )
}

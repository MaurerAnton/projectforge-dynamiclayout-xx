package org.dynamiclayout.core.ui
import org.dynamiclayout.core.currentTimeMillis
class UILayout(
    var title: String,
    var restBaseUrl: String? = null,
    var userAccess: UserAccess = UserAccess(),
    var showHistory: Boolean? = null,
    var hideSearchFilter: Boolean? = null,
    val layout: MutableList<UIElement> = mutableListOf(),
    val namedContainers: MutableList<UINamedContainer> = mutableListOf(),
    val layoutBelowActions: MutableList<UIElement> = mutableListOf(),
    val actions: MutableList<UIElement> = mutableListOf(),
    var pageMenu: MutableList<PageMenuItem> = mutableListOf(),
    var excelExportSupported: Boolean = false,
    var multiSelectionSupported: Boolean = false,
    val watchFields: MutableList<String> = mutableListOf(),
    val uid: String = "layout${currentTimeMillis()}",
    val translations: MutableMap<String, String> = mutableMapOf(),
    var historyBackButton: String? = null
) : IUIContainer {
    data class UserAccess(
        var history: Boolean? = null,
        var insert: Boolean? = null,
        var update: Boolean? = null,
        var delete: Boolean? = null,
        var cancel: Boolean = true,
        var editHistoryComments: Boolean? = null
    )
    data class PageMenuItem(
        var id: String? = null,
        var label: String? = null,
        var url: String? = null
    )
    override fun add(el: UIElement): IUIContainer {
        layout.add(el)
        return this
    }
    fun addAction(action: UIElement): UILayout {
        actions.add(action)
        return this
    }
    fun addBelowAction(el: UIElement): UILayout {
        layoutBelowActions.add(el)
        return this
    }
    fun addTranslations(vararg keys: String) {
        // translations are added by LayoutUtils with I18nProvider
    }
    fun addWatchFields(vararg fields: String) {
        fields.forEach { watchFields.add(it) }
    }
}

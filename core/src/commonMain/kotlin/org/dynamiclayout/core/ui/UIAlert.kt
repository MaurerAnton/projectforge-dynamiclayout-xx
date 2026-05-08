package org.dynamiclayout.core.ui
data class UIAlert(
    var message: String? = null,
    var title: String? = null,
    var id: String? = null,
    var color: String? = null,
    var markdown: Boolean? = null,
    var icon: List<String>? = null,
) : UIElement(UIElementType.ALERT)

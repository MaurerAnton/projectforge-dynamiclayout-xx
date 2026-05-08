package org.dynamiclayout.core.ui
data class UIBadge(
    var title: String? = null,
    var color: String? = null,
    var pill: Boolean = true,
) : UIElement(UIElementType.BADGE)

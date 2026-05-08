package org.dynamiclayout.core.ui
class UIBadgeList(
    val badgeList: MutableList<UIBadge> = mutableListOf(),
) : UIElement(UIElementType.BADGE_LIST) {
    fun add(badge: UIBadge): UIBadgeList {
        badgeList.add(badge)
        return this
    }
}

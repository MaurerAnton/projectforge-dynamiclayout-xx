package org.dynamiclayout.core.ui
data class UIRatingStars(
    override var id: String,
    var values: List<String> = emptyList(),
    override var label: String? = null,
    override var additionalLabel: String? = null,
    override var tooltip: String? = null,
) : UIElement(UIElementType.RATING), UILabelledElement, IUIId

package org.dynamiclayout.core.ui
data class UIProgress(
    override var id: String,
    var title: String? = null,
    var color: String? = null,
    var value: Int? = null,
    var info: String? = null,
    var infoColor: String? = null,
    var cancelConfirmMessage: String? = null,
    var animated: Boolean? = null,
) : UIElement(UIElementType.PROGRESS), IUIId

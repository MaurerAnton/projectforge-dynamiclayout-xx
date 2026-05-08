package org.dynamiclayout.core.ui
class  UIButton private constructor(
    override var id: String,
    var title: String? = null,
    var color: String? = null,
    var outline: Boolean? = null,
    var default: Boolean? = null,
    var responseAction: ResponseAction? = null,
    override var tooltip: String? = null,
    var confirmMessage: String? = null,
    var disabled: Boolean? = null,
) : UIElement(UIElementType.BUTTON), UILabelledElement, IUIId {
    override var label: String? = null
    override var additionalLabel: String? = null
    companion object {
        @JvmStatic
        fun create(id: String, title: String? = null, color: String? = null,
                   default: Boolean? = null, responseAction: ResponseAction? = null): UIButton {
            return UIButton(id = id, title = title, color = color,
                default = default, responseAction = responseAction)
        }
        @JvmStatic
        fun createCancelButton(): UIButton = UIButton(
            id = "cancel", title = null, color = "secondary")
        @JvmStatic
        fun createSaveButton(): UIButton = UIButton(
            id = "save", title = null, color = "primary")
        @JvmStatic
        fun createDefaultButton(id: String = "save", title: String? = null,
                                color: String? = "primary", responseAction: ResponseAction? = null): UIButton {
            return UIButton(id = id, title = title, color = color,
                default = true, responseAction = responseAction)
        }
        @JvmStatic
        fun createPrimaryButton(id: String, title: String,
                                responseAction: ResponseAction? = null): UIButton {
            return UIButton(id = id, title = title, color = "primary",
                responseAction = responseAction)
        }
        @JvmStatic
        fun createSecondaryButton(id: String, title: String,
                                  responseAction: ResponseAction? = null): UIButton {
            return UIButton(id = id, title = title, color = "secondary",
                responseAction = responseAction)
        }
        @JvmStatic
        fun createDangerButton(id: String, title: String,
                               responseAction: ResponseAction? = null): UIButton {
            return UIButton(id = id, title = title, color = "danger",
                responseAction = responseAction)
        }
        @JvmStatic
        fun createDeleteButton(): UIButton = UIButton(
            id = "deleteIt", title = null, color = "danger")
        @JvmStatic
        fun createSearchButton(): UIButton = UIButton(
            id = "search", title = null, color = "primary", default = true)
        @JvmStatic
        fun createResetButton(): UIButton = UIButton(
            id = "reset", title = null, color = "secondary")
    }
}

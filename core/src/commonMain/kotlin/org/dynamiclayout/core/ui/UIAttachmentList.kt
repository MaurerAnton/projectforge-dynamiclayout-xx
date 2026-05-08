package org.dynamiclayout.core.ui
data class UIAttachmentList(
    var category: String = "",
    var attachmentId: Long? = null,
    var listId: String = "attachments",
    var maxSizeInKB: Int = 0,
    var readOnly: Boolean = false,
    var serviceBaseUrl: String? = null,
    var restBaseUrl: String? = null,
    var downloadOnRowClick: Boolean? = null,
    var uploadDisabled: Boolean? = null,
    var showExpiryInfo: Boolean? = null,
) : UIElement(UIElementType.ATTACHMENT_LIST)

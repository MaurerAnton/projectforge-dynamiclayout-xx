package org.dynamiclayout.core.ui
class ResponseAction(
    var url: String? = null,
    var targetType: TargetType? = null,
    var merge: Boolean? = null,
    var validationErrors: MutableList<ValidationError>? = null,
    var message: Message? = null,
    var variables: MutableMap<String, Any>? = null
) {
    data class Message(
        var i18nKey: String? = null,
        var message: String? = null,
        var technicalMessage: String? = null,
        var color: String? = null
    )
    enum class TargetType {
        REDIRECT, DOWNLOAD, UPDATE, GET, PUT, POST, DELETE,
        MODAL, CLOSE_MODAL, RELOAD, NOTHING, TOAST, CHECK_AUTHENTICATION
    }
}

package org.dynamiclayout.core.ui
data class ValidationError(
    var message: String? = null,
    var fieldId: String? = null,
    var messageId: String? = null
) {
    companion object {
        @JvmStatic
        fun create(message: String, fieldId: String? = null, messageId: String? = null): ValidationError {
            return ValidationError(message = message, fieldId = fieldId, messageId = messageId)
        }
    }
}

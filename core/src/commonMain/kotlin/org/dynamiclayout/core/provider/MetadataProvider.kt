package org.dynamiclayout.core.provider

import org.dynamiclayout.core.ui.UIDataType

data class FieldMetadata(
    val name: String,
    val maxLength: Int? = null,
    val required: Boolean? = null,
    val readOnly: Boolean = false,
    val i18nKey: String? = null,
    val additionalI18nKey: String? = null,
    val tooltipI18nKey: String? = null
)

interface MetadataProvider {
    fun getFieldMetadata(clazz: kotlin.reflect.KClass<*>, fieldName: String): FieldMetadata?
    fun getDataType(typeName: String): UIDataType
}

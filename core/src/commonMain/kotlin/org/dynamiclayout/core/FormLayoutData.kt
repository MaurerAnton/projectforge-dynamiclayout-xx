package org.dynamiclayout.core

import org.dynamiclayout.core.ui.UILayout

data class FormLayoutData(
    var data: Any? = null,
    var ui: UILayout? = null,
    var serverData: Map<String, Any?>? = null,
    var variables: Map<String, Any>? = null
)

package org.dynamiclayout.core.ui
data class UILength(
    var xs: Int? = null,
    var sm: Int? = null,
    var md: Int? = null,
    var lg: Int? = null,
    var xl: Int? = null
) {
    companion object {
        fun all(size: Int) = UILength(xs = size, sm = size, md = size, lg = size, xl = size)
    }
}

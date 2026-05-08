package org.dynamiclayout.core.ui
data class UILength(
    var xs: Int? = null,
    var sm: Int? = null,
    var md: Int? = null,
    var lg: Int? = null,
    var xl: Int? = null
) {
    companion object {
        @JvmStatic fun xs(size: Int) = UILength(xs = size)
        @JvmStatic fun sm(size: Int) = UILength(sm = size)
        @JvmStatic fun md(size: Int) = UILength(md = size)
        @JvmStatic fun lg(size: Int) = UILength(lg = size)
        @JvmStatic fun xl(size: Int) = UILength(xl = size)
        @JvmStatic
        fun all(size: Int) = UILength(xs = size, sm = size, md = size, lg = size, xl = size)
    }
}

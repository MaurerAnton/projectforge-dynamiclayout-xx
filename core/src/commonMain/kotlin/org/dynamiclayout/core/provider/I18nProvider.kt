package org.dynamiclayout.core.provider

/**
 * Abstraction for internationalization (i18n) used by LayoutUtils.
 * Replace the direct calls to ProjectForge's I18nHelper.translate().
 */
fun interface I18nProvider {
    /** Translate a single i18n key to the user's locale. */
    fun translate(key: String): String
}

fun I18nProvider.translateMsg(key: String, vararg args: Any?): String {
    return translate(key).format(args)
}

fun I18nProvider.addTranslations(target: MutableMap<String, String>, vararg keys: String) {
    keys.forEach { target[it] = translate(it) }
}

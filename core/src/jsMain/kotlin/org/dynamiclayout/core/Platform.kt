package org.dynamiclayout.core

actual fun currentTimeMillis(): Long = js("Date.now()").unsafeCast<Long>()

package org.dynamiclayout.core

import kotlinx.cinterop.ExperimentalForeignApi
import platform.posix.gettimeofday
import platform.posix.timeval

@OptIn(ExperimentalForeignApi::class)
actual fun currentTimeMillis(): Long {
    val tv = timeval()
    gettimeofday(tv.ptr, null)
    return tv.tv_sec * 1000L + tv.tv_usec / 1000L
}

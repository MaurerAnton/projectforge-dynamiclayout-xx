package org.dynamiclayout.core

/**
 * Platform-specific functions needed by DynamicLayout core.
 * Each platform (JVM, Native, JS) provides its own implementation.
 */
expect fun currentTimeMillis(): Long

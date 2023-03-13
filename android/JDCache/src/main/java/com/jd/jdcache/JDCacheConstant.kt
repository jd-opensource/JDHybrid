package com.jd.jdcache

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob

internal object JDCacheConstant {
    internal val applicationScope by lazy { CoroutineScope(SupervisorJob()) }

    internal val ioDispatcher by lazy { Dispatchers.IO }
    internal val mainDispatcher by lazy { Dispatchers.Main.immediate }

    const val NET_READ_BUFFER_SIZE = 1024 * 10
    const val LOCAL_READ_BUFFER_SIZE = 1024 * 2
}
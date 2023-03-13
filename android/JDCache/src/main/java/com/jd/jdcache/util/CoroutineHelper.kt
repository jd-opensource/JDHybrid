package com.jd.jdcache.util

import androidx.annotation.Keep
import com.jd.jdcache.JDCacheConstant
import kotlinx.coroutines.*
import kotlin.coroutines.Continuation

@Keep
object CoroutineHelper {

//    /**
//     * 启动协程。
//     */
//    fun LifecycleOwner.launchCoroutine(
//        block: suspend () -> Unit
//    ): Job {
//        return launchCoroutine(this.lifecycleScope, block)
//    }

    /**
     * 启动协程。
     * 若没有指定scope则使用全局scope。
     */
    fun Any?.launchCoroutine(
        scope: CoroutineScope? = JDCacheConstant.applicationScope,
        block: suspend () -> Unit
    ): Job {
        val useScope = scope ?: JDCacheConstant.applicationScope
        return useScope.launch { block() }
    }

    /**
     * 在IO线程中执行。
     * 若没有指定scope，则使用当前scope；若指定，则使用指定的scope
     */
    suspend fun <T> Any?.runOnIo(
        scope: CoroutineScope? = null,
        block: suspend () -> T
    ): T {
        val context = scope?.let { scope.coroutineContext + JDCacheConstant.ioDispatcher }
            ?: JDCacheConstant.ioDispatcher
        return withContext(context) { block() }
    }

    @JvmStatic fun <T> Continuation<T>.onSuccess(data: T) {
        resumeWith(Result.success(data))
    }

    @JvmStatic fun <T> Continuation<T>.onFail(throwable: Throwable) {
        resumeWith(Result.failure(throwable))
    }

}
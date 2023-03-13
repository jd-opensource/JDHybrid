package com.jd.jdcache.match.base

import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import androidx.annotation.CallSuper
import androidx.annotation.Keep
import androidx.annotation.WorkerThread
import androidx.lifecycle.Lifecycle
import com.jd.jdcache.JDCacheLoader
import java.io.FileInputStream
import java.io.InputStream
import java.util.concurrent.atomic.AtomicBoolean

@Keep
abstract class JDCacheResourceMatcher {

    abstract val name: String

    var loader: JDCacheLoader? = null

    protected val destroyed = AtomicBoolean(false)

    open fun onLifecycleStateChanged(event: Lifecycle.Event) {
        if (event == Lifecycle.Event.ON_DESTROY) {
            destroy()
        }
    }

    open fun prepare(url: String) {
    }

    @WorkerThread
    abstract fun match(request: WebResourceRequest): WebResourceResponse?

    fun destroy(){
        if (destroyed.compareAndSet(false, true)) {
            onDestroy()
        }
    }

    @CallSuper
    protected open fun onDestroy() {
        loader = null
    }

    protected open fun createResponse(
        mimeType: String,
        encoding: String?,
        header: MutableMap<String?, String>?,
        filePath: String
    ): WebResourceResponse {
        return createResponse(mimeType, encoding, header, FileInputStream(filePath))
    }

    protected open fun createResponse(
        mimeType: String,
        encoding: String?,
        header: MutableMap<String?, String>?,
        inputStream: InputStream
    ): WebResourceResponse {
        return createResponse(WebResourceResponse(mimeType, encoding, inputStream))
    }

    protected open fun createResponse(
        response: WebResourceResponse
    ): WebResourceResponse {
        response.responseHeaders = response.responseHeaders ?: HashMap(1)
        response.responseHeaders["JDCache"] = name
        return response
    }
}
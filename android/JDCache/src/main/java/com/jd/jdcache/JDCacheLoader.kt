package com.jd.jdcache

import android.os.Handler
import android.os.Looper
import android.os.Message
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import androidx.annotation.CallSuper
import androidx.annotation.Keep
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import com.jd.jdcache.match.ResourceMatcherManager
import com.jd.jdcache.match.base.JDCacheResourceMatcher
import com.jd.jdcache.service.JDCacheMaster
import com.jd.jdcache.util.JDCacheLog.d
import com.jd.jdcache.util.log
import java.util.concurrent.atomic.AtomicBoolean

/**
 * 离线资源匹配加载器
 * 预下载html，匹配本地文件 etc.
 */
@Keep
open class JDCacheLoader constructor(
    val url: String,
    val key: String = System.currentTimeMillis().toString(),
    val matcherList: List<JDCacheResourceMatcher>? = ResourceMatcherManager.createDefaultMatcherList(),
    val enable: Boolean = JDCacheSetting.enable
) {

    var preloadHtml: Boolean = true

    var view: JDCacheWebView? = null
        set(value) {
            if (value != field) {
                viewId = value?.hashCode() ?: -1
            }
            field = value
        }

    var lifecycleOwner: LifecycleOwner? = null
        set(value) {
            field?.lifecycle?.removeObserver(lifecycleEventObserver)
            field = value
            value?.lifecycle?.addObserver(lifecycleEventObserver)
        }

    var viewId: Int = -1
        private set

    protected val messageHandler: Handler by lazy {
        object : Handler(Looper.getMainLooper()) {
            override fun handleMessage(msg: Message) {
                handleMessageData(msg)
            }
        }
    }

    protected val destroyed = AtomicBoolean(false)

    protected val lifecycleEventObserver: LifecycleEventObserver by lazy {
        LifecycleEventObserver { _, event -> onLifecycleStateChanged(event) }
    }

    open fun onLifecycleStateChanged(event: Lifecycle.Event) {
        matcherList?.forEach { it.onLifecycleStateChanged(event) }
        if (event == Lifecycle.Event.ON_DESTROY) {
            destroy()
        }
    }

    open fun init() : JDCacheLoader {
        if (!enable) {
            return this
        }
        JDCacheMaster.getInstance().addLoader(this)
        prepareMatchers()
        return this
    }

    protected open fun prepareMatchers(){
        if (!enable) {
            return
        }
        matcherList?.forEach {
            it.loader = this
            it.prepare(url)
        }
    }

    open fun onPageStarted(url: String) {
        if (!enable) {
            return
        }

    }

    open fun onPageFinished(url: String) {
        if (!enable) {
            return
        }

    }

    open fun onRequest(request: WebResourceRequest): WebResourceResponse? {
        if (!enable) {
            return null
        }
        matcherList?.forEach { matcher ->
            val resp = matcher.match(request)
            if (resp != null) {
                log { d("JDCacheLoader", "Use local file to create response:" +
                        "[${matcher.name}](${request.url})") }
                return resp
            }
        }
        return null
    }

    open fun sendMessageData(what: Int, data: Any? = null){
        messageHandler.sendMessage(messageHandler.obtainMessage(what, data))
    }

    protected open fun handleMessageData(msg: Message) {

    }

    fun destroy(){
        if (destroyed.compareAndSet(false, true)) {
            onDestroy()
        }
    }

    @CallSuper
    protected open fun onDestroy(){
        JDCacheMaster.getInstance().removeLoader(key)
        matcherList?.forEach { it.destroy() }
        view = null
    }

}
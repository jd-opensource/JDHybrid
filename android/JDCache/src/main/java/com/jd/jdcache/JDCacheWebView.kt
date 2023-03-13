package com.jd.jdcache

import android.view.View
import android.webkit.ValueCallback
import androidx.annotation.Keep

@Keep
interface JDCacheWebView {

    val view: View?

    fun addJavascriptInterface(obj: Any, interfaceName: String)

    fun evaluateJavascript(script: String, resultCallback: ValueCallback<String>?)

    fun reload()
}
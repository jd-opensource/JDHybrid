/*
 * MIT License
 *
 * Copyright (c) 2022 JD.com, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */
package com.jd.jdbridge.base

import android.util.Log
import android.view.View
import android.webkit.ValueCallback
import com.jd.jdbridge.WebUtils
import com.jd.jdbridge.JDBridge
import com.jd.jdbridge.JDBridgeManager

interface IBridgeWebView {

    val view: View?

    val bridgeMap: MutableMap<String, IProxy>?

    fun onStart()

    fun onResume()

    fun onPause()

    fun onStop()

    fun destroy()

    fun getUrl(): String?

    fun addJavascriptInterface(obj: Any, interfaceName: String)

    fun evaluateJavascript(script: String, resultCallback: ValueCallback<String>?)

    fun loadUrl(url: String)

    fun loadUrl(url: String, additionalHttpHeaders: MutableMap<String, String>)

    fun reload()

}

fun IBridgeWebView.runOnMain(r: Runnable){
    WebUtils.runOnMain(this.view?.handler, r)
}

//fun IBridgeWebView.evaluateJsInMain(script: String) {
//    WebUtils.evaluateJsInMain(this, script)
//}

@JvmOverloads
fun IBridgeWebView.callJS(pluginName: String? = null, params: Any? = null, callback: IBridgeCallback? = null) {
    getJDBridge()?.callJS(pluginName, params, callback)
}

fun IBridgeWebView.dispatchEvent(eventName: String, params: Any? = null) {
    getJDBridge()?.dispatchEvent(eventName, params)
}

fun IBridgeWebView.registerPlugin(pluginName: String, plugin: IBridgePlugin) {
    getJDBridge()?.registerPlugin(pluginName, plugin)
}

fun IBridgeWebView.unregisterPlugin(pluginName: String) {
    getJDBridge()?.unregisterPlugin(pluginName)
}

fun IBridgeWebView.registerDefaultPlugin(plugin: IBridgePlugin) {
    getJDBridge()?.registerDefaultPlugin(plugin)
}

fun IBridgeWebView.registerBridge(proxy: IProxy) {
    bridgeMap?.let {
        it[proxy.name] = proxy
        addJavascriptInterface(proxy, proxy.name)
    }
}

fun IBridgeWebView.getBridge(name: String): IProxy? {
    return bridgeMap?.let {
        it[name]
    }
}

fun IBridgeWebView.getJDBridge(): JDBridge? {
    val bridge = getBridge(JDBridge.JS_NAME)
    return if (bridge is JDBridge) {
        bridge
    } else {
        if (JDBridgeManager.webDebug) {
            Log.w("IBridgeWebView", "Cannot find JS bridge(${JDBridge.JS_NAME}) " +
                    "in this WebView, please call registerBridge first.")
        }
        null
    }
}

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
package com.jd.jdbridge

import android.util.Log
import com.jd.jdbridge.JDBridgeConstant.STATUS_SUCCESS
import com.jd.jdbridge.base.*
import java.util.HashMap

object JDBridgeManager {

    private const val TAG = "JDBridgeManager"

    var webDebug = false

    private val mFnClassMap: MutableMap<String, Class<out IBridgePlugin>> by lazy {
        HashMap<String, Class<out IBridgePlugin>>()
    }

    internal fun getPluginClass(pluginName: String): Class<out IBridgePlugin>? {
        return mFnClassMap[pluginName]
    }

    /**
     * add a global plugin of JS JDBridge(that is [JDBridge]), plugin will be
     * newInstanced when used.
     */
    fun registerPlugin(pluginName: String, pluginClass: Class<out IBridgePlugin>) {
        mFnClassMap[pluginName] = pluginClass
    }

    /**
     * add a local plugin of JS JDBridge(that is [JDBridge]) to the [webView] instance.
     */
    fun registerPlugin(webView: IBridgeWebView, pluginName: String, plugin: IBridgePlugin) {
        webView.registerPlugin(pluginName, plugin)
    }

    /**
     * add a js bridge(like [JDBridge]) to the [webView] instance.
     * The bridge must have at least one method with @Javascript annotation that js can call.
     */
    fun registerBridge(webView: IBridgeWebView, proxy: IProxy) {
        webView.registerBridge(proxy)
    }

    internal fun callback2H5(
        webView: IBridgeWebView,
        functionName: String,
        callbackId: String? = null,
        status: String = STATUS_SUCCESS,
        result: Any? = null,
        msg: String? = null
    ) {
        if (functionName.isNotEmpty()) {
            val javascriptStr = "$functionName && $functionName('${
                Response(status, callbackId, result, msg)
            }');"
            webView.runOnMain (Runnable {
                webView.evaluateJavascript(javascriptStr, null)
            })
            Log.d(JDBridgeConstant.MODULE_TAG,javascriptStr)
        }
    }
}
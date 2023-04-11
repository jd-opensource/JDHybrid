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
import android.webkit.JavascriptInterface
import com.jd.jdbridge.WebUtils.arrayToJsonArray
import com.jd.jdbridge.JDBridgeConstant.JS_ALERT_DEBUG_MSG
import com.jd.jdbridge.JDBridgeConstant.JS_CALL_WEB
import com.jd.jdbridge.JDBridgeConstant.JS_DISPATCH_EVENT
import com.jd.jdbridge.JDBridgeConstant.JS_RESPOND_TO_WEB
import com.jd.jdbridge.JDBridgeConstant.JS_SET_DEBUG
import com.jd.jdbridge.JDBridgeConstant.MODULE_TAG
import com.jd.jdbridge.JDBridgeConstant.MSG_ACTION_NOT_FOUND
import com.jd.jdbridge.JDBridgeConstant.MSG_EXCEPTION
import com.jd.jdbridge.JDBridgeConstant.MSG_PLUGIN_NOT_FOUND
import com.jd.jdbridge.JDBridgeConstant.STATUS_ERROR
import com.jd.jdbridge.JDBridgeConstant.STATUS_EXCEPTION
import com.jd.jdbridge.JDBridgeConstant.STATUS_NOT_FOUND
import com.jd.jdbridge.JDBridgeConstant.STATUS_SUCCESS
import com.jd.jdbridge.base.*
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

class JDBridge(val webView: IBridgeWebView) : IProxy {

    companion object {
        const val JS_NAME = "XWebView"

        private const val TAG = "${MODULE_TAG}-JDBridge"

    }

    override val name: String
        get() = JS_NAME

    private var firstJsQueue = AtomicBoolean(true)

    private var callJsQueue: LinkedList<Request>? = LinkedList()

    /**
     * The name to value of [nativeCallbackMap]
     */
    private val callbackIdCreator = AtomicInteger(0)

    /**
     * Save native callback invoked after js responded.
     */
    private val nativeCallbackMap: MutableMap<String, IBridgeCallback> by lazy { ConcurrentHashMap<String, IBridgeCallback>() }

    /**
     * A default native plugin that binds to WebView instance. JS can call this without plugin name.
     */
    private var nativeDefaultPlugin: IBridgePlugin? = null

    /**
     * save native plugin that binds to WebView instance
     */
    private val nativeLocalPluginMap: MutableMap<String, IBridgePlugin> by lazy { HashMap<String, IBridgePlugin>() }

    init {
        registerPlugin("_jdbridge", JDBridgeModule())
    }

    fun onStart() {
        dispatchEvent("ContainerShow")
    }

    fun onResume() {
        dispatchEvent("ContainerActive")
    }

    fun onPause() {
        dispatchEvent("ContainerInactive")
    }

    fun onStop() {
        dispatchEvent("ContainerHide")
    }

    fun destroy() {
        synchronized(this) {
            for (it in nativeLocalPluginMap) {
                if (it.value is Destroyable) {
                    (it.value as Destroyable).destroy()
                }
            }
        }

        if (nativeDefaultPlugin is Destroyable) {
            (nativeDefaultPlugin as Destroyable).destroy()
        }
    }

    fun startQueueRequest() {
        if (!firstJsQueue.compareAndSet(true, false)) {
            callJsQueue?.forEach { removeJsCall(it) }
            callJsQueue = LinkedList()
        }
    }

    fun registerPlugin(pluginName: String, plugin: IBridgePlugin) {
        synchronized(this) {
            nativeLocalPluginMap[pluginName] = plugin
        }
    }

    fun unregisterPlugin(pluginName: String) {
        synchronized(this) {
            nativeLocalPluginMap.remove(pluginName)
        }
    }

    fun registerDefaultPlugin(plugin: IBridgePlugin) {
        nativeDefaultPlugin = plugin
    }

    /**
     * Try to add the new request into queue if JDBridge is not installed yet.
     * Otherwise dispatch the request to web right now.
     */
    private fun queueJsCall(request: Request) {
        callJsQueue?.apply {
            addLast(request)
            logD("queueJsCall, queue size = $size")
        } ?: run {
            logD("dispatchJsCall, request: ${request.plugin}")
            dispatchJsCall(request)
        }
    }

    /**
     * Save the callback into map, then call [JS_CALL_WEB] to notify js.
     * When js result returns by [respondFromJs], retrieve the callback from map.
     */
    private fun dispatchJsCall(request: Request) {
        if (!request.callbackId.isNullOrEmpty() && request.callback != null) {
            nativeCallbackMap[request.callbackId] = request.callback!!
        }
        webView.runOnMain(Runnable {
            webView.evaluateJavascript(JS_CALL_WEB.format(request.toString()), null)
        })
    }

    private fun removeJsCall(request: Request) {
        if (!request.callbackId.isNullOrEmpty()) {
            nativeCallbackMap.remove(request.callbackId)
        }
    }

    /**
     * Call js with request which called before JDBridge is ready.
     */
    private fun dispatchStartupJsCall() {
        val queue = callJsQueue
        logD("dispatchStartupJsCall, queue size = ${queue?.size}")
        callJsQueue = null
        queue?.forEach { request ->
            dispatchJsCall(request)
        }
    }

    /**
     * The method to invoke js plugin.
     * @param pluginName name which js code registers to be invoked.
     * @param params passed to js, may be a simple string value, a json string,
     *              a json object or an array, etc. It will be converted to json string.
     * @param callback callback function will be invoked after js result returns
     */
    fun callJS(pluginName: String? = null, params: Any? = null, callback: IBridgeCallback? = null) {
        val request =
            Request(
                pluginName,
                WebUtils.jsonObjectWrap(params),
                callbackIdCreator.incrementAndGet().toString()
            )
        callback?.let { request.callback = callback }
        queueJsCall(request)
    }

    fun dispatchEvent(eventName: String, params: Any? = null) {
        try {
            val paramsStr = when (params) {
                is JSONObject, is JSONArray -> {
                    params.toString()
                }
                is Map<*, *> -> {
                    JSONObject(params).toString()
                }
                is Collection<*> -> {
                    JSONArray(params).toString()
                }
                is Array<*> -> {
                    arrayToJsonArray(params).toString()
                }
                is Number, is Boolean -> {
                    "$params"
                }
                else -> {
                    if (params == null) {
                        "undefined"
                    } else {
                        "'$params'"
                    }
//                params?.let { "'$params'" }
                }
            }
            webView.runOnMain (Runnable {
                webView.evaluateJavascript(JS_DISPATCH_EVENT.format(eventName, paramsStr), null)
            })
        } catch (e: Exception) {
            logE(e)
            alertDebugMsg("DispatchEvent Error, err = ${e.message}")
        }
    }

    /**
     * Invoked when JDBridge is initialized.
     */
    private fun jsInit() {
        if (JDBridgeManager.webDebug) {
            webView.runOnMain (Runnable {
            webView.evaluateJavascript(JS_SET_DEBUG.format(true), null)
            })
        }
        dispatchStartupJsCall()
    }

    private fun getPlugin(pluginName: String?): IBridgePlugin? {
        val defaultPlugin = nativeDefaultPlugin
        var plugin: IBridgePlugin? = null

        if (!pluginName.isNullOrEmpty()) {
            synchronized(this) {
                plugin = nativeLocalPluginMap[pluginName]
                if (plugin == null) {
                    plugin = JDBridgeManager.getPluginClass(pluginName)?.newInstance()
                    plugin?.let {
                        nativeLocalPluginMap[pluginName] = it
                    }
                }
            }
        }

        if (plugin == null) {
            plugin = defaultPlugin
            if (defaultPlugin == null) {
                logD("_callNative -> Use native default plugin to process this calling of $pluginName")
            }
        }
        return plugin
    }

    /**
     *
     */
    @Deprecated("Deprecated method, do not use.")
    @JavascriptInterface
    fun callNative(
        pluginName: String?,
        action: String?,
        params: String?,
        callbackName: String?,
        callbackId: String?
    ) {
        logD(
            "callNative(Old) -> pluginName:$pluginName, action:$action, " +
                    "callbackName:$callbackName, callbackId:$callbackId, " +
                    "params:$params"
        )
        try {
            if (action.isNullOrEmpty()){
                directRespToWeb(callbackName,callbackId, STATUS_NOT_FOUND,null, MSG_ACTION_NOT_FOUND)
            }
            val plugin = getPlugin(pluginName)
            if (plugin == null) {
                logD("_callNative -> No native plugin found can process this calling of $pluginName")
                directRespToWeb(
                    callbackName,
                    callbackId,
                    STATUS_NOT_FOUND,
                    null,
                    MSG_PLUGIN_NOT_FOUND
                )
                return
            }
            val isExist = plugin.execute(webView, action, params, object : IBridgeProgressCallback {
                override fun onSuccess(result: Any?) {
                    logD("_callNative -> onSuccess, result: $result")
                    directRespToWeb(callbackName, callbackId, STATUS_SUCCESS, result, null)
                }

                override fun onError(errMsg: String?) {
                    logD("_callNative -> onError, msg: $errMsg")
                    directRespToWeb(callbackName, callbackId, STATUS_ERROR, null, errMsg)
                }

                override fun onProgress(data: Any?) {
                    //not supported
                }
            })
            if (!isExist) {
                logD("_callNative -> Native plugin returns false for action = $action")
                directRespToWeb(
                    callbackName,
                    callbackId,
                    STATUS_NOT_FOUND,
                    "",
                    MSG_ACTION_NOT_FOUND
                )
            }
        } catch (e: Exception) {
            directRespToWeb(
                callbackName,
                callbackId,
                STATUS_EXCEPTION,
                null,
                "$MSG_EXCEPTION, e: ${e.message}"
            )
            logE(e)
            alertDebugMsg("CallNative Error, err = ${e.message}")
        }
    }

    /**
     * The method for JDBridge to call native.
     */
    @JavascriptInterface
    fun _callNative(obj: String?) {
        var req: Request? = null
        try {
            obj?.let {
                req = JSONObject(obj).toRequest()
            }
        } catch (e: JSONException) {
            logE(e)
            alertDebugMsg("CallNative, cannot convert $obj to json, e: ${e.message}")
        }
        val request = req ?: return
        val pluginName = request.plugin
        val action = request.action
        val params = request.params
        val callbackId = request.callbackId
        logD("_callNative -> plugin:$pluginName, action:$action, callbackId:$callbackId, params:$params")
        try {
            val plugin = getPlugin(pluginName)
            if (plugin == null) {
                logD("_callNative -> No native plugin found can process this calling of $pluginName")
                respondToWeb(callbackId, STATUS_NOT_FOUND, null, MSG_PLUGIN_NOT_FOUND)
                return
            }
            val isExist =
                plugin.execute(
                    webView,
                    action,
                    params?.toString(),
                    object : IBridgeProgressCallback {
                        override fun onSuccess(result: Any?) {
                            logD("_callNative -> onSuccess, result: $result")
                            respondToWeb(callbackId, STATUS_SUCCESS, result, null, true)
                        }

                        override fun onError(errMsg: String?) {
                            logD("_callNative -> onError, msg: $errMsg")
                            respondToWeb(callbackId, STATUS_ERROR, null, errMsg)
                        }

                        override fun onProgress(data: Any?) {
                            logD("_callNative -> onProgress, data: $data")
                            respondToWeb(callbackId, STATUS_SUCCESS, data, "onProgress", false)
                        }
                    })
            if (!isExist) {
                logD("_callNative -> Native plugin returns false for action = $action")
                respondToWeb(callbackId, STATUS_NOT_FOUND, "", MSG_ACTION_NOT_FOUND)
            }
        } catch (e: Exception) {
            respondToWeb(
                callbackId,
                STATUS_EXCEPTION,
                null,
                "$MSG_EXCEPTION, e: ${e.message}"
            )
            logE(e)
            alertDebugMsg("CallNative Error, err = ${e.message}")
        }
    }

    /**
     * Invoked when JDBridge responds back to native.
     */
    private fun respondFromJs(obj: String?) {
        var response: Response? = null
        try {
            response = obj?.let { JSONObject(obj).toResponse() }
        } catch (e: JSONException) {
            logE(e)
            alertDebugMsg("RespondFromJs, cannot convert $obj to json, e: ${e.message}")
        }
        val callback: IBridgeCallback? = response?.let { nativeCallbackMap[response.callbackId] }
        logD(
            "_respondFromJs -> callbackId:${response?.callbackId}, " +
                    "callback:$callback, data:${response?.data}, " +
                    "success:${response?.status == STATUS_SUCCESS}, " +
                    "complete:${response?.complete}"
        )
        callback?.let { cb ->
            webView.runOnMain (Runnable {
            response?.let {
                    try {
                        if (it.complete || cb !is IBridgeProgressCallback) {
                            nativeCallbackMap.remove(it.callbackId)
                            if (it.status == STATUS_SUCCESS) {
                                cb.onSuccess(it.data)
                            } else {
                                cb.onError(it.msg)
                            }
                        } else {
                            cb.onProgress(it.data)
                        }
                    } catch (e: Exception) {
                        logE(e)
                        alertDebugMsg("RespondFromJs Error, err = ${e.message}")
                    }
                }
            })
        }
    }

    private fun respondToWeb(
        callbackId: String? = null,
        status: String,
        data: Any? = null,
        msg: String? = null,
        complete: Boolean = true
    ) {
        webView.runOnMain(Runnable {
            webView.evaluateJavascript(
                JS_RESPOND_TO_WEB.format(
                    "'${Response(status, callbackId, data, msg, complete)}'"
                ),
                null
            )
        })
    }

    private fun directRespToWeb(
        callbackName: String? = null,
        callbackId: String? = null,
        status: String,
        data: Any? = null,
        msg: String? = null
    ) {
        callbackName?.let {
            JDBridgeManager.callback2H5(webView, callbackName, callbackId, status, data, msg)
        }
    }

    internal inner class JDBridgeModule : IBridgePlugin {
        override fun execute(
            webView: IBridgeWebView?,
            method: String?,
            params: String?,
            callback: IBridgeCallback?
        ): Boolean {
            return when (method) {
                "_jsInit" -> {
                    jsInit()
                    true
                }
                "_respondFromJs" -> {
                    respondFromJs(params)
                    true
                }
                else -> {
                    false
                }
            }
        }
    }

    private fun logD(msg: String) {
        if (JDBridgeManager.webDebug && msg.isNotEmpty()) {
            Log.d(TAG, msg)
        }
    }

    private fun logW(msg: String) {
        if (JDBridgeManager.webDebug && msg.isNotEmpty()) {
            Log.w(TAG, msg)
        }
    }

    private fun logE(e: Exception) {
        if (JDBridgeManager.webDebug) {
            Log.e(TAG, e.message, e)
        }
    }

    private fun alertDebugMsg(msg: String) {
        if (JDBridgeManager.webDebug && msg.isNotEmpty()) {
            webView.runOnMain (Runnable {
            webView.evaluateJavascript(JS_ALERT_DEBUG_MSG.format(msg), null)
            })
        }
    }
}
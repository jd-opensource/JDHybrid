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
package com.jd.hybrid.example

import android.annotation.SuppressLint
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.webkit.ConsoleMessage
import android.webkit.WebChromeClient
import android.widget.TextView
import com.jd.jdbridge.base.*
import org.json.JSONObject


class JDBridgeFragment : BaseFragment() {
    init {
        perfData = Utils.PerformanceData("JDBridgeFragment")
    }

    private lateinit var webView: MyWebView
    private lateinit var logView: TextView

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        val view = inflater.inflate(R.layout.fragment_jdbridge, container, false)
        view.apply {
            webView = findViewById(R.id.webview)
            logView = findViewById(R.id.nativeLog)

            findViewById<View>(R.id.addNative).setOnClickListener(::addNativePlugin)
            findViewById<View>(R.id.addSeqNative).setOnClickListener(::addSeqNativePlugin)
            findViewById<View>(R.id.addDefaultNative).setOnClickListener(::addDefaultNativePlugin)

            findViewById<View>(R.id.callSyncJs).setOnClickListener(::callSyncJs)
            findViewById<View>(R.id.callAsyncJs).setOnClickListener(::callAsyncJs)
            findViewById<View>(R.id.callSeqJs).setOnClickListener(::callSeqJs)
            findViewById<View>(R.id.callDefaultJs).setOnClickListener(::callDefaultJs)
        }

        val url = arguments?.getString("url")
        Utils.configWebView(webView, perfData)
        //给WebViewClient绑定loader并设置给WebView
        webView.webViewClient = Utils.getCommonWebClient(webView)
        webView.webChromeClient = object : WebChromeClient() {
            override fun onConsoleMessage(consoleMessage: ConsoleMessage?): Boolean {
                consoleMessage?.apply {
                    Log.d(
                        "JDBridge",
                        "[${messageLevel()}]${message()}(${sourceId()}[${lineNumber()}])"
                    )
                }
                return true
            }
        }

        webView.callJS("MySyncJsPlugin", "1stEarlyCall", object : IBridgeCallback {
            override fun onSuccess(result: Any?) {
                showLog("Received success from MySyncJsPlugin(1stEarlyCall), result = $result")
            }
        })
        webView.callJS(
            "MySyncJsPlugin",
            JSONObject("{p:'2ndEarlyCall'}"),
            object : IBridgeCallback {
                override fun onSuccess(result: Any?) {
                    showLog("Received success from MySyncJsPlugin(2ndEarlyCall), result = $result")
                }
            })
        url?.apply {
            webView.loadUrl(url)
        }
        return view
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

    }

    override fun onStart() {
        super.onStart()
        webView.onStart()
    }

    override fun onResume() {
        super.onResume()
        webView.onResume()
    }

    override fun onPause() {
        super.onPause()
        webView.onPause()
    }

    override fun onStop() {
        super.onStop()
        webView.onStop()
    }

    override fun onDestroy() {
        super.onDestroy()
        webView.destroy()
    }

    private fun addNativePlugin(view: View) {
        val name = "MyNativePlugin"
        showLog("register $name")
        webView.registerPlugin(name, MyNativePlugin(name))
    }

    private fun addSeqNativePlugin(view: View) {
        val name = "MySequenceNativePlugin"
        showLog("register $name")
        webView.registerPlugin(name, MySequenceNativePlugin(name))
    }

    private fun addDefaultNativePlugin(view: View) {
        val name = "DefaultNativePlugin"
        showLog("register $name")
        webView.registerDefaultPlugin(MyNativePlugin(name))
    }

    private fun callSyncJs(view: View) {
        webView.callJS("MySyncJsPlugin", "callSyncJs-buttonClick", object : IBridgeCallback {
            override fun onSuccess(result: Any?) {
                showLog("Received success from MySyncJsPlugin(buttonClick), result = $result")
            }

            override fun onError(errMsg: String?) {
                showLog("Received error from MySyncJsPlugin(buttonClick), errMsg = $errMsg")
            }
        })
    }

    private fun callAsyncJs(view: View) {
        val paramsMap = HashMap<String, String>()
        paramsMap["f"] = "callAsyncJs"
        paramsMap["p"] = "button's Click"
        paramsMap["m"] = "https://m.jd.com?abc=1&n=k's#f"
        webView.callJS("MyAsyncJsPlugin", paramsMap,
            object : IBridgeCallback {
                override fun onError(errMsg: String?) {
                    showLog("Received error from MyAsyncJsPlugin(buttonClick), result = $errMsg")
                }

                override fun onSuccess(result: Any?) {
                    showLog("Received success from MyAsyncJsPlugin(buttonClick), result = $result")
                }
            })
    }

    private fun callSeqJs(view: View) {
        val list = arrayListOf("callSeqJs-buttonClick1", "callSeqJs-buttonClick2", "callSeqJs-buttonClick3")
        webView.callJS("MySequenceJsPlugin", list, object : IBridgeProgressCallback {
            override fun onError(errMsg: String?) {
                showLog("Received error from MySequenceJsPlugin(buttonClick), err = $errMsg")
            }

            override fun onProgress(data: Any?) {
                showLog("Received progress from MySequenceJsPlugin(buttonClick), result = $data")
            }

            override fun onSuccess(result: Any?) {
                showLog("Received success from MySequenceJsPlugin(buttonClick), result = $result")
            }


        })
    }

    private fun callDefaultJs(view: View) {
        val array = arrayOf("defaultClickParam1", "defaultClickParam2", "defaultClickParam3")
        webView.callJS(null, array, object : IBridgeCallback {
            override fun onSuccess(result: Any?) {
                showLog("Received success from default js plugin (buttonClick), result = $result")
            }

            override fun onError(errMsg: String?) {
                showLog("Received error from default js plugin (buttonClick), errMsg = $errMsg")
            }
        })
    }

    @SuppressLint("SetTextI18n")
    fun showLog(log: String) {
        activity?.runOnUiThread { logView.text = log + "\n-------\n" + logView.text }
    }

    private inner class MyNativePlugin(val name: String) : IBridgePlugin, Destroyable {

        override fun execute(
            webView: IBridgeWebView?,
            method: String?,
            params: String?,
            callback: IBridgeCallback?
        ): Boolean {
            showLog("$name called by js, action = $method, params = $params")
            callback?.onSuccess(params)
            return true
        }

        override fun destroy() {
        }

    }

    private inner class MySequenceNativePlugin(val name: String) : IBridgePlugin {

        var progress = 0

        override fun execute(
            webView: IBridgeWebView?,
            method: String?,
            params: String?,
            callback: IBridgeCallback?
        ): Boolean {
            showLog("$name called by js, action = $method, params = $params")
            Thread {
                do {
                    if (progress >= 100 || callback !is IBridgeProgressCallback) {
                        showLog("$name finished")
                        callback?.onSuccess(params)
                        break
                    } else {
                        showLog("$name onProgress:$progress")
                        callback.onProgress(progress)
                    }
                    progress += 10
                    Thread.sleep(500)
                } while (true)
            }.start()
            return true
        }

    }
}
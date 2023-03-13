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
package com.jd.hybrid

import android.annotation.SuppressLint
import android.content.Context
import android.os.Build
import android.util.AttributeSet
import android.util.Log
import android.view.View
import android.webkit.ValueCallback
import android.webkit.WebSettings
import android.webkit.WebView
import androidx.annotation.RequiresApi
import com.jd.jdbridge.WebUtils.getWrapJs
import com.jd.jdbridge.JDBridgeInstaller
import com.jd.jdbridge.JDBridgeManager
import com.jd.jdbridge.base.IBridgeWebView
import com.jd.jdbridge.base.IProxy
import com.jd.jdbridge.base.runOnMain
import com.jd.jdcache.JDCacheWebView

open class JDWebView : WebView, IBridgeWebView, JDCacheWebView {

    companion object {
        @JvmStatic
        var webDebug = false
            set(value) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                    setWebContentsDebuggingEnabled(value)
                }
                JDBridgeManager.webDebug = value
                field = value
            }

    }

    constructor(context: Context)
            : super(context)

    constructor(context: Context, attrs: AttributeSet?)
            : super(context, attrs)

    constructor(context: Context, attrs: AttributeSet?, defStyleAttr: Int)
            : super(context, attrs, defStyleAttr)

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    constructor(context: Context, attrs: AttributeSet?, defStyleAttr: Int, defStyleRes: Int)
            : super(context, attrs, defStyleAttr, defStyleRes)

    private val jdBridgeInstaller: JDBridgeInstaller = JDBridgeInstaller()

    final override val view: View
        get() = this

    final override val bridgeMap: MutableMap<String, IProxy>
        get() = jdBridgeInstaller.bridgeMap

    init {
        val settings = settings
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            settings.mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
        }
        settings.cacheMode = WebSettings.LOAD_DEFAULT
        settings.domStorageEnabled = true
        @SuppressLint("SetJavaScriptEnabled")
        settings.javaScriptEnabled = true
        settings.loadWithOverviewMode = true
        settings.useWideViewPort = true
        settings.builtInZoomControls = false
        @SuppressLint("ObsoleteSdkInt")
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.ICE_CREAM_SANDWICH_MR1) {
            settings.allowFileAccessFromFileURLs = false
            settings.allowUniversalAccessFromFileURLs = false
        }
        settings.savePassword = false
        @Suppress("LeakingThis")
        jdBridgeInstaller.install(this)
    }

    override fun onStart() {
        jdBridgeInstaller.onStart()
    }

    override fun onResume() {
        super.onResume()
        jdBridgeInstaller.onResume()
    }

    override fun onPause() {
        jdBridgeInstaller.onPause()
        super.onPause()
    }

    override fun onStop() {
        jdBridgeInstaller.onStop()
    }

    override fun destroy() {
        jdBridgeInstaller.destroy()
        super.destroy()
    }

    @SuppressLint("JavascriptInterface")
    override fun addJavascriptInterface(obj: Any, interfaceName: String) {
        runOnMain (Runnable {
            super.addJavascriptInterface(obj, interfaceName)
        })
    }

    override fun evaluateJavascript(script: String, resultCallback: ValueCallback<String>?) {
        runOnMain (Runnable {
            val wrapJs = getWrapJs(script)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                if (BuildConfig.DEBUG) {
                    Log.d("JDWebView", "evaluateJavascript -> $wrapJs")
                }
                super.evaluateJavascript(wrapJs, resultCallback)
            } else {
                if (BuildConfig.DEBUG) {
                    Log.d("JDWebView", "loadUrl -> $wrapJs")
                }
                super.loadUrl(wrapJs)
            }
        })
    }

    override fun loadUrl(url: String) {
        jdBridgeInstaller.loadUrl(url)
        runOnMain (Runnable {
            super.loadUrl(url)
        })
    }

    override fun loadUrl(url: String, additionalHttpHeaders: MutableMap<String, String>) {
        jdBridgeInstaller.loadUrl(url)
        runOnMain (Runnable {
            super.loadUrl(url, additionalHttpHeaders)
        })
    }

    override fun reload() {
        jdBridgeInstaller.reload()
        runOnMain (Runnable {
            super.reload()
        })
    }

    override fun stopLoading() {
        runOnMain (Runnable {
            super.stopLoading()
        })
    }

    override fun goBack() {
        runOnMain (Runnable {
            super.goBack()
        })
    }

    override fun goForward() {
        runOnMain (Runnable {
            super.goForward()
        })
    }

    override fun goBackOrForward(steps: Int) {
        runOnMain (Runnable {
            super.goBackOrForward(steps)
        })
    }
}
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
import android.os.Build
import android.webkit.*
import com.jd.hybrid.XWebView

object Utils {

    fun configWebView(view: WebView, perfData: PerformanceData) {
        if (view !is XWebView) {
            configSysWebView(view)
        }
        CookieManager.getInstance().setAcceptCookie(true)
        view.addJavascriptInterface(PerformanceJsBridge(perfData), PerformanceJsBridge.NAME)
    }

    private fun configSysWebView(view: WebView){
        val settings = view.settings
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
    }

    fun getCommonWebClient(webView: MyWebView? = null): WebViewClient{
        return object : WebViewClient() {
            override fun shouldOverrideUrlLoading(
                view: WebView?,
                request: WebResourceRequest?
            ): Boolean {
                return super.shouldOverrideUrlLoading(view, request)
            }
        }
    }

    data class PerformanceData(val pageName: String) {
        var fp: String? = null
        var fcp: String? = null
        var lcp: String? = null
        var pageFinish: String? = null

        override fun toString(): String {
            return """
                ($pageName)
                First Paint: $fp,
                First Contentful Paint: $fcp,
                Largest Contentful Paint: $lcp,
                PageFinished - PageStarted: $pageFinish
                """.trimIndent()
        }

    }
}
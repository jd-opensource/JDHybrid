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

import android.graphics.Bitmap
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import com.jd.jdcache.JDCacheLoader
import com.jd.jdcache.JDCache.createDefaultLoader
import com.jd.jdcache.JDCache.getAndBindLoader


class JDCacheFragment : BaseFragment() {
    init {
        perfData = Utils.PerformanceData("JDCacheFragment")
    }

    private lateinit var webView: MyWebView

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        val view = inflater.inflate(R.layout.fragment_jdcache, container, false)
        view?.apply {
            webView = findViewById(R.id.webview)
        }

        val url = arguments?.getString("url")
        //获取之前提前创建的loader
        val loaderKey = arguments?.getString("loaderKey")
        var loader: JDCacheLoader? = loaderKey?.let {
            getAndBindLoader(it)
        }
        //如果之前没有提前创建，则这里创建
        loader = loader ?: createDefaultLoader(url)
        //设置lifecycleOwner监听生命周期
        loader?.lifecycleOwner = this

        Utils.configWebView(webView, perfData)
        //给WebViewClient绑定loader并设置给WebView
        webView.webViewClient = object : WebViewClient() {
            override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                super.onPageStarted(view, url, favicon)
                url?.let {
                    loader?.onPageStarted(url)
                }
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                url?.let {
                    loader?.onPageFinished(url)
                }
            }

            override fun shouldInterceptRequest(
                view: WebView?,
                request: WebResourceRequest?
            ): WebResourceResponse? {
                return request?.let { loader?.onRequest(request) } ?: super.shouldInterceptRequest(view, request)
            }
        }

        url?.apply {
            webView.loadUrl(url)
        }
        return view
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
}
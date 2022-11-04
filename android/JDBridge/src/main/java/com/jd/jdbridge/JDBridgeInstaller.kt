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

import com.jd.jdbridge.base.IBridgeWebView
import com.jd.jdbridge.base.IProxy
import com.jd.jdbridge.base.registerBridge

class JDBridgeInstaller {

    val bridgeMap: MutableMap<String, IProxy> = HashMap(1)

    private lateinit var jsBridge: JDBridge

    fun install(actualView: IBridgeWebView){
        jsBridge = JDBridge(actualView)
        actualView.registerBridge(jsBridge)
    }

    fun loadUrl(url: String) {
        if (url.startsWith("http") || url.startsWith("file")) {
            jsBridge.startQueueRequest()
        }
    }

    fun reload() {
        jsBridge.startQueueRequest()
    }

    fun onStart() {
        jsBridge.onStart()
    }

    fun onResume() {
        jsBridge.onResume()
    }

    fun onPause() {
        jsBridge.onPause()
    }

    fun onStop() {
        jsBridge.onStop()
    }

    fun destroy() {
        jsBridge.destroy()
    }
}
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

import android.app.Application
import android.widget.Toast
import com.jd.hybrid.JDWebView
import com.jd.hybrid.example.CoroutineHelper.launchCoroutine
import com.jd.jdbridge.JDBridgeManager
import com.jd.jdcache.JDCache
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

fun Any.showToast(msg: String?){
    msg?.apply {
        launchCoroutine {
            withContext(Dispatchers.Main.immediate) {
                Toast.makeText(MyApplication.app, msg, Toast.LENGTH_SHORT).show()
            }
        }
    }
}

class MyApplication : Application() {

    companion object {
        lateinit var app: Application
            private set
        var userAgent: String? = null
        var debug = true
    }

    override fun onCreate() {
        app = this
        super.onCreate()

        JDWebView.webDebug = debug // will also set JDBridge.js debuggable
        //初始化JDCache
        JDCache.init(this, debug)
        //设置必要参数
        JDCache.setGlobalParams(MyHybridParamsProvider::class.java)
        //注册全局JS桥
        JDBridgeManager.registerPlugin(GlobalJdBridgePlugin.NAME, GlobalJdBridgePlugin::class.java)
    }
}
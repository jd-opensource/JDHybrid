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

import com.jd.jdcache.JDCacheLoader
import com.jd.jdcache.JDCacheParamsProvider
import com.jd.jdcache.entity.JDCacheDataSource

class MyHybridParamsProvider : JDCacheParamsProvider() {

    companion object {
        const val DEMO_PRELOAD_URL1 = "https://m.jd.com"
        const val DEMO_PRELOAD_FILE1_ASSET = "offline/m.jd.com"
        const val DEMO_PRELOAD_FILE1_DIR = "m.jd.com"

        const val DEMO_PRELOAD_URL2 = "https://prodev.m.jd.com/mall/active/3jmVvVWpsmP2m1Uab14H8crExDVw/index.html"
        const val DEMO_PRELOAD_FILE2_ASSET = "offline/3jmVvVWpsmP2m1Uab14H8crExDVw"
        const val DEMO_PRELOAD_FILE2_DIR = "3jmVvVWpsmP2m1Uab14H8crExDVw"
    }

    override fun getUserAgent(url: String?): String? {
        return MyApplication.userAgent
    }

    override fun showLog(): Boolean {
        return true
    }

    override fun sourceWithUrl(url: String, loader: JDCacheLoader?): JDCacheDataSource? {
        return when(url){
            DEMO_PRELOAD_URL1 ->
                JDCacheDataSource(DEMO_PRELOAD_FILE1_DIR, isRelativePath = true)
            DEMO_PRELOAD_URL2 ->
                JDCacheDataSource(DEMO_PRELOAD_FILE2_DIR, isRelativePath = true)
            else ->
                null
        }
        /* usage example
        return when(url){
            "Url1" ->
                JDCacheDataSource("localFileDirPath1")
            "Url2" ->
                JDCacheDataSource("localFileDirPath2", sourceMap = mapOf(Pair("https://Host2/a.js", JDCacheLocalResp("https://Host2/a.js", "script", filename = "a.js"))))
            "Url3" ->
                JDCacheDataSource("localFileDirPath3", sourceList = listOf(Triple("https://Host3/b.css", "stylesheet", "b.css")))
            "Url4" ->
                JDCacheDataSource("localFileDirPath4", sourceStr = "[{\"url\":\"https://Host4/c.png\",\"filename\":\"c.png\",\"type\":\"image\"}]")
            else -> null
        }
        */
    }

}
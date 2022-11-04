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

import android.webkit.JavascriptInterface
import org.json.JSONArray
import java.util.*

class PerformanceJsBridge(val perfData: Utils.PerformanceData) {

    companion object {
        const val NAME = "DemoJs"

        const val JS_LISTEN_LCP = """
        javascript:try{
            const po = new PerformanceObserver((entryList) => {
                const entries = entryList.getEntries();
                const lastEntry = entries[entries.length - 1];
                window.JDHybrid_lcp = lastEntry.renderTime || lastEntry.loadTime;
            });
            po.observe({type: 'largest-contentful-paint', buffered: true});
        } catch (e) {}"""

        const val JS_SEND_PERFORMANCE = """
        javascript:try{
            window.$NAME && $NAME.sendPerformance(
                %s,
                JSON.stringify(window.performance.timing),
                JSON.stringify(window.performance.getEntriesByType('paint')),
                window.JDHybrid_lcp ? window.JDHybrid_lcp : -1);
        }catch (e) {}"""
    }

    @JavascriptInterface
    fun sendPerformance(finish: String, timing: String, paint: String, lcp: Double){
        var fp = ""
        var fcp = ""
        if (paint.isNotEmpty()) {
            val resourceJson = JSONArray(paint)
            for (i in 0 until resourceJson.length()) {
                val entity = resourceJson.getJSONObject(i)
                val startTime: String = entity.getDouble("startTime").to2f()
                if ("first-paint" == entity.getString("name")) {
                    fp = startTime
                } else if ("first-contentful-paint" == entity.getString("name")) {
                    fcp = startTime
                }
            }
        }
        perfData.apply {
            pageFinish = finish
            this.fp = fp
            this.fcp = fcp
            this.lcp = lcp.to2f()
        }
    }

    private fun Double.to2f(): String{
        if (this == 0.0) {
            return "0"
        }
        return String.format(Locale.getDefault(), "%.2f", this)
    }
}
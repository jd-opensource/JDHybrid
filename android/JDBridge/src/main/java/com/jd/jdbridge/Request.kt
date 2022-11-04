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
import com.jd.jdbridge.JDBridgeConstant.MODULE_TAG
import com.jd.jdbridge.base.IBridgeCallback
import org.json.JSONException
import org.json.JSONObject

data class Request(
    val plugin: String? = null,
    val params: Any? = null,
    val callbackId: String? = null
) {
    var action: String? = null // only needed when js calls native
    var callback: IBridgeCallback? = null

    override fun toString(): String {
        val jsonObj = JSONObject()
        try {
            jsonObj.put("plugin", plugin)
            jsonObj.put("action", action)
            jsonObj.put("params", params)
            jsonObj.put("callbackId", callbackId)
        } catch (e: JSONException) {
            if (JDBridgeManager.webDebug) {
                Log.e("${MODULE_TAG}-Request", e.message, e)
            }
        }
        return JSONObject.quote(jsonObj.toString())
    }
}

internal fun JSONObject.toRequest(): Request {
    val request = Request(
        optString("plugin", "").ifEmpty { null },
        opt("params"),
        optString("callbackId", "").ifEmpty { null })
    request.action = optString("action", "").ifEmpty { null }
    return request
}

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

import android.os.Handler
import android.os.Looper
import com.jd.jdbridge.JDBridgeConstant.JS_PREFIX
import com.jd.jdbridge.JDBridgeConstant.JS_TRY_WARP
import com.jd.jdbridge.JDBridgeConstant.MODULE_TAG
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.lang.reflect.Array

@Suppress("MemberVisibilityCanBePrivate")
object WebUtils {

    private const val TAG: String = "${MODULE_TAG}-WebUtils"

    private val mainHandler = Handler(Looper.getMainLooper())

    fun runOnMain(mainHandler: Handler?, r: Runnable){
        val mainThread = mainHandler?.looper?.thread ?: this.mainHandler.looper.thread
        if (Thread.currentThread() == mainThread) {
            r.run()
        } else if (mainHandler?.post(r) != true) {
            this.mainHandler.post(r)
        }
    }

    fun getWrapJs(script: String) : String{
        return when {
            script.isEmpty() || script.startsWith(JS_PREFIX) -> {
                script
            }
            else -> {
                JS_TRY_WARP.format(script)
            }
        }
    }

    fun string2JsStr(str: String): String {
        if (str.isEmpty()) {
            return str
        }
        return str.replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\'", "\\\'")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\u2028", "\\u2028")
            .replace("\u2029", "\\u2029")
    }

    /**
     * Copied from [org.json.JSONObject.wrap]
     * ------
     *
     * Wraps the given object if necessary.
     *
     * <p>If the object is null or , returns {@link #NULL}.
     * If the object is a {@code JSONArray} or {@code JSONObject}, no wrapping is necessary.
     * If the object is {@code NULL}, no wrapping is necessary.
     * If the object is an array or {@code Collection}, returns an equivalent {@code JSONArray}.
     * If the object is a {@code Map}, returns an equivalent {@code JSONObject}.
     * If the object is a primitive wrapper type or {@code String}, returns the object.
     * Otherwise if the object is from a {@code java} package, returns the result of {@code toString}.
     * If wrapping fails, returns null.
     */
    internal fun jsonObjectWrap(o: Any?): Any? {
        if (o == null) {
            return JSONObject.NULL
        }
        if (o is JSONArray || o is JSONObject) {
            return o
        }
        if (o == JSONObject.NULL) {
            return o
        }
        try {
            if (o is Collection<*>) {
                return JSONArray(o as Collection<*>?)
            } else if (o.javaClass.isArray) {
                return arrayToJsonArray(o)
            }
            if (o is Map<*, *>) {
                return JSONObject(o as Map<*, *>?)
            }
            if (o is Boolean ||
                o is Byte ||
                o is Char ||
                o is Double ||
                o is Float ||
                o is Int ||
                o is Long ||
                o is Short ||
                o is String
            ) {
                return o
            }
            if (o.javaClass.getPackage()?.name?.startsWith("java.") == true) {
                return o.toString()
            }
        } catch (ignored: Exception) {
        }
        return null
    }

    /**
     * Copied from [org.json.JSONArray]
     * ------
     *
     * Creates a new JSONArray with values from the given primitive array.
     */
    internal fun arrayToJsonArray(array: Any): JSONArray {
        if (!array.javaClass.isArray) {
            throw JSONException("Not a primitive array: " + array.javaClass)
        }
        val length = Array.getLength(array)
        val jsonArray = JSONArray()
        for (i in 0 until length) {
            jsonArray.put(jsonObjectWrap(Array.get(array, i)))
        }
        return jsonArray
    }
}
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

object JDBridgeConstant {

    const val MODULE_TAG = "JDBridge"

    const val JS_PREFIX = "javascript:"

    const val JS_TRY_WARP = "javascript:try{%s}catch(e){console&&console.error(e)}"

    const val JS_CALL_WEB = "window.JDBridge._handleRequestFromNative(%s)"

    const val JS_RESPOND_TO_WEB = "window.JDBridge._handleResponseFromNative(%s)"

    const val JS_DISPATCH_EVENT =
        ";(function(){" +
            "var event = new CustomEvent('%s', {'detail': %s}); " +
            "window.dispatchEvent(event);" +
        "})();"

    const val JS_ALERT_DEBUG_MSG = "alert('JDBridge Debug Msg: %s')"

    const val JS_SET_DEBUG = "window.JDBridge.setDebug(%b)"

    const val STATUS_SUCCESS = "0"
    const val STATUS_ERROR = "-1"
    const val STATUS_EXCEPTION = "1"
    const val STATUS_NOT_FOUND = "-2"

    const val MSG_PLUGIN_NOT_FOUND = "Target plugin not found."
    const val MSG_ACTION_NOT_FOUND = "Target action not found."
    const val MSG_EXCEPTION = "Execute plugin throws."
}
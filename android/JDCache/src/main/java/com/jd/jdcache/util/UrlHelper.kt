package com.jd.jdcache.util

import android.net.Uri
import android.text.TextUtils
import androidx.annotation.Keep

@Keep
object UrlHelper {

    const val METHOD_GET = "GET"
    const val METHOD_POST = "POST"
    const val METHOD_PUT = "PUT"
    const val METHOD_DELETE = "DELETE"
    const val METHOD_HEAD = "HEAD"
    const val METHOD_PATCH = "PATCH"
    const val METHOD_OPTIONS = "OPTIONS"
    const val METHOD_TRACE = "TRACE"

    /**
     * 原始url转换为 host/path 的形式，只转化http(s)的url
     */
    fun Uri.urlToKey(): String {
        val scheme = this.scheme
        val host = this.host.safeUrlPart()
        return if (("https".equals(scheme, ignoreCase = true) || "http".equals(scheme, ignoreCase = true))
            && !TextUtils.isEmpty(host)) {
            val path = this.path.safeUrlPart()
            //只支持http(s)协议，host不能为空
            "$host" + (path?.let {
                if (it.startsWith("/")) {
                    it
                } else {
                    "/$it"
                }
            } ?: "")
        } else {
            this.toString()
        }
    }

    /**
     * 原始url转换为 host/path 的形式，只转化http(s)的url
     */
    fun String.urlToKey(): String {
        return try {
            Uri.parse(this).urlToKey()
        } catch (e: Exception) {
            this
        }
    }

    fun String?.safeUrlPart(): String? {
        return this?.trimStart()?.dropLastWhile {
            when(it) {
                '/' -> true
                ' ' -> true
                else -> false
            }
        } ?: this
    }

    /**
     * 从url获取文件名
     */
    fun String.getFileNameFromUrl(): String? {
        if (!this.endsWith("/")) {
            val index = this.lastIndexOf("/")
            if (index != -1) {
                return this.substring(index + 1)
            }
        }
        return null
    }

    fun Uri?.matchHostPath(other: Uri?): Boolean {
        return this?.host.safeUrlPart().equals(other?.host.safeUrlPart(), ignoreCase = true)
                && this?.path.safeUrlPart().equals(other?.path.safeUrlPart(), ignoreCase = false)
    }

    //header转换，规则根据https://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.2
    fun Map<String?, List<String?>>?.convertHeader(): Map<String?, String>? {
        if (this.isNullOrEmpty()) {
            return null
        }
        val header: MutableMap<String?, String> = HashMap(this.size)
        this.forEach { entry ->
            val valueList: List<String?> = entry.value
            val combinedValue = StringBuilder()
            for (value in valueList) {
                value?.let {
                    if (combinedValue.isNotEmpty()) {
                        combinedValue.append(",")
                    }
                    combinedValue.append(value)
                }
            }
            header[entry.key] = combinedValue.toString()
        }
        return header
    }

}
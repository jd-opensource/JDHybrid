package com.jd.jdcache

import androidx.annotation.Keep

@Keep
interface JDCacheLogger {
    fun d(msg: String?)
    fun d(tag: String?, msg: String?)
    fun d(tag: String?, t: Throwable?)
    fun d(tag: String?, msg: String?, t: Throwable?)
    fun w(msg: String?)
    fun w(tag: String?, msg: String?)
    fun w(tag: String?, t: Throwable?)
    fun w(tag: String?, msg: String?, t: Throwable?)
    fun e(msg: String?)
    fun e(tag: String?, msg: String?)
    fun e(tag: String?, t: Throwable?)
    fun e(tag: String?, msg: String?, t: Throwable?)
}
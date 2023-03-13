package com.jd.jdcache.util

import androidx.annotation.Keep

@Keep
interface ICancellable {
    fun cancel(msg: String? = null)
}
package com.jd.jdcache.entity

import android.text.TextUtils
import androidx.annotation.Keep
import kotlin.random.Random

@Keep
data class JDCacheModule(
    var configId: String = generateRandomId(),
    var url: String? = null,
    var urlType: Short = URL_TYPE_NORMAL,
    var createTime: Long = System.currentTimeMillis()
) {

    companion object {
        const val URL_TYPE_NORMAL: Short = 1
        const val URL_TYPE_REGEXP: Short = 2

        private fun generateRandomId(): String {
            return "${System.currentTimeMillis()}-${Random.nextInt(100, 1000)}"
        }
    }

    val isRegexpUrl: Boolean
        get() = (URL_TYPE_REGEXP == urlType && !TextUtils.isEmpty(url))

    override fun equals(other: Any?): Boolean {
        if (this === other) {
            return true
        }
        if (other == null || other !is JDCacheModule) {
            return false
        }
        return configId == other.configId
    }

    override fun hashCode(): Int {
        return configId.hashCode()
    }

}
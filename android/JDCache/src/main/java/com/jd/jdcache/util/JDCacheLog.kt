package com.jd.jdcache.util

import androidx.annotation.Keep
import com.jd.jdcache.JDCacheLogger
import com.jd.jdcache.JDCacheSetting

@Keep
inline fun log(block: (logger: JDCacheLog) -> Unit) {
    if (JDCacheLog.canLog) {
        block(JDCacheLog)
    }
}

@Keep
object JDCacheLog : JDCacheLogger {
    private const val LOG_HYBRID = "JDCache"

    var myLogger: JDCacheLogger? = null

    var canLog: Boolean = false
        private set
        get() = JDCacheSetting.debug || JDCacheSetting.getParamsProvider()?.showLog() == true

    /**
     * JDCacheLog.d
     */
    override fun d(msg: String?) {
        msg?.let { myLogger?.d(msg) ?: android.util.Log.d(LOG_HYBRID, msg) }
    }

    /**
     * JDCacheLog.d
     */
    override fun d(tag: String?, msg: String?) {
        msg?.let { myLogger?.d(tag, msg) ?: android.util.Log.d("$LOG_HYBRID-$tag", msg) }
    }

    /**
     * JDCacheLog.d
     */
    override fun d(tag: String?, t: Throwable?) {
        t?.let { myLogger?.d(tag, t) ?: android.util.Log.d("$LOG_HYBRID-$tag", t.message ?: "") }
    }

    /**
     * JDCacheLog.d
     */
    override fun d(tag: String?, msg: String?, t: Throwable?) {
        myLogger?.d(tag, msg, t) ?: android.util.Log.d("$LOG_HYBRID-$tag", msg, t)
    }

    /**
     * JDCacheLog.w
     */
    override fun w(msg: String?) {
        msg?.let { myLogger?.w(msg) ?: android.util.Log.w(LOG_HYBRID, msg) }
    }

    /**
     * JDCacheLog.w
     */
    override fun w(tag: String?, msg: String?) {
        msg?.let { myLogger?.w(tag, msg) ?: android.util.Log.w("$LOG_HYBRID-$tag", msg) }
    }

    /**
     * JDCacheLog.w
     */
    override fun w(tag: String?, t: Throwable?) {
        myLogger?.w(tag, t) ?: android.util.Log.w("$LOG_HYBRID-$tag", t)
    }

    /**
     * JDCacheLog.w
     */
    override fun w(tag: String?, msg: String?, t: Throwable?) {
        myLogger?.w(tag, msg, t) ?: android.util.Log.w("$LOG_HYBRID-$tag", msg, t)
    }

    /**
     * JDCacheLog.e
     */
    override fun e(msg: String?) {
        msg?.let { myLogger?.e(msg) ?: android.util.Log.e(LOG_HYBRID, msg) }
    }

    /**
     * JDCacheLog.e
     */
    override fun e(tag: String?, msg: String?) {
        msg?.let { myLogger?.e(tag, msg) ?: android.util.Log.e("$LOG_HYBRID-$tag", msg) }
    }

    /**
     * JDCacheLog.e
     */
    override fun e(tag: String?, t: Throwable?) {
        t?.let { myLogger?.e(tag, t) ?: android.util.Log.e("$LOG_HYBRID-$tag", t.message, t) }
    }

    /**
     * JDCacheLog.e
     */
    override fun e(tag: String?, msg: String?, t: Throwable?) {
        myLogger?.e(tag, msg, t) ?: android.util.Log.e("$LOG_HYBRID-$tag", msg, t)
    }

}
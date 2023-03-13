package com.jd.jdcache

import android.content.Context
import com.jd.jdcache.util.JDCacheLog.e
import com.jd.jdcache.util.log

internal object JDCacheSetting {
    var appContext: Context? = null
    var debug: Boolean = false
    var enable: Boolean = true

//    private var globalParamsClassChanged = AtomicBoolean(true)

    private var paramsProviderClass: Class<out JDCacheParamsProvider> = JDCacheParamsProvider::class.java

    fun setGlobalParamsClass(clazz: Class<out JDCacheParamsProvider>) {
        paramsProvider = null
//        globalParamsClassChanged.set(true)
        paramsProviderClass = clazz
    }

    private var paramsProvider: JDCacheParamsProvider? = null

    fun getParamsProvider(): JDCacheParamsProvider? {
        if (paramsProvider == null) {
            synchronized(this) {
                if (paramsProvider == null) {
                    try {
                        paramsProvider = paramsProviderClass.newInstance()
                    } catch (e: Throwable) {
                        //这里不套log{ }，因为会循环调用canLog方法
                        e("JDCacheSetting", "Error in creating global params", e)
                    }
                }
            }
        }
        return paramsProvider
    }


//    var paramsProvider: JDCacheParamsProvider? = null
//        private set
//        get() {
//            field = if (globalParamsClassChanged.compareAndSet(true, false)) {
//                try {
//                    paramsProviderClass.createInstance()
//                } catch (e: Exception) {
//                    log { e("JDCacheSetting", "Error in creating global params", e) }
//                    null
//                }
//            } else {
//                field
//            }
//            return field
//        }
}
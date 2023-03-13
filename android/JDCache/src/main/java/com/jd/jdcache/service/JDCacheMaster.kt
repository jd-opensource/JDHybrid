package com.jd.jdcache.service

import com.jd.jdcache.JDCacheLoader
import com.jd.jdcache.util.JDCacheLog.d
import com.jd.jdcache.util.log
import java.util.concurrent.ConcurrentHashMap

/**
 * hybrid逻辑中枢
 */
internal class JDCacheMaster private constructor() {

    private val loaderMap by lazy { ConcurrentHashMap<String, JDCacheLoader>() }

    //单例
    companion object {
        private const val TAG = "JDCacheMaster"
        @Volatile
        private var INSTANCE: JDCacheMaster? = null

        fun getInstance(): JDCacheMaster =
            //双重校验锁
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: JDCacheMaster().also { INSTANCE = it }
            }
    }

    init {
    }

//    fun addModule(config: JDCacheModule?) {
//        config?.let {
//            ConfigService.getInstance().save(config)
//        }
//    }
//
//    fun removeModule(config: JDCacheModule?) {
//        config?.let {
//            ConfigService.getInstance().delete(config)
//        }
//    }

    fun createDefaultLoader(url: String): JDCacheLoader {
        val id = System.currentTimeMillis().toString()
        val loader = JDCacheLoader(url, id).init()
        log { d(TAG, "Create new loader(id:${loader.key}) for ${loader.url}") }
        loaderMap[loader.key] = loader
        return loader
    }

    fun addLoader(loader: JDCacheLoader) {
        log { d(TAG, "Add new loader(id:${loader.key}) for ${loader.url}") }
        loaderMap[loader.key] = loader
    }

    fun getLoader(loaderKey: String): JDCacheLoader? {
        return loaderMap[loaderKey]
    }

    fun removeLoader(loaderKey: String): JDCacheLoader? {
        val removed = loaderMap.remove(loaderKey)
        log {
            removed?.let { d(TAG, "Remove loader(id:${removed.key})") }
        }
        return removed
    }
}
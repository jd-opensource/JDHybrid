package com.jd.jdcache

import com.jd.jdcache.service.JDCacheMaster
import com.jd.jdcache.match.ResourceMatcherManager
import android.content.Context
import androidx.annotation.Keep
import androidx.lifecycle.LifecycleOwner
import com.jd.jdcache.match.base.JDCacheResourceMatcher
import com.jd.jdcache.match.impl.MapResourceMatcher
import com.jd.jdcache.match.impl.PreloadHtmlMatcher
import com.jd.jdcache.service.DelegateManager
import com.jd.jdcache.service.base.AbstractDelegate
import com.jd.jdcache.service.impl.FileRepo
import com.jd.jdcache.service.impl.net.NetConnection
import com.jd.jdcache.util.JDCacheLog
import java.util.*

/**
 * 统一对外api集合类
 */
@Keep
object JDCache {

    private fun initInternal(context: Context){
        JDCacheSetting.appContext = context
        //服务代理
        registerService(NetConnection::class.java)
        registerService(FileRepo::class.java)
        //匹配规则
        registerDefaultResourceMatcher(PreloadHtmlMatcher::class.java)
        registerDefaultResourceMatcher(MapResourceMatcher::class.java)
    }

    /**
     * 初始化
     */
    fun init(context: Context, debug: Boolean = false) {
        JDCacheSetting.debug = debug
        initInternal(context)
    }

    fun getContext() : Context? {
        return JDCacheSetting.appContext
    }

    /**
     * 全局控制JDCache功能开关
     */
    fun enable(enable: Boolean) {
        JDCacheSetting.enable = enable
    }

    /**
     * 设置全局参数。
     * 必须：UserAgent、cookie。
     * 可选：存储路径、是否展示log、etc.
     */
    fun setGlobalParams(paramsProviderClazz: Class<out JDCacheParamsProvider>) {
        JDCacheSetting.setGlobalParamsClass(paramsProviderClazz)
    }

    /**
     * 获取全局参数。
     */
    fun getGlobalParams(): JDCacheParamsProvider?{
        return JDCacheSetting.getParamsProvider()
    }

    /**
     * 注册自定义匹配规则
     */
    fun registerDefaultResourceMatcher(matcherClazz: Class<out JDCacheResourceMatcher>) {
        if (!JDCacheSetting.enable) {
            return
        }
        ResourceMatcherManager.registerMatcher(matcherClazz)
    }

    /**
     * 移除自定义匹配规则
     */
    fun unregisterDefaultResourceMatcher(matcherClazz: Class<out JDCacheResourceMatcher>) {
        if (!JDCacheSetting.enable) {
            return
        }
        ResourceMatcherManager.unregisterMatcher(matcherClazz)
    }

    /**
     * 创建默认匹配规则实例列表
     */
    fun createDefaultResourceMatcherList(): LinkedList<JDCacheResourceMatcher> {
        if (!JDCacheSetting.enable) {
            return LinkedList<JDCacheResourceMatcher>()
        }
        return ResourceMatcherManager.createDefaultMatcherList()
    }

    /**
     * 注册各种服务
     * @param delegateClazz 具体服务的类，例如[FileRepo]
     */
    fun registerService(delegateClazz: Class<out AbstractDelegate>) {
        if (!JDCacheSetting.enable) {
            return
        }
        DelegateManager.addDelegateClass(delegateClazz)
    }

    /**
     * 获取服务
     * @param delegateType 服务类型，具体服务所需实现的类，例如[XCFileRepoDelegate]
     */
    fun <T : AbstractDelegate> getService(delegateType: Class<T>): T? {
        if (!JDCacheSetting.enable) {
            return null
        }
        return DelegateManager.getDelegate(delegateType)
    }

//    /**
//     * 设置离线文件（配置+目录）
//     */
//    @JvmStatic
//    fun addJDCacheModule(module: JDCacheModule?) {
//        JDCacheMaster.getInstance().addModule(module)
//    }

    /**
     * 创建加载器
     */
    fun createDefaultLoader(url: String?, lifecycleOwner: LifecycleOwner? = null): JDCacheLoader? {
        if (!JDCacheSetting.enable) {
            return null
        }
        val loader = url?.let { JDCacheMaster.getInstance().createDefaultLoader(url) }
        loader?.lifecycleOwner = lifecycleOwner
        return loader
    }

    fun LifecycleOwner.createDefaultLoader(url: String?): JDCacheLoader? = createDefaultLoader(url, this)

    /**
     * 获取加载器
     */
    fun getLoader(key: String?): JDCacheLoader? {
        if (!JDCacheSetting.enable) {
            return null
        }
        return key?.let { JDCacheMaster.getInstance().getLoader(key) }
    }

    /**
     * 获取加载器
     */
    fun getAndBindLoader(key: String?, lifecycleOwner: LifecycleOwner? = null): JDCacheLoader? {
        if (!JDCacheSetting.enable) {
            return null
        }
        val loader = key?.let { JDCacheMaster.getInstance().getLoader(key) }
        loader?.lifecycleOwner = lifecycleOwner
        return loader
    }

    fun LifecycleOwner.getAndBindLoader(key: String?): JDCacheLoader? = getAndBindLoader(key, this)

    fun removeLoader(key: String?) {
        if (!JDCacheSetting.enable) {
            return
        }
        key?.let {
            JDCacheMaster.getInstance().getLoader(key)?.destroy()
        }
    }

    fun setLogger(logger: JDCacheLogger?) {
        JDCacheLog.myLogger = logger
    }
}
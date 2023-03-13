package com.jd.jdcache

import android.os.Build
import android.text.TextUtils
import android.webkit.CookieManager
import android.webkit.CookieSyncManager
import androidx.annotation.Keep
import com.jd.jdcache.entity.JDCacheDataSource
import com.jd.jdcache.util.JDCacheLog.d
import com.jd.jdcache.util.log
import java.io.File

@Keep
abstract class JDCacheParamsProvider {
    abstract fun getUserAgent(url: String?): String?

    open val cacheDir: String?
        get() = File(JDCacheSetting.appContext!!.filesDir.path, "jdcache").absolutePath

    open fun showLog(): Boolean {
        return false
    }

    open fun getCookie(url: String?): String {
        val cookie = CookieManager.getInstance().getCookie(url)
        return cookie ?: ""
    }

    open fun saveCookie(url: String?, cookies: List<String?>): Boolean {
        val cookieManager = CookieManager.getInstance()
        if (!cookieManager.acceptCookie()) {
            return false
        }
        for (cookieSegment in cookies) {
            if (TextUtils.isEmpty(cookieSegment)) {
                continue
            }
            cookieManager.setCookie(url, cookieSegment)
            log { d("JDCacheParamsProvider", "set cookie: $cookieSegment") }
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            CookieSyncManager.createInstance(JDCacheSetting.appContext)
            CookieSyncManager.getInstance().sync()
        } else {
            CookieManager.getInstance().flush()
        }
        return true
    }

    /**
     * If you use default resource matcher the sdk provides,
     * you should override this method to return [JDCacheDataSource] for specific url.
     *
     * [JDCacheDataSource] helps [MapResourceMatcher] with locating offline files, so a
     * Map<String, JDCacheLocalResp> is needed to map each sub file's url to its relative path.
     * There are 4 ways set the map:
     * One is put a json file named "resource.json" in [JDCacheDataSource]'s offlineDirPath and
     * [JDCacheDataSource] will find the json itself during constructing.
     * The other three are setting sourceMap, sourceList, or sourceStr for [JDCacheDataSource].
     */
    open fun sourceWithUrl(url: String, loader: JDCacheLoader?): JDCacheDataSource? {
        return null
    }

//    open fun preloadHtmlUrl(originUrl: String): String? {
//        return originUrl
//    }
}
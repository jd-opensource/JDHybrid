package com.jd.jdcache.match.impl

import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import androidx.annotation.Keep
import androidx.annotation.WorkerThread
import com.jd.jdcache.JDCacheSetting
import com.jd.jdcache.entity.JDCacheDataSource
import com.jd.jdcache.entity.createResponse
import com.jd.jdcache.entity.jsonArrayParse
import com.jd.jdcache.match.base.JDCacheResourceMatcher
import com.jd.jdcache.util.*
import com.jd.jdcache.util.CoroutineHelper.launchCoroutine
import com.jd.jdcache.util.UrlHelper.urlToKey
import java.io.File

/**
 * 根据本地目录里的resource.json文件匹配。
 */
@Keep
open class MapResourceMatcher : JDCacheResourceMatcher() {

    override val name: String = "MapResourceMatcher"

    private var readMapTask: ICancellable? = null

    protected var dataSource: JDCacheDataSource? = null

    open fun getDataSource(url: String): JDCacheDataSource? {
        return JDCacheSetting.getParamsProvider()?.sourceWithUrl(url, loader)
    }

    override fun prepare(url: String) {
        dataSource = getDataSource(url)
        dataSource?.apply {
            if (localFileMap == null && localFileDirDetail.exists()) {
                readResMapFromJsonFile(
                    "${localFileDirDetail.path}${File.separator}resource.json")
            }
        }
    }

    @WorkerThread
    override fun match(request: WebResourceRequest): WebResourceResponse? {
        //todo wait for readResMapFromJsonFile
        val dataSource = this.dataSource ?: return null
        val localFile = dataSource.localFileMap?.get(request.url.urlToKey())
        if (localFile == null) {
//            log {
//                d(name,
//                    "[Web-Match] $name cannot find local file config for url[${request.url}], " +
//                            "may search config in next matcher if exists."
//                )
//            }
            return null
        }
        return localFile.createResponse(dataSource.localFileDirDetail.path)?.let { createResponse(it) }
    }

    private fun readResMapFromJsonFile(filePath: String) {
        val job = launchCoroutine {
            val fileContent = File(filePath).getString()
            dataSource?.localFileMap = jsonArrayParse(fileContent)
                ?.useful()
                ?.keyNonNullMap { it.url.urlToKey() }
        }
        readMapTask = CancellableJob(job)
    }

    override fun onDestroy() {
        super.onDestroy()
        readMapTask?.cancel()
    }
}
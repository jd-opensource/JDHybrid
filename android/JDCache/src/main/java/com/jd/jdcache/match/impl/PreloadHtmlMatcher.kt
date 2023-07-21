package com.jd.jdcache.match.impl

import android.net.Uri
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import androidx.annotation.Keep
import com.jd.jdcache.JDCacheConstant
import com.jd.jdcache.JDCacheSetting
import com.jd.jdcache.entity.JDCacheLocalResp
import com.jd.jdcache.entity.createResponse
import com.jd.jdcache.match.PreReadInputStream
import com.jd.jdcache.match.base.JDCacheResourceMatcher
import com.jd.jdcache.service.DelegateManager
import com.jd.jdcache.service.base.*
import com.jd.jdcache.util.*
import com.jd.jdcache.util.CoroutineHelper.launchCoroutine
import com.jd.jdcache.util.CoroutineHelper.runOnIo
import com.jd.jdcache.util.JDCacheLog.d
import com.jd.jdcache.util.JDCacheLog.e
import com.jd.jdcache.util.UrlHelper.convertHeader
import com.jd.jdcache.util.UrlHelper.matchHostPath
import com.jd.jdcache.util.log
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.channels.Channel.Factory.CONFLATED
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onEach
import java.io.BufferedInputStream
import java.io.File
import kotlin.Exception

/**
 * 预下载html文件然后匹配
 */
@Keep
open class PreloadHtmlMatcher : JDCacheResourceMatcher() {

    override val name: String = "PreloadHtmlMatcher"

    protected val fileRepo: JDCacheFileRepoDelegate? by lazy {
        DelegateManager.getDelegate<JDCacheFileRepoDelegate>()
    }

    protected var downloadUrl: String? = null

    protected var localResp: JDCacheLocalResp? = null

    protected var waitingChannel: Channel<JDCacheLocalResp>? = null

    protected var downloadTask: ICancellable? = null

//    protected var htmlFileStream: PreReadInputStream? = null
//    protected var htmlFileRelativePath: String? = null

    override fun prepare(url: String) {
        if (loader?.preloadHtml == true) {
            if (url.startsWith("http")) {
                downloadHtmlStream(url)
//              downloadHtmlFile(url)
            } else {
                log { d(name, "Will NOT perform preload HTML for non-HTTP url.") }
            }
        }
    }

    protected open fun downloadHtmlStream(url: String, header: MutableMap<String?, String>? = null) {
        downloadUrl = url
        val job = launchCoroutine {
            val saveOption = FileRequestOption(
                header = header,
                userAgent = JDCacheSetting.getParamsProvider()?.getUserAgent(url),
                cookie = JDCacheSetting.getParamsProvider()?.getCookie(url)
            )
            log { d(name, "Starting pre-download html($url)") }
            val state = fileRepo?.getInputStreamFromNet(url, saveOption)
            if (destroyed.get()) {
                return@launchCoroutine
            }
            if (state is InputStreamState.Connected) {
                log { d(name, "The pre-downloading html can be read now($url)") }
//                htmlFileStream = PreReadInputStream(BufferedInputStream(state.data))
//                htmlFileStream?.startPreRead()
                val stream = PreReadInputStream(BufferedInputStream(state.data))
                saveCookieFromRespHeaders(url, state.headers) //同步Set-Cookie
                val localResp = JDCacheLocalResp(url, "html")
                localResp.fileStream = stream
                localResp.header = state.headers?.convertHeader()?.toMutableMap()
                waitingChannel?.send(localResp)
                stream.startPreRead()
            } else if (state is InputStreamState.Error) {
                log {
                    e(
                        name, "Fail pre-downloading html, " +
                                "code=${state.code}, exception=${state.throwable}"
                    )
                }
            }
        }
        waitingChannel = Channel(CONFLATED)
        downloadTask = CancellableJob(job)
    }

    protected open fun downloadHtmlFile(url: String, header: MutableMap<String?, String>? = null) {
        downloadUrl = url
        val saveOption = FileSaveOption(
            header = header,
            userAgent = JDCacheSetting.getParamsProvider()?.getUserAgent(url),
            cookie = JDCacheSetting.getParamsProvider()?.getCookie(url)
        )
        val relativePath = "preload${File.separatorChar}${url.generateFileName()}"
        val flow = fileRepo?.saveFileFromNetFlow(url, relativePath, saveOption)?.map { fileState ->
            when (fileState) {
                is FileState.OnStart -> {
                    log { d(name, "Starting pre-download html($url)") }
                    null
                }
                is FileState.Complete -> {
                    log { d(name, "Complete pre-downloading html($url)") }
                    true to fileState
                }
                is FileState.Error -> {
                    log {
                        e(
                            name, "Fail pre-downloading html, " +
                                    "code=${fileState.code}, exception=${fileState.throwable}"
                        )
                    }
                    true to null
                }
                else -> null
            }
        }?.filterNotNull()?.onEach { (end, fileState) ->
            if (end) {
                downloadTask = null
            }
            if (fileState is FileState.Complete) {
                saveCookieFromRespHeaders(url, fileState.headers) //同步Set-Cookie
//                htmlFileRelativePath = relativePath
                val localResp = JDCacheLocalResp(url, "html")
                localResp.filename = fileState.data.absolutePath
//                localResp.fileStream = FileInputStream(fileState.data)
                localResp.header = fileState.headers?.convertHeader()?.toMutableMap()
                waitingChannel?.send(localResp)
            }
        }
        flow?.let {
            waitingChannel = Channel(CONFLATED)
            downloadTask = CancellableJob(flow.launchIn(JDCacheConstant.applicationScope))
        }
    }

    protected open fun saveCookieFromRespHeaders(url: String, headers: Map<String?, List<String?>>?){
        headers?.get("Set-Cookie")?.let {
            JDCacheSetting.getParamsProvider()?.saveCookie(url, it)
        }
    }

    override fun match(request: WebResourceRequest): WebResourceResponse? {
        if (loader?.preloadHtml != true) {
            //未开启html预下载，无需匹配
            return null
        }
        if (destroyed.get()) {
            return null
        }
        if (!request.isForMainFrame) {
            //非html，无需匹配
            return null
        }
        var downloadUri: Uri? = null
        downloadUrl?.let {
            try {
                downloadUri = Uri.parse(downloadUrl)
            } catch (ignored: Exception) {
            }
        }
        if (downloadUri == null || !request.url.matchHostPath(downloadUri)) {
            //与下载的url不对应，无需匹配
            return null
        }
        downloadUrl = null //使用一次后不能再被使用
        if (localResp == null) {
            //未获取到才尝试去获取
//            htmlFileStream?.finishPreRead()
            localResp = geDownloadLocalResp()
            if (destroyed.get()) {
                return null
            }
            localResp?.fileStream?.let {
                if (it is PreReadInputStream) {
                    it.finishPreRead() //若是走stream返回类型的，通知其停止预读
                }
            }
            log {
                if (localResp != null) {
                    d(name, "Received pre-download html file. $localResp")
                }
            }
        }
        return localResp?.createResponse()?.let { createResponse(it) }
    }

    protected open fun geDownloadLocalResp() : JDCacheLocalResp?{
        return waitingChannel?.let {
            if (!it.isClosedForReceive) {
                runBlocking {
                    try {
                        log { d(name, "Waiting for receiving pre-download html file.") }
                        //等待下载完成
                        withTimeout(2000L) {
                            it.receive()
                        }
                    } catch (e: TimeoutCancellationException) {
                        log { d(name, "Timeout in receiving pre-download html file.") }
                        null
                    } catch (e: Exception) {
                        log { e(name, "Error in receiving pre-download html file, e = $e") }
                        null
                    }
                }
            } else {
                null
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        waitingChannel?.let {
            it.cancel()
            waitingChannel = null
        }
        downloadTask?.let {
            it.cancel()
            downloadTask = null
        }

        val fileStream = localResp?.fileStream
        fileStream?.let {
            if (it !is PreReadInputStream || !it.isClosed()) {
                launchCoroutine {
                    runOnIo {
                        try {
                            @Suppress("BlockingMethodInNonBlockingContext")
                            it.close()
                        } catch (e: Throwable) {
                            log { e(name, e) }
                        }
                    }
                }
            }
        }
        localResp?.filename?.let { fileRepo?.deleteFile(it) }
    }
}
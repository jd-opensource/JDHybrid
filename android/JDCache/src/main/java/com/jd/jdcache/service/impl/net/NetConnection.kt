package com.jd.jdcache.service.impl.net

import androidx.annotation.Keep
import com.jd.jdcache.service.base.NetState
import com.jd.jdcache.service.base.JDCacheNetDelegate
import com.jd.jdcache.util.JDCacheLog.e
import com.jd.jdcache.util.log
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.toList
import java.io.File
import java.io.InputStream
import java.lang.Exception
import java.net.HttpURLConnection

@Keep
open class NetConnection : JDCacheNetDelegate() {

    override val name: String = "NetConnection"

    /**
     * 请求接口，返回String类型
     */
    override fun requestFlow(
        url: String,
        method: String,
        header: MutableMap<String?, String>?,
        userAgent: String?,
        cookie: String?,
        body: MutableMap<String, String>?,
        followRedirect: Boolean
    ): Flow<NetState<String>>? {

        if (url.isEmpty()) {
            log { e(name, "Cannot start network request, because url is empty.") }
            return null
        }
        val request = HttpRequest(url)
        request.method = method
        request.header = header
        request.userAgent = userAgent
        request.cookies = cookie
        request.body = body
        request.allowRedirect = followRedirect

        return request.connectFlow()
    }

    /**
     * 请求接口，连接上则马上返回，返回InputStream
     */
    override fun connectFlow(
        url: String,
        method: String,
        header: MutableMap<String?, String>?,
        userAgent: String?,
        cookie: String?,
        body: MutableMap<String, String>?,
        followRedirect: Boolean
    ): Flow<NetState<InputStream?>>? {

        if (url.isEmpty()) {
            log { e(name, "Cannot start network connection, because url is empty.") }
            return null
        }
        val request = object : BaseRequest<InputStream?>(url){
            override val TAG: String
                get() = "InputStreamRequest"

            override suspend fun parseData(
                responseCode: Int,
                responseHeaders: Map<String?, List<String?>>?,
                contentLength: Long,
                inputStream: InputStream?
            ): NetState<InputStream?> {
                return if (responseCode == HttpURLConnection.HTTP_OK) {
                    val callbackStream = inputStream?.let {
                        CallbackInputStream(inputStream, object : CallbackInputStream.StreamCallback {
                            override fun onClose() {
                                //when outside closes the stream, disconnect connection
                                disconnect()
                            }
                        })
                    }
                    NetState.Complete(
                        responseCode,
                        responseHeaders,
                        contentLength,
                        callbackStream)
                } else {
                    NetState.Error(responseCode, Exception("Net Error code = $responseCode"))
                }
            }
        }
        request.method = method
        request.header = header
        request.userAgent = userAgent
        request.cookies = cookie
        request.body = body
        request.allowRedirect = followRedirect

        return request.connectFlow()
    }

    override fun downloadFlow(
        url: String,
        savePath: String,
        method: String,
        header: MutableMap<String?, String>?,
        userAgent: String?,
        cookie: String?,
        followRedirect: Boolean
    ): Flow<NetState<File>>? {
        if (url.isEmpty()) {
            log { e(name, "Cannot download file, because url is empty.") }
            return null
        }
        if (savePath.isEmpty()) {
            log { e(name, "Cannot download file[$url], because savePath is empty.") }
            return null
        }
        val request = FileRequest(url, savePath)
        request.method = method
        request.header = header
        request.userAgent = userAgent
        request.cookies = cookie
        request.allowRedirect = followRedirect
        return request.connectFlow()
    }

}
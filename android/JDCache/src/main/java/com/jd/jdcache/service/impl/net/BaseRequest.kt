package com.jd.jdcache.service.impl.net

import android.net.Uri
import android.os.Build
import com.jd.jdcache.JDCacheConstant
import com.jd.jdcache.service.base.NetState
import com.jd.jdcache.util.JDCacheLog.e
import com.jd.jdcache.util.UrlHelper.METHOD_DELETE
import com.jd.jdcache.util.UrlHelper.METHOD_GET
import com.jd.jdcache.util.UrlHelper.METHOD_HEAD
import com.jd.jdcache.util.UrlHelper.METHOD_PATCH
import com.jd.jdcache.util.UrlHelper.METHOD_POST
import com.jd.jdcache.util.UrlHelper.METHOD_PUT
import com.jd.jdcache.util.JDCacheLog.d
import com.jd.jdcache.util.log
import kotlinx.coroutines.flow.*
import java.io.IOException
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.util.zip.GZIPInputStream
import javax.net.ssl.HttpsURLConnection

abstract class BaseRequest<T>(
    var url: String,
    var method: String = METHOD_GET,
    var userAgent: String? = null,
    var cookies: String? = null,
    var header: MutableMap<String?, String>? = null,
    var params: Map<String, String>? = null,
    var body: Map<String, String>? = null,
    var allowRedirect: Boolean = true,
    var referer: String? = null,
    var connectTimeout: Int = 5 * 1000,
    var readTimeout: Int = 5 * 1000
) {

    companion object {
        const val HEAD_KEY_CONNECTION = "Connection"
        const val HEAD_VALUE_CONNECTION_KEEP_ALIVE = "keep-alive"
        const val HEAD_VALUE_CONNECTION_CLOSE = "close"

        const val HEAD_KEY_CONTENT_ENCODING = "Content-Encoding"

        const val HEAD_KEY_COOKIE = "Cookie"
        const val HEAD_KEY_USER_AGENT = "User-Agent"
        const val HEAD_KEY_REFERER = "Referer"
    }

    abstract val TAG: String

    var connection: HttpURLConnection? = null

    var requestUrl: String = url
        private set
        get() {
            val params = this.params
            if (params?.isNotEmpty() == true) {
                val builder = Uri.parse(url).buildUpon()
                for (key in params.keys) {
                    builder.appendQueryParameter(key, URLEncoder.encode(params[key], "UTF-8"))
                }
                return builder.build().toString()
            }
            return url
        }

    private var flowCollector: FlowCollector<NetState<T>>? = null

    private val ioDispatcher = JDCacheConstant.ioDispatcher

    /**
     * It is implementation's responsibility to close stream and disconnect at the right time.
     */
    protected abstract suspend fun parseData(
        responseCode: Int,
        responseHeaders: Map<String?, List<String?>>?,
        contentLength: Long,
        inputStream: InputStream?
    ): NetState<T>

    protected suspend fun notifyProgress(progress: Long, length: Long) {
        flowCollector?.emit(NetState.OnProgress(progress, length))
    }

    @Suppress("BlockingMethodInNonBlockingContext")
    fun connectFlow(): Flow<NetState<T>> {
        return flow {
            flowCollector = this
            val url = URL(requestUrl)
            emit(connect(url))
        }.onStart {
            emit(NetState.OnStart(requestUrl))
        }.catch { e ->
            log { e(TAG, e) }
            emit(NetState.Error(-1, e))
//            onError(-1, e)
        }.flowOn(ioDispatcher)
    }

    @Suppress("BlockingMethodInNonBlockingContext")
    @Throws(Exception::class)
    protected suspend fun connect(url: URL): NetState<T> {
        val connection = url.openConnection() as HttpURLConnection
        this.connection = connection
        connection.connectTimeout = connectTimeout
        connection.readTimeout = readTimeout
        connection.instanceFollowRedirects = allowRedirect
        if (connection is HttpsURLConnection) {
            connection.sslSocketFactory = SSLUtils.defaultSSLSocketFactory()
            connection.hostnameVerifier = SSLUtils.defaultHostnameVerifier(url)
        }
        connection.requestMethod = method
        connection.doInput = true
        if (isAllowBody()) {
            connection.doOutput = true
            writeBody(connection)
        }
        val header = this.header ?: HashMap()
        header[HEAD_KEY_CONNECTION] = HEAD_VALUE_CONNECTION_KEEP_ALIVE
        for (key in header.keys) {
            connection.setRequestProperty(key, header[key])
        }
        cookies?.let { connection.setRequestProperty(HEAD_KEY_COOKIE, it) }
        userAgent?.let { connection.setRequestProperty(HEAD_KEY_USER_AGENT, it) }
        referer?.let { connection.setRequestProperty(HEAD_KEY_REFERER, it) }

        connection.connect()

        val responseCode = connection.responseCode
        when {
            responseCode == 301
                    || responseCode == 302
                    || responseCode == 303
                    || responseCode == 307
                    || responseCode == 308 -> {
                // redirect connection
                val location = connection.getHeaderField("Location")
                connection.inputStream?.close()
                return NetState.Redirect(
                    responseCode,
                    connection.headerFields,
                    location
                )
            }
            responseCode !in 100..199
                    && responseCode != 204
                    && responseCode != 205
                    && responseCode !in 300..399 -> {
                // successful connection, code may be 2xx, 4xx, 5xx
                val inputStream =
                    if (method != METHOD_HEAD) getServerStream(responseCode, connection) else null
                val length: Long = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N)
                    connection.contentLengthLong
                else connection.contentLength.toLong()
                return parseData(
                    responseCode,
                    connection.headerFields,
                    length,
                    inputStream
                )
            }
            else -> {
                return NetState.Error(
                    responseCode,
                    Exception("Http Error: " + connection.responseMessage)
                )
            }
        }
    }

    fun disconnect() {
        log { d(TAG, "connection.disconnect() called") }
        connection?.disconnect()
    }

//    private fun getRequestMethod(): String {
//        return when (method) {
//            METHOD_POST -> {
//                "POST"
//            }
//            METHOD_PUT -> {
//                "PUT"
//            }
//            METHOD_DELETE -> {
//                "DELETE"
//            }
//            METHOD_HEAD -> {
//                "HEAD"
//            }
//            METHOD_PATCH -> {
//                "PATCH"
//            }
//            METHOD_OPTIONS -> {
//                "OPTIONS"
//            }
//            METHOD_TRACE -> {
//                "TRACE"
//            }
//            else -> {
//                "GET"
//            }
//        }
//    }

    private fun isAllowBody(): Boolean {
        return when (method) {
            METHOD_POST, METHOD_PUT, METHOD_PATCH, METHOD_DELETE -> true
            else -> false
        }
    }

    @Throws(IOException::class)
    protected fun writeBody(connection: HttpURLConnection) {
        val body = this.body
        if (body?.isNotEmpty() == true) {
            val sb = StringBuilder()
            for (key in body.keys) {
                sb.append("&").append(key).append("=")
                    .append(URLEncoder.encode(body[key], "UTF-8"))
            }
            sb.deleteCharAt(0)
            val ops = connection.outputStream
            ops.write(sb.toString().toByteArray())
            ops.flush()
            ops.close()
        }
    }

    @Throws(IOException::class)
    private fun getServerStream(
        responseCode: Int,
        connection: HttpURLConnection
    ): InputStream {
        val contentEncoding = connection.getHeaderField(HEAD_KEY_CONTENT_ENCODING)
        return if (responseCode >= HttpURLConnection.HTTP_BAD_REQUEST) {
            // 4xx or 5xx
            getErrorStream(contentEncoding, connection)
        } else {
            // 2xx
            getInputStream(contentEncoding, connection)
        }
    }

    @Throws(IOException::class)
    private fun getInputStream(
        contentEncoding: String?,
        urlConnection: HttpURLConnection
    ): InputStream {
        val inputStream = urlConnection.inputStream
        return gzipInputStream(contentEncoding, inputStream)
    }

    @Throws(IOException::class)
    private fun getErrorStream(
        contentEncoding: String?,
        urlConnection: HttpURLConnection
    ): InputStream {
        val inputStream = urlConnection.errorStream
        return gzipInputStream(contentEncoding, inputStream)
    }

    @Throws(IOException::class)
    private fun gzipInputStream(
        contentEncoding: String?,
        inputStream: InputStream
    ): InputStream {
        var inputStream = inputStream
        if (isGzipContent(contentEncoding)) {
            inputStream = GZIPInputStream(inputStream)
        }
        return inputStream
    }

    private fun isGzipContent(contentEncoding: String?): Boolean {
        return contentEncoding != null && contentEncoding.contains("gzip")
    }

}
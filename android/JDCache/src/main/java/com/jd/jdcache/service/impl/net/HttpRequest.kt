package com.jd.jdcache.service.impl.net

import com.jd.jdcache.service.base.NetState
import com.jd.jdcache.util.JDCacheLog.e
import com.jd.jdcache.util.UrlHelper.METHOD_HEAD
import com.jd.jdcache.util.log
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStream
import java.io.InputStreamReader
import java.lang.StringBuilder
import java.net.HttpURLConnection
import kotlin.Exception

class HttpRequest(url: String) : BaseRequest<String>(url) {

    override val TAG: String = "HttpRequest"

    @Suppress("BlockingMethodInNonBlockingContext")
    override suspend fun parseData(
        responseCode: Int,
        responseHeaders: Map<String?, List<String?>>?,
        contentLength: Long,
        inputStream: InputStream?
    ): NetState<String> {
        var result: StringBuilder? = null
        var br: BufferedReader? = null
        if (method != METHOD_HEAD && inputStream != null) {
            result = StringBuilder()
            br = BufferedReader(InputStreamReader(inputStream))
            try {
                var readLine: String?
                while (br.readLine().also { readLine = it } != null) {
                    result.append(readLine)
                    result.append("\n")
                }
            } catch (e: Exception) {
                return NetState.Error(-1, e)
            }
        }
        val netResult = if (responseCode == HttpURLConnection.HTTP_OK) {
            NetState.Complete(
                responseCode,
                responseHeaders,
                contentLength,
                result?.toString() ?: "")
        } else {
            NetState.Error<String>(responseCode, Exception(br?.toString() ?: ""))
        }
        try {
            if (br != null) {
                br.close()
            } else inputStream?.close()
        } catch (e: IOException) {
            log { e(TAG, e) }
        }
        disconnect()
        return netResult
    }

}
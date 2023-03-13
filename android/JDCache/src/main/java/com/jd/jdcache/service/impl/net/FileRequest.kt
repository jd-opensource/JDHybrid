package com.jd.jdcache.service.impl.net

import com.jd.jdcache.JDCacheConstant.NET_READ_BUFFER_SIZE
import com.jd.jdcache.service.base.NetState
import com.jd.jdcache.util.JDCacheLog.e
import com.jd.jdcache.util.UrlHelper.METHOD_HEAD
import com.jd.jdcache.util.log
import java.io.*
import java.net.HttpURLConnection
import kotlin.Exception

class FileRequest(url: String, val targetPath: String) : BaseRequest<File>(url) {

    override val TAG: String = "FileRequest"

    @Suppress("BlockingMethodInNonBlockingContext")
    override suspend fun parseData(
        responseCode: Int,
        responseHeaders: Map<String?, List<String?>>?,
        contentLength: Long,
        inputStream: InputStream?
    ): NetState<File> {
        val state = if (responseCode == HttpURLConnection.HTTP_OK) {
            var bufferedOutputStream: BufferedOutputStream? = null
            try {
                if (method != METHOD_HEAD) {
                    if (inputStream == null) {
                        return NetState.Error(-1, Exception("Response stream is null!"))
                    }
                    notifyProgress(0, contentLength)
                    File(targetPath).parentFile?.mkdirs()
                    val fos = FileOutputStream(targetPath, false)
                    bufferedOutputStream = BufferedOutputStream(fos)
                    val buffer = ByteArray(NET_READ_BUFFER_SIZE)
                    var currentSize = 0L
                    var hasRead = 0
                    while (inputStream.read(buffer).also { hasRead = it } != -1) {
                        bufferedOutputStream.write(buffer, 0, hasRead)
                        currentSize += hasRead
                        notifyProgress(currentSize, contentLength)
                    }
                    bufferedOutputStream.flush()
                }
                NetState.Complete(
                    responseCode,
                    responseHeaders,
                    contentLength,
                    File(targetPath))
            } catch (e: Exception) {
                log { e(TAG, e) }
                NetState.Error<File>(-1, Exception("Write file error: " + e.message))
            } finally {
                try {
                    bufferedOutputStream?.close()
                } catch (e: IOException) {
                    log { e(TAG, e) }
                }
            }
        } else {
            NetState.Error<File>(responseCode, Exception("Response code is not 200"))
        }
        try {
            inputStream?.close()
        } catch (e: IOException) {
            log { e(TAG, e) }
        }
        disconnect()
        return state
    }

}
package com.jd.jdcache.match

import androidx.annotation.Keep
import com.jd.jdcache.JDCacheConstant.NET_READ_BUFFER_SIZE
import com.jd.jdcache.util.JDCacheLog.d
import com.jd.jdcache.util.JDCacheLog.e
import com.jd.jdcache.util.log
import java.io.*
import java.lang.Exception
import java.util.concurrent.atomic.AtomicBoolean

/**
 * An inputStream can read into memory in advance. When [read] called,
 * read pre-read memory data first, then the unread data.
 * [finishPreRead] must be called before [read] this stream.
 */
@Keep
class PreReadInputStream(
    unreadStream: BufferedInputStream
) : InputStream() {

    private companion object {
        const val TAG = "PreReadInputStream"
    }

    /**
     * unread stream, usually the data stream from net,
     * used to combined with the [readStream] in [read].
     */
    private var unreadStream: BufferedInputStream? = null

    /**
     * stream which is read before, used to combined with [unreadStream] in [read].
     */
    private var readStream: BufferedInputStream? = null

    /**
     * data already read from [unreadStream], used to create [readStream].
     */
    private var readData: ByteArrayOutputStream? = null

    private var unreadStreamFinish = true

    private var readStreamFinish = true

    private val preReadStarted = AtomicBoolean(false)

    private val preReadStopPoint = AtomicBoolean(false)

    private val closed = AtomicBoolean(false)

    init {
        this.unreadStream = unreadStream
        this.unreadStreamFinish = false
    }

    fun isClosed(): Boolean {
        return closed.get()
    }

    /**
     * Call this when you would like to start pre-read the stream
     */
    fun startPreRead() {
        val unreadStream = this.unreadStream ?: return
        if (!preReadStarted.compareAndSet(false, true)) {
            log { e(TAG, "Pre-read already started, cannot start twice.") }
            return
        }
        try {
            val readData = ByteArrayOutputStream()
            this.readData = readData
            val buffer = ByteArray(NET_READ_BUFFER_SIZE)
            var count = 0
            synchronized(this) {
                log { d(TAG, "Start to pre-read stream.") }
                while (!preReadStopPoint.get() && unreadStream.read(buffer).also { count = it } != -1) {
                    readData.write(buffer, 0, count) //容量自增长
                }
                if (-1 == count) {
                    unreadStreamFinish = true
                    finishPreRead()
                }
            }
        } catch (e: Exception) {
            log { e(TAG, "Pre-read stream error", e) }
        }
    }

    /**
     * Must call this before you [read] this stream.
     */
    fun finishPreRead() {
        if (preReadStopPoint.compareAndSet(false, true)) {
            log { d(TAG, "Pre-read stream finished.") }
            synchronized(this) {
                readData?.let {
                    readStream = BufferedInputStream(ByteArrayInputStream(it.toByteArray()))
                    readStreamFinish = false
                    log { d(TAG, "Pre-read data size=${readData?.size()}, " +
                            "unreadStreamFinish = $unreadStreamFinish") }
                }
            }
        }
    }

    override fun read(): Int {
        var c = -1
        try {
            if (!readStreamFinish) {
                c = readStream?.read() ?: -1
                log {
                    if (-1 == c) {
                        d(TAG, "Read from readStream finished.")
                    }
                }
            }
            if (-1 == c) {
                readStreamFinish = true
                if (!unreadStreamFinish) {
                    c = unreadStream?.read() ?: -1
                    if (-1 == c) {
                        unreadStreamFinish = true
                        log { d(TAG, "Read from unreadStream finished.") }
                    }
                }
            }
        } catch (e: Throwable) {
            log { e(TAG, e) }
            if (e is IOException) {
                throw e
            } else { //Turn all exceptions to IO exceptions to prevent scenes that the kernel can not capture
                throw IOException(e)
            }
        }

        return c
    }

    override fun close() {
        if (!closed.compareAndSet(false, true)) {
            return
        }
        preReadStopPoint.set(true) //停止预读
        log { d(TAG, "close pre-read stream, " +
                "readStreamFinish = $readStreamFinish, " +
                "unreadStreamFinish = $unreadStreamFinish") }
        var error: Throwable? = null
        readStream?.let {
            try {
                it.close()
            } catch (e: Throwable) {
                error = e
            } finally {
                readStream = null
            }
        }
        unreadStream?.let {
            try {
                it.close()
            } catch (e: Throwable) {
                error = e
            } finally {
                unreadStream = null
            }
        }
        readData = null
        if (error != null) {
            log { e(TAG, error) }
            if (error is IOException) {
                throw error as IOException
            } else { // Turn all exceptions to IO exceptions to prevent scenes that the kernel can not capture
                throw IOException(error)
            }
        }
    }
}
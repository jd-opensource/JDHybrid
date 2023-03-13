package com.jd.jdcache.service.impl.net

import java.io.InputStream

internal class CallbackInputStream(
    val stream: InputStream,
    val callback: StreamCallback?
) : InputStream() {

    override fun read(): Int {
        return stream.read()
    }

    override fun read(b: ByteArray?): Int {
        return stream.read(b)
    }

    override fun read(b: ByteArray?, off: Int, len: Int): Int {
        return stream.read(b, off, len)
    }

    override fun skip(n: Long): Long {
        return stream.skip(n)
    }

    override fun available(): Int {
        return stream.available()
    }

    override fun mark(readlimit: Int) {
        stream.mark(readlimit)
    }

    override fun reset() {
        stream.reset()
    }

    override fun markSupported(): Boolean {
        return stream.markSupported()
    }

    override fun close() {
        stream.close()
        callback?.onClose()
    }

    interface StreamCallback {
        fun onClose()
    }
}
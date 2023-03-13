package com.jd.jdcache.service.impl.net

import android.os.Build
import java.io.IOException
import java.lang.AssertionError
import java.net.InetAddress
import java.net.Socket
import java.net.URL
import java.security.GeneralSecurityException
import java.security.SecureRandom
import javax.net.ssl.*

object SSLUtils {
    fun defaultSSLSocketFactory(): SSLSocketFactory {
        return TLSSocketFactory()
    }

    fun defaultHostnameVerifier(url: URL): HostnameVerifier {
        return HostVerifier(url)
    }
}

class HostVerifier(val url: URL) : HostnameVerifier {
    /**
     * Verify that the host name is an acceptable match with
     * the server's authentication scheme.
     *
     * @param hostname the host name
     * @param session SSLSession used on the connection to host
     * @return true if the host name is acceptable
     */
    override fun verify(hostname: String?, session: SSLSession?): Boolean {
        return HttpsURLConnection.getDefaultHostnameVerifier().verify(url.host, session)
    }
}

class TLSSocketFactory : SSLSocketFactory {
    companion object {
        private val PROTOCOL_ARRAY: Array<String> = when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O -> {
                arrayOf("TLSv1", "TLSv1.1", "TLSv1.2")
            }
            else -> {
                arrayOf("SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2")
            }
        }

        private fun setSupportProtocolAndCipherSuites(socket: Socket) {
            if (socket is SSLSocket) {
                socket.enabledProtocols = PROTOCOL_ARRAY
            }
        }

    }

    private var delegate: SSLSocketFactory

    constructor() {
        delegate = try {
            val sslContext = SSLContext.getInstance("TLS")
            sslContext.init(null, null, SecureRandom())
            sslContext.socketFactory
        } catch (e: GeneralSecurityException) {
            throw AssertionError() // The system has no TLS. Just give up.
        }
    }

    constructor(factory: SSLSocketFactory) {
        delegate = factory
    }

    override fun getDefaultCipherSuites(): Array<String> {
        return delegate.defaultCipherSuites
    }

    override fun getSupportedCipherSuites(): Array<String> {
        return delegate.supportedCipherSuites
    }

    @Throws(IOException::class)
    override fun createSocket(s: Socket, host: String, port: Int, autoClose: Boolean): Socket {
        val ssl = delegate.createSocket(s, host, port, autoClose)
        setSupportProtocolAndCipherSuites(ssl)
        return ssl
    }

    @Throws(IOException::class)
    override fun createSocket(host: String, port: Int): Socket {
        val ssl = delegate.createSocket(host, port)
        setSupportProtocolAndCipherSuites(ssl)
        return ssl
    }

    @Throws(IOException::class)
    override fun createSocket(
        host: String,
        port: Int,
        localHost: InetAddress,
        localPort: Int
    ): Socket {
        val ssl = delegate.createSocket(host, port, localHost, localPort)
        setSupportProtocolAndCipherSuites(ssl)
        return ssl
    }

    @Throws(IOException::class)
    override fun createSocket(host: InetAddress, port: Int): Socket {
        val ssl = delegate.createSocket(host, port)
        setSupportProtocolAndCipherSuites(ssl)
        return ssl
    }

    @Throws(IOException::class)
    override fun createSocket(
        address: InetAddress,
        port: Int,
        localAddress: InetAddress,
        localPort: Int
    ): Socket {
        val ssl = delegate.createSocket(address, port, localAddress, localPort)
        setSupportProtocolAndCipherSuites(ssl)
        return ssl
    }

    @Throws(IOException::class)
    override fun createSocket(): Socket {
        val ssl = delegate.createSocket()
        setSupportProtocolAndCipherSuites(ssl)
        return ssl
    }
}
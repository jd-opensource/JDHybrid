package com.jd.jdcache.service.base

import androidx.annotation.Keep
import com.jd.jdcache.util.JDCacheLog.e
import com.jd.jdcache.util.UrlHelper.METHOD_GET
import com.jd.jdcache.util.log
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.toList
import java.io.File
import java.io.InputStream
import java.lang.Exception

@Keep
abstract class JDCacheNetDelegate : AbstractDelegate() {

    /**
     * 请求接口，返回String类型
     */
    abstract fun requestFlow(
        url: String,
        method: String = METHOD_GET,
        header: MutableMap<String?, String>? = null,
        userAgent: String? = null,
        cookie: String? = null,
        body: MutableMap<String, String>? = null,
        followRedirect: Boolean = true
    ): Flow<NetState<String>>?

    /**
     * 请求接口，返回String类型
     */
    open suspend fun request(
        url: String,
        method: String = METHOD_GET,
        header: MutableMap<String?, String>? = null,
        userAgent: String? = null,
        cookie: String? = null,
        body: MutableMap<String, String>? = null,
        followRedirect: Boolean = true
    ): NetState<String>? {
        return try {
            requestFlow(url, method, header, userAgent, cookie, body, followRedirect)?.toList()?.last()
        } catch (e: Exception) {
            log { e(name, e) }
            null
        }
    }

    /**
     * 请求接口，连接上则马上返回，返回InputStream
     */
    abstract fun connectFlow(
        url: String,
        method: String = METHOD_GET,
        header: MutableMap<String?, String>? = null,
        userAgent: String? = null,
        cookie: String? = null,
        body: MutableMap<String, String>? = null,
        followRedirect: Boolean = true
    ): Flow<NetState<InputStream?>>?

    /**
     * 请求接口，连接上则马上返回，返回InputStream
     */
    open suspend fun connect(
        url: String,
        method: String = METHOD_GET,
        header: MutableMap<String?, String>? = null,
        userAgent: String? = null,
        cookie: String? = null,
        body: MutableMap<String, String>? = null,
        followRedirect: Boolean = true
    ): NetState<InputStream?>? {
        return try {
            connectFlow(url, method, header, userAgent, cookie, body, followRedirect)?.toList()?.last()
        } catch (e: Exception) {
            log { e(name, e) }
            null
        }
    }

    /**
     * 下载文件，返回File
     */
    abstract fun downloadFlow(
        url: String,
        savePath: String,
        method: String = METHOD_GET,
        header: MutableMap<String?, String>? = null,
        userAgent: String? = null,
        cookie: String? = null,
        followRedirect: Boolean = true
    ): Flow<NetState<File>>?

    /**
     * 下载文件，返回File
     */
    open suspend fun download(
        url: String,
        savePath: String,
        method: String = METHOD_GET,
        header: MutableMap<String?, String>? = null,
        userAgent: String? = null,
        cookie: String? = null,
        followRedirect: Boolean = true
    ): NetState<File>? {
        return try {
            downloadFlow(url, savePath, method, header, userAgent, cookie, followRedirect)?.toList()?.last()
        } catch (e: Exception) {
            log { e(name, e) }
            null
        }
    }

//    /**
//     * 下载文件。
//     * java使用者可实现此方法
//     */
//    open fun downloadWithCallback(
//        url: String,
//        savePath: String,
//        method: String = METHOD_GET,
//        header: MutableMap<String?, String>? = null,
//        userAgent: String? = null,
//        cookie: String? = null,
//        lifecycleOwner: LifecycleOwner? = null,
//        stateCallback: ((NetState<File>) -> Unit)? = null
//    ): ICancellable? {
//        TODO(
//            "If you choose to implement this callback type function, you also need to " +
//                    "implement <download> function which returns a flow. " +
//                    "You can use the convertor <downloadCallbackToFlow>."
//        )
//    }
//
//    /**
//     * downloadWithCallback方法转flow的实现
//     */
//    protected fun downloadCallbackToFlow(
//        url: String,
//        savePath: String,
//        method: String = METHOD_GET,
//        header: MutableMap<String?, String>? = null,
//        userAgent: String? = null,
//        cookie: String? = null
//    ): Flow<NetState<File>> {
//        return callbackFlow {
//            val cancellable = downloadWithCallback(
//                url, savePath,
//                method, header,
//                userAgent, cookie
//            ) {
//                try {
//                    sendBlocking(it)
//                    if (it is NetState.Redirect || it is NetState.Complete || it is NetState.Error) {
//                        close()
//                    }
//                } catch (e: Throwable) {
//                    log {
//                        e(
//                            name, "Error in converting callback to flow" +
//                                    "(JDCacheNetDelegate#downloadFlow)", e
//                        )
//                    }
//                }
//            }
//            if (cancellable != null) {
//                awaitClose { cancellable.cancel() }
//            } else {
//                close()
//            }
//        }
//    }

}

/**
 * 网络回调状态
 */
@Keep
sealed class NetState<T> {

    //起始态
    @Keep
    data class OnStart<T>(val url: String) : NetState<T>()

    //中间态
    @Keep
    data class OnProgress<T>(
        val progress: Long,
        val max: Long
    ) : NetState<T>()

    //结束态1
    @Keep
    data class Redirect<T>(
        val code: Int,
        val headers: Map<String?, List<String?>?>?,
        val location: String?
    ) : NetState<T>()

    //结束态2
    @Keep
    data class Error<T>(
        val code: Int,
        val throwable: Throwable?
    ) : NetState<T>()

    //结束态3
    @Keep
    data class Complete<T>(
        val code: Int,
        val headers: Map<String?, List<String?>>?,
        val length: Long,
        val data: T
    ) : NetState<T>()

    override fun toString(): String {
        return when (this) {
            is OnStart -> "NetResult[OnStart] url: $url"
//            is Connected -> "NetResult[Connected, code=$code]"
            is OnProgress -> "NetResult[OnProgress] $progress/$max"
            is Complete<*> -> "NetResult[Complete, code=$code] data: $data"
            is Error -> "NetResult[Error, code=$code] exception: ${throwable?.message}]"
            is Redirect -> "NetResult[Redirect, code=$code] location: $location"
        }
    }
}
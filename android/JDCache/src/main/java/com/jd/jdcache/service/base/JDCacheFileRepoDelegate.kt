package com.jd.jdcache.service.base

import androidx.annotation.Keep
import com.jd.jdcache.service.DelegateManager
import com.jd.jdcache.util.JDCacheLog.e
import com.jd.jdcache.util.UrlHelper.METHOD_GET
import com.jd.jdcache.util.log
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.toList
import java.io.File
import java.io.InputStream
import java.lang.Exception

@Keep
abstract class JDCacheFileRepoDelegate : AbstractDelegate() {

    protected val netDelegate: JDCacheNetDelegate? by lazy {
        DelegateManager.getDelegate<JDCacheNetDelegate>()
    }

    abstract fun getInputStreamFromNetFlow(
        url: String,
        option: FileRequestOption? = null
    ) : Flow<InputStreamState>?

    open suspend fun getInputStreamFromNet(
        url: String,
        option: FileRequestOption? = null
    ) : InputStreamState? {
        return try {
            getInputStreamFromNetFlow(url, option)?.toList()?.last()
        } catch (e: Exception) {
            log { e(name, e) }
            null
        }
    }

    abstract fun saveFileFromNetFlow(
        url: String,
        relativeFilePath: String,
        option: FileSaveOption? = null
    ): Flow<FileState>?

    open suspend fun saveFileFromNet(
        url: String,
        relativeFilePath: String,
        option: FileSaveOption? = null
    ): FileState? {
        return try {
            saveFileFromNetFlow(url, relativeFilePath, option)?.toList()?.last()
        } catch (e: Exception) {
            log { e(name, e) }
            null
        }
    }

//    open fun saveFileFromNetWithCallback(
//        url: String,
//        relativeFilePath: String,
//        lifecycleOwner: LifecycleOwner? = null,
//        option: FileSaveOption? = null,
//        stateCallback: ((FileState) -> Unit)?
//    ): ICancellable? {
//        TODO(
//            "If you choose to implement this callback type function, you also need to " +
//                    "implement <download> function which returns a flow. " +
//                    "You can use the convertor <downloadCallbackToFlow>."
//        )
//    }

    abstract suspend fun saveFileFromAsset(
        assetFilePath: String,
        relativeFilePath: String,
        option: FileSaveOption? = null
    ): FileState?

    abstract fun deleteRelativeFile(relativeFilePath: String): Boolean
    abstract fun getRelativeFile(relativeFilePath: String): File

    abstract fun deleteFile(absoluteFilePath: String): Boolean

//    /**
//     * downloadWithCallback方法转flow的实现
//     */
//    protected fun saveFileFromNetCallbackToFlow(
//        url: String,
//        relativeFilePath: String,
//        option: FileSaveOption? = null
//    ): Flow<FileState> {
//        return callbackFlow {
//            val cancellable = saveFileFromNetWithCallback(url, relativeFilePath, option = option) {
//                try {
//                    sendBlocking(it)
//                    if (it is FileState.Complete || it is FileState.Error) {
//                        close()
//                    }
//                } catch (e: Throwable) {
//                    log {
//                        JDCacheLog.e(
//                            name, "Error in converting callback to flow" +
//                                    "(JDCacheFileRepoDelegate#saveFileFromNetCallbackToFlow)", e
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

@Keep
open class FileRequestOption(
    var method: String = METHOD_GET,
    val header: MutableMap<String?, String>? = null,
    val userAgent: String? = null,
    val cookie: String? = null,
    val allowRedirect: Boolean = true
)

@Keep
open class FileSaveOption(
    method: String = METHOD_GET,
    header: MutableMap<String?, String>? = null,
    userAgent: String? = null,
    cookie: String? = null,
    allowRedirect: Boolean = true,
    val needUnzip: Boolean = false,
    val unzipDir: String? = null,
    val split: Boolean = false,
    val mergeWithFile: String? = null
) : FileRequestOption(method, header, userAgent, cookie, allowRedirect)

@Keep
sealed class FileState {

    @Keep
    data class OnStart(val url: String) : FileState()

    @Keep
    data class OnProgress(
        val progress: Long,
        val max: Long
    ) : FileState()

    @Keep
    data class Error(
        val code: Int,
        val throwable: Throwable?
    ) : FileState()

    @Keep
    data class Complete(
        val code: Int,
        val length: Long,
        val headers: Map<String?, List<String?>>?,
        val data: File
    ) : FileState()

    override fun toString(): String {
        return when (this) {
            is OnStart -> "FileState[OnStart] url: $url"
            is OnProgress -> "FileState[OnProgress] $progress/$max"
            is Complete -> "FileState[Complete, code=$code] path: ${data.path}"
            is Error -> "FileState[Error, code=$code] exception: ${throwable?.message}]"
        }
    }
}

@Keep
sealed class InputStreamState {

    @Keep
    data class OnStart(val url: String) : InputStreamState()

    @Keep
    data class Error(
        val code: Int,
        val throwable: Throwable?
    ) : InputStreamState()

    @Keep
    data class Connected(
        val code: Int,
        val headers: Map<String?, List<String?>>?,
        val data: InputStream?
    ) : InputStreamState()

    override fun toString(): String {
        return when (this) {
            is Connected -> "InputStreamState[Connected, code=$code]"
            is Error -> "InputStreamState[Error, code=$code] exception: ${throwable?.message}]"
            is OnStart -> "InputStreamState[OnStart]"
        }
    }
}
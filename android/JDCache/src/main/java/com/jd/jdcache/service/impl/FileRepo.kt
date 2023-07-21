package com.jd.jdcache.service.impl

import android.content.Context
import androidx.annotation.Keep
import com.jd.jdcache.JDCacheConstant.LOCAL_READ_BUFFER_SIZE
import com.jd.jdcache.JDCacheSetting
import com.jd.jdcache.service.base.*
import com.jd.jdcache.util.CoroutineHelper.runOnIo
import com.jd.jdcache.util.UrlHelper.METHOD_GET
import com.jd.jdcache.util.JDCacheLog.d
import com.jd.jdcache.util.JDCacheLog.e
import com.jd.jdcache.util.log
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.io.*

@Keep
open class FileRepo : JDCacheFileRepoDelegate() {

    override val name: String = "FileRepo"

    protected val rootDirPath: String by lazy {
        JDCacheSetting.getParamsProvider()?.cacheDir ?: throw RuntimeException(
            "Cache dir need to be set by JDCacheParamsProvider"
        )
    }

    override fun getInputStreamFromNetFlow(
        url: String,
        option: FileRequestOption?
    ): Flow<InputStreamState>? {
        return netDelegate?.connectFlow(
            url,
            option?.method ?: METHOD_GET,
            option?.header,
            option?.userAgent,
            option?.cookie,
            followRedirect = option?.allowRedirect?:true
        )?.map { netState ->
            when(netState) {
                is NetState.Complete -> {
                    val fileInputStream = if (netState.data != null) {
                        BufferedInputStream(netState.data)
                    } else {
                        null
                    }
                    InputStreamState.Connected(netState.code, netState.headers, fileInputStream)
                }
                is NetState.OnStart -> InputStreamState.OnStart(netState.url)
                is NetState.Error -> InputStreamState.Error(netState.code, netState.throwable)
                is NetState.OnProgress -> InputStreamState.Error(-1,
                    RuntimeException("This state[NetState.OnProgress] should not show up for InputStreamState"))
                is NetState.Redirect -> InputStreamState.Error(netState.code, RuntimeException("Connection redirects."))
            }
        }
    }

    override fun saveFileFromNetFlow(
        url: String,
        relativeFilePath: String,
        option: FileSaveOption?
    ): Flow<FileState>? {
        if (relativeFilePath.isEmpty()) {
            log { e(name, "Cannot save file to empty path.") }
            return null
        }
        var lastProgress = 0f

        return netDelegate?.downloadFlow(
            url,
            concretePath(relativeFilePath),
            option?.method ?: METHOD_GET,
            option?.header,
            option?.userAgent,
            option?.cookie,
            followRedirect = option?.allowRedirect?:true
        )?.map { netState ->
            when (netState) {
                is NetState.OnStart -> {
                    log {
                        d(
                            name,
                            "Starting downloading file[$url]."
                        )
                    }
                    FileState.OnStart(url)
                }
                is NetState.Complete -> {
                    log {
                        d(
                            name,
                            "Complete downloading file[$url] in ${netState.data.path}."
                        )
                    }
                    FileState.Complete(
                        netState.code,
                        netState.length,
                        netState.headers,
                        netState.data
                    )
                }
                is NetState.OnProgress -> {
                    if (netState.max > 0) {
                        log {
                            val percent = netState.progress / netState.max.toFloat()
                            if (percent == 1f || percent - lastProgress >= 10f)
                                lastProgress = percent
                            d(
                                name,
                                "Downloading file(${percent * 100}%)"
                            )
                        }
                    }
                    FileState.OnProgress(netState.progress, netState.max)
                }
                is NetState.Error -> {
                    log {
                        e(
                            name,
                            "Error in downloading file[$url]. " +
                                    "Code = ${netState.code}, " +
                                    "Exception = ${netState.throwable}"
                        )
                    }
                    FileState.Error(netState.code, netState.throwable)
                }
                is NetState.Redirect -> {
                    log {
                        e(
                            name,
                            "Redirect in downloading file[$url]"
                        )
                    }
                    FileState.Error(-1, Exception("Redirect in downloading file"))
                }
            }
        }
    }

    @Suppress("BlockingMethodInNonBlockingContext")
    override suspend fun saveFileFromAsset(
        assetFilePath: String,
        relativeFilePath: String,
        option: FileSaveOption?
    ): FileState? {
        if (assetFilePath.isEmpty()) {
            return FileState.Error(-1, IllegalArgumentException("Asset path is empty."))
        }
        if (relativeFilePath.isEmpty()) {
            return FileState.Error(-1, IllegalArgumentException("Destination path is empty."))
        }
        val context = JDCacheSetting.appContext
            ?: return FileState.Error(-1, RuntimeException("Application context is null."))

        return runOnIo {
            val list = context.assets.list(assetFilePath)
            if (list.isNullOrEmpty()) {
                copyFileFromAsset(context, assetFilePath, concretePath(relativeFilePath))
            } else {
                val destPath = concretePath(relativeFilePath)
                var failNum = 0
                list.forEach {
                    if (copyFileFromAsset(
                            context,
                            assetFilePath + File.separator + it,
                            destPath + File.separator + it
                        ) is FileState.Error
                    ) {
                        failNum++
                    }
                }
                if (failNum == list.size) {
                    FileState.Error(-1, RuntimeException("Fail to copy files from directory."))
                } else {
                    log {
                        if (failNum > 0) {
                            e(
                                name, "Partially succeed to save file(s) from asset, " +
                                        "$failNum file(s) fails"
                            )
                        }
                    }
                    FileState.Complete(0, 0, null, File(destPath))
                }
            }
        }
    }

    private fun copyFileFromAsset(
        context: Context,
        assetFilePath: String,
        destPath: String
    ): FileState {
        var inputStream: InputStream? = null
        var fos: FileOutputStream? = null
        try {
            inputStream = context.assets.open(assetFilePath)
            val buffer = ByteArray(LOCAL_READ_BUFFER_SIZE)
            var length: Long = 0
            var read: Int
            val destFile = File(destPath)
            destFile.parentFile?.mkdirs()
            fos = FileOutputStream(destFile)
            while (inputStream.read(buffer).also { read = it } > -1) {
                fos.write(buffer, 0, read)
                length += read
            } //FileOutputStream没有使用buffer，不需flush
            return FileState.Complete(0, length, null, destFile)
        } catch (e: java.lang.Exception) {
            log { e(name, e) }
            return FileState.Error(-1, e)
        } finally {
            try {
                fos?.close()
                inputStream?.close()
            } catch (e: IOException) {
                log { e(name, e) }
            }
        }
    }

    override fun deleteRelativeFile(relativeFilePath: String): Boolean {
        return deleteFile(File(concretePath(relativeFilePath)))
    }

    override fun getRelativeFile(relativeFilePath: String): File {
        return File(concretePath(relativeFilePath))
    }

    override fun deleteFile(absoluteFilePath: String): Boolean {
        if (absoluteFilePath.isEmpty()) {
            return false
        }
        return deleteFile(File(absoluteFilePath))
    }

    private fun concretePath(relativePath: String?): String {
        if (relativePath.isNullOrBlank()) {
            return rootDirPath
        }
        return rootDirPath + File.separatorChar +
                relativePath.trimStart { it == File.separatorChar }
    }

    private fun deleteFile(file: File?): Boolean {
        if (file?.exists() != true) {
            return false
        }
        if (file.isDirectory) {
            val children = file.listFiles() ?: return true
            for (child in children) {
                deleteFile(child)
            }
        }
        return file.delete()
    }

}
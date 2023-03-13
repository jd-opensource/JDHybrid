package com.jd.jdcache.util

import com.jd.jdcache.util.CoroutineHelper.runOnIo
import com.jd.jdcache.util.UrlHelper.getFileNameFromUrl
import com.jd.jdcache.util.JDCacheLog.e
import java.io.File
import java.io.FileNotFoundException
import kotlin.random.Random


suspend fun File?.getString(): String? {
    return this?.let {
        if (!it.exists() || !it.isFile) {
            null
        } else {
            runOnIo {
                try {
                    it.readText()
                } catch (e: FileNotFoundException) {
                    log { e("FileHelper", e) }
                    null
                }
            }
        }
    }
}

/**
 * 根据url获取文件名,若不存在,则手动生成文件名
 */
internal fun String?.generateFileName(): String {
    return this?.getFileNameFromUrl().let {
        val randomStr = "${System.currentTimeMillis()}${Random.nextInt(900) + 100}"
        if (it.isNullOrEmpty()) {
            randomStr
        } else {
            "${it}_${randomStr}"
        }
    }
}
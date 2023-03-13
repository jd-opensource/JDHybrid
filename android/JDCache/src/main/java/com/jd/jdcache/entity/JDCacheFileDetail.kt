package com.jd.jdcache.entity

import androidx.annotation.Keep
import java.io.File

@Keep
data class JDCacheFileDetail constructor(
    /** 文件路径 */
    var path: String,
    /**
     * 上次修改时间
     */
    var lastModified: Long = 0,
    /**
     * 文件大小
     */
    var totalSpace: Long = 0
) {

    constructor(file: File) : this(file.absolutePath, file.lastModified(), file.totalSpace)

    fun exists(): Boolean {
        val file = File(path)
        return file.exists()
    }

    fun hasChanged(): Boolean {
        val file = File(path)
        return !file.exists() || file.lastModified() != lastModified
    }

}
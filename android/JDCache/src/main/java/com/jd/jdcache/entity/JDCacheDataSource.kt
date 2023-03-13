package com.jd.jdcache.entity

import androidx.annotation.Keep
import com.jd.jdcache.JDCacheSetting
import com.jd.jdcache.util.UrlHelper.urlToKey
import com.jd.jdcache.util.keyNonNullMap
import com.jd.jdcache.util.useful
import java.io.File

@Keep
data class JDCacheDataSource constructor(
    var localFileDirDetail: JDCacheFileDetail,
    var localFileMap: HashMap<String, JDCacheLocalResp>? = null
) {

    /**
     * Using the given data to build a JDCacheDataSource,
     * will convert into a map where key is in "host/path" format.
     *
     * @param offlineDirPath the offline directory's absolute path
     * @param sourceList1 List of JDCacheLocalResp
     * @param sourceList2 List of Triple<url, type, sub file's relative path>
     * @param sourceStr json array: {
     *  "url":"https://a.b.com/c/d/e.html", //url
     *  "type":"html", // html/script/stylesheet/image or other
     *  "filename":"xxx.html" // sub file's path relative to offlineDirPath
     * }, {}, {}...
     */
    constructor(
        offlineDirPath: String,
        isRelativePath: Boolean = false,
        sourceList1: List<JDCacheLocalResp>? = null,
        sourceList2: List<Triple<String, String, String>>? = null,
        sourceStr: String? = null
    ) : this(
        JDCacheFileDetail(
            if (isRelativePath) {
                File(JDCacheSetting.getParamsProvider()?.cacheDir
                    ?.plus(File.separator + offlineDirPath)
                        ?: throw RuntimeException("Cache dir need to be set by JDCacheParamsProvider"))
            } else {
                File(offlineDirPath)
            }
        )
    ) {
        when {
            sourceList1 != null -> {
                setSourceList1(sourceList1)
            }
            sourceList2 != null -> {
                setSourceList2(sourceList2)
            }
            sourceStr != null -> {
                setSourceStr(sourceStr)
            }
//            else -> {
//                if (localFileDirDetail.exists()) {
//                    readJsonListFromFile(
//                        "${localFileDirDetail.path}${File.separator}resource.json")
//                }
//            }
        }
    }

//    private fun readJsonListFromFile(filePath: String, lifecycleOwner: LifecycleOwner? = null) {
//        launchCoroutine(lifecycleOwner?.lifecycleScope) {
//            val fileContent = File(filePath).getString()
//            if (localFileMap != null) {
//                return@launchCoroutine
//            }
//            localFileMap = fileContent
//                    ?.jsonParse<MutableList<JDCacheLocalResp>>()
//                    ?.useful()
//                    ?.keyNonNullMap { it.url.urlToKey() }
//        }
//    }

    private fun setSourceList1(sourceList: List<JDCacheLocalResp>){
        localFileMap = sourceList.toMutableList().useful().keyNonNullMap { it.url.urlToKey() }
    }

    private fun setSourceList2(sourceList: List<Triple<String, String, String>>) {
        localFileMap = sourceList
            .mapTo(ArrayList(sourceList.size)) { (url, type, filename) ->
                JDCacheLocalResp(url, type, filename = filename)
            }.useful()
            .keyNonNullMap { it.url.urlToKey() }
    }

    private fun setSourceStr(sourceStr: String){
        localFileMap = jsonArrayParse(sourceStr)
            .useful()
            .keyNonNullMap { it.url.urlToKey() }
    }

}

package com.jd.jdcache.entity

import android.webkit.WebResourceResponse
import androidx.annotation.Keep
import com.jd.jdcache.util.IUsefulCheck
import com.jd.jdcache.util.JDCacheLog.e
import com.jd.jdcache.util.log
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.io.File
import java.io.FileInputStream
import java.io.InputStream

@Keep
data class JDCacheLocalResp(
    val url: String,
    val type: String,
    @JvmField var header: MutableMap<String?, String>? = null,
    var filename: String? = null,
    @Transient var fileStream: InputStream? = null,
    @Transient val needSafeChangeHeader: Boolean = true
)  : IUsefulCheck {

    init {
        if (needSafeChangeHeader) {
            safeChangeHeader()
        }
    }

    fun setHeader(header: MutableMap<String?, String>?) {
        this.header = header
        if (needSafeChangeHeader) {
            safeChangeHeader()
        }
    }

    fun getHeader(): MutableMap<String?, String>? {
        return header
    }

    /**
     * 将原header的key转换为驼峰格式
     */
    private fun safeChangeHeader() {
        this.header = header?.mapKeys {
                (key, _) -> key?.let { toUpperCamelCase(key, '-') }
        } as MutableMap<String?, String>?
    }

    /**
     * 转换成第一个大写的驼峰格式，不剔除分隔符，例如：content-type变成Content-Type
     */
    @Suppress("SameParameterValue")
    private fun toUpperCamelCase(text: String, delimiter: Char): String {
        var shouldConvertNextCharToUpper = true
        val builder = StringBuilder()
        for (element in text) {
            when {
                element == delimiter -> {
                    builder.append(element)
                    shouldConvertNextCharToUpper = true
                }
                shouldConvertNextCharToUpper -> {
                    builder.append(Character.toUpperCase(element))
                    shouldConvertNextCharToUpper = false
                }
                else -> {
                    builder.append(Character.toLowerCase(element))
                }
            }
        }
        return builder.toString()
    }

    override fun useful(): Boolean {
        return !filename.isNullOrEmpty() || fileStream != null
    }

    override fun toString(): String {
        return toJson().toString()
    }

    fun toJson(): JSONObject {
        val json = JSONObject()
        json.put("url", url)
        json.put("type", type)
        filename?.let { json.put("filename", filename) }
        fileStream?.let { json.put("fileStream", fileStream) }
        header?.let {
            val headerJson = JSONObject()
            it.forEach { entry ->
                val key = entry.key ?: "null"
                headerJson.put(key, entry.value)
            }
            json.put("header", headerJson)
        }
        return json
    }
}

@Keep
fun JDCacheLocalResp.createResponse(fileDirPath: String? = null): WebResourceResponse? {
    val fileResp = this
    var mimeType: String
    var encoding: String? = null
    val contentType: String? = fileResp.header?.get("Content-Type")
    if (!contentType.isNullOrBlank()) {
        // header有类型的话，做mimeType的设置。注意
        // html的mime不能设置为空，会识别不了然后跳去下载流程(现象可能是打开系统浏览器)
        mimeType = contentType
        val types = contentType.split(";")
        if (!types.isNullOrEmpty() && types.size > 1) {
            mimeType = types[0]
            if (types[1].contains("charset=")) {
                encoding = types[1].trim().replace("charset=", "")
            }
        }
    } else {
        mimeType = when (fileResp.type) {
            "script" -> {
                "text/txt"
            }
            "stylesheet" -> {
                "text/css"
            }
            "image" -> {
                "image/*"
            }
            "html" -> {
                "text/html"
            }
            else -> {
                "text/html"
            }
        }
    }

    //优先使用已经存在的InputStream
    var inputStream = fileResp.fileStream

    if (inputStream == null) {
        val filePath = filename?.let {
            fileDirPath?.let { dirPath ->
                dirPath + File.separator + filename
            } ?: filename
        }
        val canUsePath = if (!filePath.isNullOrBlank()) {
            val file = File(filePath)
            file.exists() && file.isFile
        } else false

        inputStream = if (canUsePath) FileInputStream(filePath) else null
    }

    if (inputStream == null) {
        log {
            e(
                "JDCacheLocalResp",
                "Error in creating response from JDCacheLocalResp, " +
                        "filePath or inputStream cannot be null."
            )
        }
        return null
    }

    val resp = WebResourceResponse(mimeType, encoding, inputStream)
    resp.responseHeaders = fileResp.header
    return resp
}

@Keep
fun jsonParse(jsonString: String?) : JDCacheLocalResp? {
    if (jsonString.isNullOrEmpty()) {
        return null
    }
    try {
        val json = JSONObject(jsonString)
        val url: String = json.getString("url")
        val type: String = json.getString("type")
        val header: MutableMap<String?, String>? = json.optJSONObject("header")?.let {
            val map = HashMap<String?, String>()
            it.keys().forEach { key ->
                map[key] = it.getString(key)
            }
            map
        }
        val filename: String? = json.getString("filename")
        return JDCacheLocalResp(url, type, header, filename)
    } catch (e: JSONException) {
        log { e("JDCacheLocalResp", e) }
        return null
    }
}

@Keep
fun jsonArrayParse(jsonString: String?) : MutableList<JDCacheLocalResp>? {
    if (jsonString.isNullOrEmpty()) {
        return null
    }
    try {
        val jsonArray = JSONArray(jsonString)
        val list = ArrayList<JDCacheLocalResp>()
        if (jsonArray.length() > 0) {
            val length = jsonArray.length()
            for (i in 0 until length) {
                val item = jsonParse(jsonArray[i].toString())
                item?.let {
                    list.add(it)
                }
            }
        }
        return list
    } catch (e: JSONException) {
        log { e("JDCacheLocalResp", e) }
        return null
    }
}

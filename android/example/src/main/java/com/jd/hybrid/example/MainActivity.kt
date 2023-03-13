/*
 * MIT License
 *
 * Copyright (c) 2022 JD.com, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */
package com.jd.hybrid.example

import android.annotation.SuppressLint
import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.webkit.WebView
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.jd.jdcache.JDCacheLoader
import com.jd.jdcache.JDCache
import com.jd.jdcache.match.base.JDCacheResourceMatcher
import com.jd.jdcache.service.base.FileState
import com.jd.jdcache.service.base.JDCacheFileRepoDelegate
import com.jd.jdcache.util.CoroutineHelper.launchCoroutine
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.atomic.AtomicInteger

class MainActivity : AppCompatActivity() {

    companion object {
        private const val TAG = "MainActivity"
    }

    private var loaderKey: String? = null
    private var preloadUrlHash: AtomicInteger = AtomicInteger(0)
    private var preDownloadJob: Job? = null
    private lateinit var tvLog: TextView

    private val url: String
        get() = Setting.settingData.url

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_main)
        setSupportActionBar(findViewById(R.id.toolbar))

        tvLog = findViewById(R.id.tvLog)
        findViewById<Button>(R.id.preload).setOnClickListener(::preload)
        findViewById<Button>(R.id.openSysWeb).setOnClickListener(::openSysWeb)
        findViewById<Button>(R.id.openJDCacheWeb).setOnClickListener(::openJDCacheWeb)
        findViewById<Button>(R.id.openJDBridgeWeb).setOnClickListener(::openJDBridgeWeb)
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.main, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        if (item.itemId == R.id.action_settings) {
            startActivity(Intent(this, SettingActivity::class.java))
            return true
        }
        return super.onOptionsItemSelected(item)
    }

    @SuppressLint("SetTextI18n")
    private fun showLog(log: String, gapLine: Int = 0){
        runOnUiThread {
            val gapLineStr = if (gapLine > 0) {
                val line = StringBuilder()
                for (i in 1..gapLine) {
                    line.append("\n")
                }
                line
            } else {
                ""
            }
            tvLog.text = "[${SimpleDateFormat.getTimeInstance().format(Date())}]" +
                    "$log\n$gapLineStr${tvLog.text}"
        }
    }

    private fun preload(v: View) {
        //提前获取loader
        url.let { url ->
            if (MyApplication.userAgent.isNullOrEmpty()) {
                val uaWebView = WebView(this)
                MyApplication.userAgent = uaWebView.settings.userAgentString
            }
            val newUrlHash = url.hashCode()
            val oldUrlHash = preloadUrlHash.getAndSet(newUrlHash)
            if (oldUrlHash != newUrlHash) {
                // finish previous preload process
                loaderKey?.apply {
                    JDCache.removeLoader(loaderKey)
                    loaderKey = null
                }
                preDownloadJob?.apply {
                    if (!isCompleted) {
                        cancel(CancellationException("Switch to download another url."))
                    }
                }
                // start a new preload process
                // you can save the web's resources before loading and let the loader use them
                if (!preDownloadFiles(url)){
                    createJDCacheLoader(url)
                }
            } else {
                showLog("Preload has been started.", 2)
            }
        }
    }

    private fun openSysWeb(v: View) {
        val intent = Intent(this, WebActivity::class.java)
        intent.putExtra("pageType", "system")
        intent.putExtra("url", url)
        startActivity(intent)
    }

    private fun openJDCacheWeb(v: View) {
        val intent = Intent(this, WebActivity::class.java)
        intent.putExtra("pageType", "JDCache")
        intent.putExtra("url", url)
        //获取或创建loader
        val loader = JDCache.getLoader(loaderKey) ?: createJDCacheLoader(url)
        loader?.key.let {
            //把key传给WebActivity
            intent.putExtra("loaderKey", it)
        }
        loaderKey = null
        preloadUrlHash.set(0)
        startActivity(intent)
    }

    private fun openJDBridgeWeb(v: View) {
        val intent = Intent(this, WebActivity::class.java)
        intent.putExtra("pageType", "JDBridge")
        intent.putExtra("url", url)
        startActivity(intent)
    }

    private fun createJDCacheLoader(url: String): JDCacheLoader? {
        if (!Setting.settingData.enableJDCache) {
            return null
        }
        // create loader, it may preload html if loader's preload is set to true
        // normally, you can use JDCache.createDefaultLoader(url)
        // to get a new loader with default matchers
        val preloadHtml = Setting.settingData.preloadHtml
        val loader = JDCacheLoader(url, matcherList = createJDCacheMatcherList())
        loader.preloadHtml = preloadHtml
        loader.init()
        if (preloadHtml) {
            showLog("Start to preload HTML file ($url)...")
        }
        loaderKey = loader.key
        return loader
    }

    private fun createJDCacheMatcherList(): List<JDCacheResourceMatcher> {
        val matcherList = JDCache.createDefaultResourceMatcherList()
        if (Setting.settingData.useCustomMatcher) {
            matcherList.addFirst(MyMatcher())
        }
        return matcherList
    }

    /**
     * This will copy resource files from asset into app's data folder.
     * It is to simulate the process of downloading resources from net.
     *
     * @return true: pre-download files started, false otherwise.
     */
    private fun preDownloadFiles(url: String): Boolean {
        var assetFile: String? = null
        var destFileDir: String? = null
        when(url){
            MyHybridParamsProvider.DEMO_PRELOAD_URL1 -> {
                assetFile = MyHybridParamsProvider.DEMO_PRELOAD_FILE1_ASSET
                destFileDir = MyHybridParamsProvider.DEMO_PRELOAD_FILE1_DIR
            }
            MyHybridParamsProvider.DEMO_PRELOAD_URL2 -> {
                assetFile = MyHybridParamsProvider.DEMO_PRELOAD_FILE2_ASSET
                destFileDir = MyHybridParamsProvider.DEMO_PRELOAD_FILE2_DIR
            }
        }
        if (assetFile.isNullOrEmpty() || destFileDir.isNullOrEmpty()) {
            // Only this website has local files in asset.
            // You can produce these files using web project in nodejs directory.
            showLog("There is no resource can be downloaded for this url ($url)", 2)
            return false
        }
        showLog("Start to download resources for ($url)...", 2)
        preDownloadJob = launchCoroutine{
            doPreDownload(url, assetFile, destFileDir)
            createJDCacheLoader(url)
            preDownloadJob = null
        }
        return true
    }

    private suspend fun doPreDownload(url: String, assetFile: String, destFileDir: String){
        val fileRepo = JDCache.getService(JDCacheFileRepoDelegate::class.java)
        fileRepo?.deleteRelativeFile(destFileDir)
        val state = fileRepo?.saveFileFromAsset(assetFile, destFileDir)
        if (state is FileState.Complete) {
            showLog("Download finished successfully.")
        } else {
            showLog("Download failed.")
        }
    }
}
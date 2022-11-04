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
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : AppCompatActivity() {

    companion object {
        private const val TAG = "MainActivity"
    }

    private lateinit var tvLog: TextView

    private val url: String
        get() = Setting.settingData.url

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_main)
        setSupportActionBar(findViewById(R.id.toolbar))

        tvLog = findViewById(R.id.tvLog)
        findViewById<Button>(R.id.openSysWeb).setOnClickListener(::openSysWeb)
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

    private fun openSysWeb(v: View) {
        val intent = Intent(this, WebActivity::class.java)
        intent.putExtra("pageType", "system")
        intent.putExtra("url", url)
        startActivity(intent)
    }

    private fun openJDBridgeWeb(v: View) {
        val intent = Intent(this, WebActivity::class.java)
        intent.putExtra("pageType", "JDBridge")
        intent.putExtra("url", url)
        startActivity(intent)
    }
}
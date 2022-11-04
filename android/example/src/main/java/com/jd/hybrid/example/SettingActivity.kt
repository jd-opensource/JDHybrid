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

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.view.View
import android.widget.RadioGroup
import com.google.android.material.radiobutton.MaterialRadioButton
import com.google.android.material.switchmaterial.SwitchMaterial
import com.google.android.material.textfield.TextInputEditText

class SettingActivity : AppCompatActivity() {

    private lateinit var groupUrl: RadioGroup
    private lateinit var checkUrl0: MaterialRadioButton
    private lateinit var checkUrl1: MaterialRadioButton
    private lateinit var checkUrl2: MaterialRadioButton
    private lateinit var checkUrl3: MaterialRadioButton
    private lateinit var etUrl: TextInputEditText

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_setting)
        setSupportActionBar(findViewById(R.id.toolbar))

        supportActionBar?.setDisplayHomeAsUpEnabled(true)

        init()
    }

    private fun init() {

        groupUrl = findViewById(R.id.rg_url)
        checkUrl0 = findViewById(R.id.url0)
        checkUrl1 = findViewById(R.id.url1)
        checkUrl2 = findViewById(R.id.url2)
        checkUrl3 = findViewById(R.id.url_below)
        etUrl = findViewById(R.id.url_et)

        checkUrl3.setOnCheckedChangeListener { _, isChecked ->
            etUrl.isEnabled = isChecked
        }

        loadSetting()
    }

    private fun loadSetting() {
        val setting = Setting.settingData
        val checkUrlId = when (setting.urlIndex) {
            1 -> R.id.url1
            2 -> R.id.url2
            3 -> R.id.url_below
            else -> R.id.url0
        }
        groupUrl.check(checkUrlId)
        if (groupUrl.checkedRadioButtonId == R.id.url_below) {
            etUrl.setText(setting.url)
        }
    }

    private fun saveSetting() {
        val urlIndex: Int
        val url: String
        when (groupUrl.checkedRadioButtonId) {
            R.id.url1 -> {
                urlIndex = 1
                url = checkUrl1.text.toString()
            }
            R.id.url2 -> {
                urlIndex = 2
                url = checkUrl2.text.toString()
            }
            R.id.url_below -> {
                urlIndex = 3
                url = etUrl.text.toString()
            }
            else -> {
                urlIndex = 0
                url = checkUrl0.text.toString()
            }
        }
        Setting.settingData = Setting.SettingData(
            urlIndex,
            url
        )
    }

    override fun onDestroy() {
        saveSetting()
        super.onDestroy()
    }

}
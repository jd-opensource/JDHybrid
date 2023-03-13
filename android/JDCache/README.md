> [简体中文文档](README-zh-CN.md)

# XCache - Android

## UML

![XCacheUML](../doc/jdcache_process.md)

## Dependencies

Add XCache as a dependency in your module's build.gradle

Gradle

In your root `build.gradle`

```groovy
	allprojects {
		repositories {
			...
			maven { url 'https://jitpack.io' }
		}
	}
```

In your module `build.gradle`

```groovy
	implementation 'com.github.JDHybrid.JDHybridTmp:XCache:1.0.0'
```

## Usage

### Implement parameters provider

```kotlin
class MyHybridGlobalParams : XCParamsProvider() {
  
    override fun getCookie(url: String?): String? {
        return getCookieString(url)
    }

    override fun saveCookie(url: String?, cookies: List<String?>?) {
        saveCookieString(url, cookies)
    }
  
    override fun getUserAgent(url: String?): String? {
        return "Your UserAgent String"
    }
  
    override fun showLog(): Boolean {
        return true
    }
  
    override fun sourceWithUrl(url: String, loader: XCLoader?): XCDataSource? {
        return null
    }
  
  	//...
}
```

#### If you are using XWebView

If you are using `XWebView`, you can implement `XParamsProvider` instead of `XCParamsProvider`, this save you from bothering some methods. For example:

```kotlin
class MyHybridParamsProvider : XParamsProvider() {

    override fun getUserAgent(url: String?): String? {
        return "Your UserAgent String"
    }

    override fun showLog(): Boolean {
        return true
    }

    override fun sourceWithUrl(url: String, loader: XCLoader?): XCDataSource? {
        return null
    }
}
```

### Initialize when App startup

In your application

```kotlin
//initialize XCache
XCache.init(this, debug)
//set the XCParamsProvider you implemented before
XCache.setGlobalParams(MyHybridParamsProvider::class)
```

### Preload Web's resources before opening webview page

```kotlin
val url = "https://m.jd.com"
//get loader in advance
val loader = XCache.createDefaultLoader(url)
val intent = Intent(this, WebActivity::class.java)
loader?.key?.let {
	//pass the loader key to WebActivity
  intent.putExtra("loaderKey", it)
}
intent.putExtra("url", url)
startActivity(intent)
```

### Use loader you created before in your webview page

```kotlin
class WebActivity : AppCompatActivity() {
    var webView: WebView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val url = intent.getStringExtra("url")
        //get the loader's key and get XCLoader instance
        val loaderKey = intent.getStringExtra("loaderKey")
        var loader = loaderKey?.let {
            getLoader(it)
        }
        //But if you haven't create loader in advance, don't worry, you can create from here.
        loader = loader ?: createDefaultLoader(url)
        //set the loader's lifecycleOwner to this page
        loader?.lifecycleOwner = this

        setContentView(R.layout.activity_web)
        this.webView = findViewById(R.id.webview)
        configWebView()
        val webView = this.webView
        webView?.let {
          	//set XWebClient as WebViewClient, and pass the view and XCLoader to it
            webView.webViewClient = XWebClient(webView, loader)
        }
        url?.apply {
          	//now you can start load web page
            webView?.loadUrl(url)
        }
    }
}
```

**And all done!** Now your app will preload the html resource when you create the `XCLoader`, and use the downloaded html file as response.

If you would like to use other local files (such as image, css, js etc.), please read the following instruction.

---

## Optional Functions

### Use other local files

If you use default resource matcher `MapResourceMatcher` that the sdk provides, you can override `XCParamsProvider`'s method *sourceWithUrl* to return `XCDataSource` for specific url. 

```kotlin
class MyHybridGlobalParams : XCParamsProvider() {
    override fun sourceWithUrl(url: String, loader: XCLoader?): XCDataSource? {
        return getDataSource(url)
    }
}
```

`XCDataSource` helps default matcher `MapResourceMatcher` with locating offline files, so a *Map<String, XCLocalResp>* is needed to map each resource's url to its relative path of offline file. 

There are 4 ways set the map: 

- One is put a json file named `"resource.json"` in `XCDataSource`'s offlineDirPath and `XCDataSource` will find the json itself during constructing. There is a tool generating offline package containing `resource.json`, please see [Offline package generating Tool](../../nodejs/README.md).
- The other three ways are setting *sourceMap*, *sourceList*, or *sourceStr* for `XCDataSource`.

```kotlin
    fun getDataSource(url: String): XCDataSource? {
        return when(url){
            "Url1" ->
                XCDataSource("localFileDirPath1") //directory localFileDirPath1 contains a resource.json file
            "Url2" ->
                XCDataSource("localFileDirPath2", sourceMap = mapOf(Pair("https://Host2/a.js", XCLocalResp("https://Host2/a.js", "script", filename = "a.js")))) //use map of XCLocalResp
            "Url3" ->
                XCDataSource("localFileDirPath3", sourceList = listOf(Triple("https://Host3/b.css", "stylesheet", "b.css"))) //use list of <url, type, file's relative path>
            "Url4" ->
                XCDataSource("localFileDirPath4", sourceStr = "[{\"url\":\"https://Host4/c.png\",\"filename\":\"c.png\",\"type\":\"image\"}]") //use json string
            else -> null
        }
    }
```

### More options about XCLoader

Throught `XCLoader`, you can change settings or functions about loading offline files.

```kotlin
val loader = XCLoader(url) // create XCLoader
XCache.addLoader(loader) // add it into XCache so that other page can retreive it by XCache.getLoader(key)
```

#### Enable/Disable preload Html

By default, the html preloading is enable, you can change it when creating your own `XCLoader`

```kotlin
XCLoader(url, preload = false)
```

#### Custom offline resource matching rules for the WebView

You can add your own matcher into the matcher list, matcher will try to match resources throught the matcher list by order, and return response once a matcher matches, ignore remaining matchers.

```kotlin
    private fun createMyMatcherList(): List<XCResourceMatcher> {
        val matcherList = XCache.createDefaultResourceMatcherList()
        matcherList.addFirst(MyMatcher())
        return matcherList
    }

		private fun createMyLoader(url: String): XCLoader? {
        return if (useMyLoader) {
            val loader = XCLoader(url, preload = false, matcherList = createMyMatcherList())
            XCache.addLoader(loader)
            loader
        } else {
            XCache.createDefaultLoader(url)
        }
    }
```

#### Custom global offline resource matching rules

You can add your matcher to default matcher list, then every default `XCLoader` will use your matcher by default. You need to implement `XCResourceMatcher`. Your matcher will be added in the last of matcher list.

```kotlin
XCache.registerDefaultResourceMatcher(YourCustomMatcherClass::class)
```

### Enable XCache globally or just for single webview

```kotlin
XCache.enable(true/false) // globally
XCLoader.enable = true/false // for single webview's loader
```

### Use your own database/net/... implementations

```kotlin
XCache.registerService(YourFileServiceClass::class) //YourFileServiceClass extends XCFileRepoDelegate
XCache.registerService(YourNetServiceClass::class) //YourNetServiceClass extends XCNetDelegate
//etc.
```


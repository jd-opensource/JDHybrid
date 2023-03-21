# JDCache - Android

## 类结构图

![XCacheUML](../doc/jdcache_process.md)

## 依赖

在您模块的`build.gradle`文件配置中加入以下依赖

Gradle

项目 build.gradle`

```groovy
	allprojects {
		repositories {
			...
			maven { url 'https://jitpack.io' }
		}
	}
```

模块 `build.gradle`

```groovy
	implementation 'com.github.JDHybrid.JDHybridTmp:XCache:1.0.0'
```

## 使用

### 提供必要参数

实现`JDCacheParamsProvider`中的方法

```kotlin
class MyHybridGlobalParams : JDCacheParamsProvider() {
  
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

### 初始化

在您App的application中

```kotlin
//初始化XCache
JDCache.init(this, debug)
//用您上面实现的XCParamsProvider类来设置
JDCache.setGlobalParams(MyHybridParamsProvider::class)
```

### 打开网页前预加载网页

```kotlin
val url = "https://m.jd.com"
//提前获取XCLoader
val loader = JDCache.createDefaultLoader(url)
val intent = Intent(this, WebActivity::class.java)
loader?.key?.let {
	//把loader key通过bundle传给WebActivity(展示网页的Activity)
  intent.putExtra("loaderKey", it)
}
intent.putExtra("url", url)
startActivity(intent)
```

### 在页面中使用JDCacheLoader桥接网页资源

```kotlin
class WebActivity : AppCompatActivity() {
    var webView: WebView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val url = intent.getStringExtra("url")
        //获得loader key，然后获取JDCacheLoader实例
        val loaderKey = intent.getStringExtra("loaderKey")
        var loader = loaderKey?.let {
            getLoader(it)
        }
        //如果没有提前创建JDCacheLoader实例，也可现场创建，但我们强烈建议您提前创建好实例，否则预加载的效果将大打折扣
        loader = loader ?: createDefaultLoader(url)
        //设置loader的lifecycleOwner为当前页面
        loader?.lifecycleOwner = this

        setContentView(R.layout.activity_web)
        this.webView = findViewById(R.id.webview)
        configWebView()
        val webView = this.webView
        //给WebViewClient绑定loader并设置给WebView
        webView.webViewClient = object : WebViewClient() {
            override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                super.onPageStarted(view, url, favicon)
                url?.let {
                    loader?.onPageStarted(url)
                }
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                url?.let {
                    loader?.onPageFinished(url)
                }
            }

            override fun shouldInterceptRequest(
                view: WebView?,
                request: WebResourceRequest?
            ): WebResourceResponse? {
                return request?.let { loader?.onRequest(request) } ?: super.shouldInterceptRequest(view, request)
            }
        }
        url?.apply {
          	//然后您可以加载网页了
            webView?.loadUrl(url)
        }
    }
}
```

**这样就完成了!** 现在您的App将可以在创建`JDCacheLoader`实例时预加载HTML文件。如果您想使用本地的离线资源（例如图片、css、js等资源），请继续阅读后续文档。

---

## 更多功能

### 使用本地离线资源

当您使用SDK提供的默认资源匹配器`MapResourceMatcher`时，您可以通过`JDCacheParamsProvider`的*sourceWithUrl*方法为特定的URL提供本地离线资源。

```kotlin
class MyHybridGlobalParams : JDCacheParamsProvider() {
    override fun sourceWithUrl(url: String, loader: XCLoader?): XCDataSource? {
        return getDataSource(url)
    }
}
```

返回的`JDCacheDataSource`可让 `MapResourceMatcher`使用里面的离线文件，为此您需要提供各资源URL和其本地文件路径映射信息的一个*Map<String, JDCacheLocalResp>*。

有4种方法可以为`XCDataSource`设置文件映射：

- 第一种方法是，映射信息存入在离线文件目录中的`"resource.json"`文件里，离线文件目录由`JDCacheDataSource`构造时，传入的`offlineDirPath`来设置。然后 `JDCacheDataSource`在构造时会自动查找这个json文件。我们提供了一个自动为URL打包离线资源的工具，可以下载选定的离线资源文件和生成`resource.json`文件，请查阅[Offline package generating Tool](../../nodejs/README.md)。
- 其他的方法是让`JDCacheDataSource`使用*sourceMap*、 *sourceList*、或者*sourceStr*方法。

```kotlin
    fun getDataSource(url: String): XCDataSource? {
        return when(url){
            "Url1" ->
                JDCacheDataSource("localFileDirPath1") //directory localFileDirPath1 contains a resource.json file
            "Url2" ->
                JDCacheDataSource("localFileDirPath2", sourceMap = mapOf(Pair("https://Host2/a.js", XCLocalResp("https://Host2/a.js", "script", filename = "a.js")))) //use map of XCLocalResp
            "Url3" ->
                JDCacheDataSource("localFileDirPath3", sourceList = listOf(Triple("https://Host3/b.css", "stylesheet", "b.css"))) //use list of <url, type, file's relative path>
            "Url4" ->
                JDCacheDataSource("localFileDirPath4", sourceStr = "[{\"url\":\"https://Host4/c.png\",\"filename\":\"c.png\",\"type\":\"image\"}]") //use json string
            else -> null
        }
    }
```

### JDCacheLoader的更多功能

通过`JDCacheLoader`您可以更改加载离线文件的设置或者方案，可自行创建XCLoader实例。

```kotlin
val loader = JDCacheLoader(url) //创建XCLoader
JDCacheLoader.addLoader(loader) //把实例添加进XCache中，这样您可以在其他页面通过key来拿到此实例。例如XCache.getLoader(key)
```

#### 开启/关闭预加载HTML文件功能

默认情况下，预加载HTML文件功能是自动开启的，您也可以在创建Loader时更改此配置。

```kotlin
JDCacheLoader(url, preload = false)
```

#### 自定义离线资源匹配规则

您可以创建自己的匹配器来自定义匹配规则，您需要实现一个新的`JDCacheResourceMatcher`。在获取默认匹配器列表后，再修改匹配器列表，可添加自定义的匹配器。网页资源的匹配是按此列表中匹配器顺序执行的，一旦前一个匹配器匹配成功，此资源将不再执行后续的匹配器。

```kotlin
    private fun createMyMatcherList(): List<JDCacheResourceMatcher> {
        val matcherList = JDCache.createDefaultResourceMatcherList()
        matcherList.addFirst(MyMatcher())
        return matcherList
    }

		private fun createMyLoader(url: String): JDCacheLoader? {
        return if (useMyLoader) {
            val loader = JDCacheLoader(url, preload = false, matcherList = createMyMatcherList())
            JDCacheLoader.addLoader(loader)
            loader
        } else {
            JDCacheLoader.createDefaultLoader(url)
        }
    }
```

#### 自定义全局离线资源匹配规则

您可以把自定义的匹配器添加到默认匹配器列表中，这样后续的XCLoader在创建默认匹配规则时都会使用到您的匹配器。您的匹配器将会添加到列表的最后。

```kotlin
JDCacheLoader.registerDefaultResourceMatcher(YourCustomMatcherClass::class)
```

### 开关XCache功能

```kotlin
JDCache.enable(true/false) // 全局开启/关闭
JDCacheLoader.enable = true/false // 给XCLoader所使用webview开启/关闭
```

### 使用自定义的功能实现（网络、文件操作等）

```kotlin
JDCache.registerService(YourFileServiceClass::class) //YourFileServiceClass继承自JDCacheFileRepoDelegate
JDCache.registerService(YourNetServiceClass::class) //YourNetServiceClass继承自JDCacheNetDelegate
//etc.
```


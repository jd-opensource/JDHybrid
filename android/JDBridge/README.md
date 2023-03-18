

# JDBridge Android

## 简介

通用的原生与JS通信方法库。内部逻辑执行流程图请查阅[此处](../../doc/progress.md)

## 依赖

Gradle

项目 `build.gradle`

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
	implementation 'com.github.JDFED.JDHybrid:JDBridge:1.0.0'
```

## 原生Native使用

建议您直接使用[JDWebView](../JDWebView/README.md)作为您的WebView，它是`IBridgeWebView`的默认实现，并额外实现了一些功能，您无需额外配置即可直接使用JDBridge功能。

或者您也可自行实现`IBridgeWebView`接口，请参考[自定义实现IBridgeWebView](#自定义实现IBridgeWebView)

**IBridgeWebView的实例创建后即可调用JS，无需等待Web加载完毕，内部会自动在JS准备好时，分发提前触发的JS调用。**

### 原生调用JS

##### 调用JS模块

```kotlin
//  JsPluginName为JS模块名，供原生调用，String
//  params为参数，可为任意能被JSON化的类型
webView.callJS("JsPluginName", params, object : IBridgeCallback {
	override fun onSuccess(result: Any?) {
	}
})
// 或者带error回调
webView.callJS("JsPluginName", params, object : IBridgeCallback {
	override fun onSuccess(result: Any?) {
	}
  override fun onError(errMsg: String?) {
	}
})
```

##### 调用JS模块（JS持续回调）

可用于触发JS下载等长时间的，会持续回调多次的场景。您需要使用`IBridgeProgressCallback`作为回调方法。

```kotlin
//  JsPluginName为JS模块名，供原生调用
webView.callJS("JsPluginName", params, object : IBridgeProgressCallback {
  override fun onError(errMsg: String?) {
  	//invoked on error
  }

  override fun onProgress(data: Any?) {
  	//invoked in progress
  }

  override fun onSuccess(result: Any?) {
  	//invoked when finished
  }
})
```

##### 调用JS默认处理模块

若JS注册了默认处理，原生调用时可不指定JS模块名

```kotlin
webView.callJS(null, params, object : IBridgeCallback {
  override fun onSuccess(result: Any?) {
	  showLog("Received result from default js plugin, result = $result")
  }
})
```



### 原生注册模块给JS调用

##### 单次回调

```kotlin
// NativePluginName为原生模块名，提供给JS调用
webView.registerPlugin("NativePluginName", object : IBridgePlugin {
  override fun execute(
    webView: IBridgeWebView?,
    method: String?,
    params: String?,
    callback: IBridgeCallback?
  ): Boolean {
    //do your work
    if (success) {
      callback?.onSuccess(result) // return result to js
    } else {
      callback?.onError(errMsg) // return result to js
    }
    return true //返回true说明方法被调用
  }
})
```

##### 持续多次回调

```kotlin
// NativePluginName为原生模块名，提供给JS调用
webView.registerPlugin("NativePluginName", object : IBridgePlugin {
  var progress = 0
  override fun execute(
    webView: IBridgeWebView?,
    method: String?,
    params: String?,
    callback: IBridgeCallback?
  ): Boolean {
    //do your work
    if (progress == 100 || callback !is IBridgeProgressCallback) {
    	callback?.onSuccess(result) // return result to js
    } else {
    	callback?.onProgress(tempResult)  // return multiple results to js
    }
    return true //返回true说明方法被调用
  }
})
```

##### 移除已添加的原生功能

```kotlin
webView.unregisterPlugin("NativePluginName")
```

##### 默认原生处理

原生注册默认处理模块，JS调用时可不指定特定模块名称

```kotlin
webView.registerDefaultPlugin(IBridgePluginInstance)//IBridgePluginInstance是IBridgePlugin的实例
```

##### 注册全局模块

原生注册全局处理模块后，所有`IBridgeWebView`实例都能使用

```kotlin
JDBridgeManager.registerPlugin(GlobalJDBridgePlugin.NAME, GlobalJDBridgePlugin::class.java)//使用的是class来注册
```

> 此方法与之前描述的方法不同的是，之前的方法注册的`IBridgePlugin`模块为实例级别，通常可以和WebView实例互相绑定，而`JDBridgeManager.registerPlugin`方法注册的是`IBridgePlugin`的类，在WebView使用时才自动创建，内部逻辑与WebView实例不强引用



### 原生通知自定义事件

> eventName 自定义名称，例如 customEvent

```kotlin
webView.dispatchEvent(eventName, params)
```



### 自定义实现IBridgeWebView

类似`JDWebView`, 实现`IBridgeWebView`请参照以下例子。需要您创建`JDBridgeInstaller`并使用其桥接部分成员变量和方法。

```kotlin
class MyWebView : WebView, IBridgeWebView {

    constructor(context: Context) : super(context)

    //创建JDBridgeInstaller
    private val jdBridgeInstaller: JDBridgeInstaller = JDBridgeInstaller()

    final override val view: View
        get() = this

    //使用JDBridgeInstaller的bridgeMap
    final override val bridgeMap: MutableMap<String, IProxy>
        get() = jdbridgeInstaller.bridgeMap

    init {
        @Suppress("LeakingThis")
        //调用JDBridgeInstaller的桥接方法
        jdBridgeInstaller.install(this)
    }

    override fun onStart() {
        //调用JDBridgeInstaller的桥接方法
        jdBridgeInstaller.onStart()
    }

    override fun onResume() {
        super.onResume()
        //调用JDBridgeInstaller的桥接方法
        jdBridgeInstaller.onResume()
    }

    override fun onPause() {
        //调用JDBridgeInstaller的桥接方法
        jdBridgeInstaller.onPause()
        super.onPause()
    }

    override fun onStop() {
        //调用JDBridgeInstaller的桥接方法
        jdBridgeInstaller.onStop()
    }

    override fun destroy() {
        //调用JDBridgeInstaller的桥接方法
        jdBridgeInstaller.destroy()
        super.destroy()
    }

    override fun loadUrl(url: String) {
        //调用JDBridgeInstaller的桥接方法
        jdBridgeInstaller.loadUrl(url)
        super.loadUrl(url)
    }

    override fun loadUrl(url: String, additionalHttpHeaders: MutableMap<String, String>) {
        //调用JDBridgeInstaller的桥接方法
        jdBridgeInstaller.loadUrl(url, additionalHttpHeaders)
        super.loadUrl(url, additionalHttpHeaders)
    }

    override fun reload() {
        //调用JDBridgeInstaller的桥接方法
        jdBridgeInstaller.reload()
        super.reload()
    }
}
```
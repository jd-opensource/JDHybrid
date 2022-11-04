> [简体中文文档](README-zh-CN.md)

# JDBridge Android

## Introduction

General Native and JS communication library. Please refer to the logic execution flow chart [here](../../doc/progress.md)

You can add bridge ability by `JDBridge` (JDBridgeManager) or `XWebView`

## Dependency

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
	implementation 'com.github.JDHybrid.JDHybridTmp:JDBridge:1.0.0'
```

## Native usage

It is recommended that you directly use [XWebView](../XWebView/README.md) as your WebView. It is the default implementation of `IBridgeWebView` and implements some additional functions. You can use JDBridge functions directly without additional configuration.

Or you can implement the `IBridgeWebView` interface by yourself, please refer to [Implementation of IBridgeWebView](#Implementation of IBridgeWebView)

**After an instance of IBridgeWebView is created, JS can be called without waiting for the Web to be loaded. The JS call triggered in advance will be automatically distributed internally when the JS is ready.**

### Native call JS

##### Call JS Plugin

```kotlin
//  JsPluginName, String
//  params, any type that can be Jsonfied
webView.callJS("JsPluginName", params, object : IBridgeCallback {
	override fun onSuccess(result: Any?) {
	}
})
// or use callback with error
webView.callJS("JsPluginName", params, object : IBridgeCallback {
	override fun onSuccess(result: Any?) {
	}
  override fun onError(errMsg: String?) {
	}
})
```

##### Call JS Plugin(multiple callbacks)

It can be used to trigger JS download or other long-term scenarios that will continue to callback multiple times. You need to use `IBridgeProgressCallback` as the callback.

```kotlin
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

##### Call JS Default Plugin

If JS registered a default plugin, then JS plugin name can be omitted when native calls JS.

```kotlin
webView.callJS(null, params, object : IBridgeCallback {
  override fun onSuccess(result: Any?) {
	  showLog("Received result from default js plugin, result = $result")
  }
})
```



### Native Plugin (JS Call Native)

##### Native Plugin(Callback Only once)

```kotlin
// NativePluginName, String
webView.registerPlugin("NativePluginName", object : IBridgePlugin {
  override fun execute(
    webView: IXWebView?,
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
    //return true means this call is actully handled,
    //false means method's value cannot be found in your plugin
    return true
  }
})
```

##### Native Plugin (Multiple Callback)

```kotlin
webView.registerPlugin("NativePluginName", object : IBridgePlugin {
  var progress = 0
  override fun execute(
    webView: IXWebView?,
    method: String?,
    params: String?,
    callback: IBridgeCallback?
  ): Boolean {
    //do your work
    if (progress == 100 || callback !is IBridgeProgressCallback) {
    	callback?.onSuccess(result) // return result to js
    } else {
    	callback?.onProgress(tempResult)  // return result to js multiple times
    }
    return true
  }
})
```

##### Unregister Native Plugin

```kotlin
webView.unregisterPlugin("NativePluginName")
```

##### Native Default Plugin

If Native registered a default plugin, then plugin name can be omitted when JS calls Native.

```kotlin
webView.registerDefaultPlugin(IBridgePluginInstance)//IBridgePluginInstance is an instance of IBridgePlugin
```

##### Global Native Plugin

If Native registered a global plugin, then all `IBridgeWebView` can use it.

```kotlin
JDBridgeManager.registerPlugin(GlobalJDBridgePlugin.NAME, GlobalJDBridgePlugin::class.java)//use class of your implementation of IBridgeWebView
```

> The difference between this method and methods described earlier is that the `IBridgePlugin` registered by the previous methods usually is bound to the single WebView instance, while the `JDBridgeManager.registerPlugin` method registers the `IBridgePlugin` class, which is automatically created when used, and is for all WebView instances.



### Native fire custome  JS event

> eventName is a customed string, i.e. 'customEvent'.

```kotlin
webView.dispatchEvent(eventName, params)
```



### Implementation of IBridgeWebView

Please refer to the following example to implement `IBridgeWebView`, it is similar to `XWebView`. It requires you to create an `JDBridgeInstaller` and use it to bridge some variables and methods.

```kotlin
class MyWebView : WebView, IBridgeWebView {

    constructor(context: Context) : super(context)

    //Create JDBridgeInstaller
    private val jdBridgeInstaller: JDBridgeInstaller = JDBridgeInstaller()

    final override val view: View
        get() = this

    //use JDBridgeInstaller's bridgeMap
    final override val bridgeMap: MutableMap<String, IProxy>
        get() = jdBridgeInstaller.bridgeMap

    init {
        @Suppress("LeakingThis")
        //call JDBridgeInstaller
        jdBridgeInstaller.install(this)
    }

    override fun onStart() {
        //call JDBridgeInstaller
        jdBridgeInstaller.onStart()
    }

    override fun onResume() {
        super.onResume()
        //call JDBridgeInstaller
        jdBridgeInstaller.onResume()
    }

    override fun onPause() {
        //call JDBridgeInstaller
        jdBridgeInstaller.onPause()
        super.onPause()
    }

    override fun onStop() {
        //call JDBridgeInstaller
        jdBridgeInstaller.onStop()
    }

    override fun destroy() {
        //call JDBridgeInstaller
        jdBridgeInstaller.destroy()
        super.destroy()
    }

    override fun loadUrl(url: String) {
        //call JDBridgeInstaller
        jdBridgeInstaller.loadUrl(url)
        super.loadUrl(url)
    }

    override fun loadUrl(url: String, additionalHttpHeaders: MutableMap<String, String>) {
        //call JDBridgeInstaller
        jdBridgeInstaller.loadUrl(url, additionalHttpHeaders)
        super.loadUrl(url, additionalHttpHeaders)
    }

    override fun reload() {
        //call JDBridgeInstaller
        jdBridgeInstaller.reload()
        super.reload()
    }
}
```

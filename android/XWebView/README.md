> [简体中文文档](README-zh-CN.md)

# XWebView - Android

## Dependencies

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
	implementation 'com.github.JDHybrid.JDHybridTmp:XWebView:1.0.0'
```

## Usage

### WebView

Use `XWebView` as your WebView widget.

> ```kotlin
> import com.jd.hybrid.XWebView
> 
> ...
> 
> val webView = XWebView(context)
> 
> ...
> ```

## Abilities

### JDBridge

Integrated [JDBridge](../JDBridge/README.md)

### Lifecycle events

`XWebView` will fire following JS events when its lifecycle changed.

- onStart -> event: ContainerShow

- onResume -> event: ContainerActive

- onPause -> event: ContainerInactive

- onStop -> event: ContainerHide

### Following methods will run on main thread

If you call the following methods of WebView not in the main thread, `XWebView` will auto switch to main thread to invoke them, and you don't need to handle the switching.

- addJavascriptInterface
- evaluateJavascript
- loadUrl
- reload
- stopLoading
- goBack
- goForward
- goBackOrForward

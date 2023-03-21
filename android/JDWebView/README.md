# JDWebView - Android

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
	implementation 'com.github.JDFED.JDHybrid:JDWebView:1.0.0'
```

## 使用

### WebView

使用 `JDWebView` 作为您的Web View。

> ```kotlin
> import com.jd.hybrid.JDWebView
> 
> ...
> 
> val webView = JDWebView(context)
> 
> ...
> ```

## 能力

### JDBridge

已集成 [JDBridge](../JDBridge/README.md)

### 生命周期事件

`JDWebView` 的生命周期变化时会发射以下JS事件：

- onStart -> event: ContainerShow

- onResume -> event: ContainerActive

- onPause -> event: ContainerInactive

- onStop -> event: ContainerHide

### 以下方法会在主线程执行

`JDWebView`的以下方法将会自动切换到主线程执行，您无需手动切换：

- addJavascriptInterface
- evaluateJavascript
- loadUrl
- reload
- stopLoading
- goBack
- goForward
- goBackOrForward
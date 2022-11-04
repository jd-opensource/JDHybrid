# JDBridge JS指南

## Dependencies

```javascript
//npm install jdhybrid_jdbridge
var JDBridge = require("jdhybrid_jdbridge")
```

使用`JDBridge`的API来与原生Native通信。

## JS Call Native

#### 调用原生模块(单次回调)

```javascript
// 回调function
var callback = function (result) {
	showLog('Received result from MyNativePlugin, result = ' + result)
}
// NativePluginName为原生模块名，提供给JS调用
// action为string类型，params可为string或json
JDBridge.callNative('NativePlugin', {action: 'MyAction', params: params, success: callback})
```

#### 调用原生模块（多次回调）

```javascript
var successCallback = function (result) {
	showLog('Received success from MySequenceNativePlugin, result = ' + result)
}
var progressCallback = function (result, response) {
	showLog('Received progress from MySequenceNativePlugin, complete = ' + response.complete + ', msg = ' + response.msg + ', result = ' + result)
}
// NativePlugin为原生模块名，提供给JS调用
// 除了上面所示方法传参外，模块名也可使用以下方法传参
JDBridge.callNative({name: 'NativePlugin', params: params, success: successCallback, progress: progressCallback})
```

#### 调用原生默认处理模块

若原生注册了默认模块，JS调用时可不指定特定模块名

```javascript
var callback = function (result, response) {
	showLog('Received result from native, complete = ' + response.complete + ', msg = ' + response.msg + ', result = ' + result)
}
JDBridge.callNative({params: params, success: callback})
```



## JSPlugin（供原生调用）

#### 单次回调

```javascript
//JsPluginName为JS模块名，供原生调用
//同步
JDBridge.registerPlugin('JsPluginName', function (params) {
  showLog('MySyncJsPlugin invoked by native, params = ' + JSON.stringify(params))
  return JSON.stringify(result)
})

//异步
JDBridge.registerPlugin('JsPluginName', function (params, callback) {
  showLog('MyAsyncJsPlugin invoked by native, params = ' + JSON.stringify(params))
  callback(JSON.stringify(result))
})

//处理失败
JDBridge.registerPlugin('JsPluginName', function (params, callback) {
  showLog('MyAsyncJsPlugin invoked by native, params = ' + JSON.stringify(params))
  var isSuccess = true;//false
  callback(JSON.stringify(result), isSuccess)
})
```

#### 多次回调

```javascript
//JsPluginName为JS模块名，供原生调用
//通过callback返回中间、最后结果给原生，使用complete标志是否完成
JDBridge.registerPlugin('JsPluginName', function (params, callback) {
  showLog('MySequenceJsPlugin invoked by native, params = ' + JSON.stringify(params))
  var isSuccess = true;//false
  var time = 0
  var timer = setInterval(function () {
    var complete = false
    time++
    if (time == 10) {
      clearInterval(timer)
      complete = true
    }
    callback((time * 10) + '%, MySequenceJsPlugin returns ' + JSON.stringify(result), isSuccess, complete)
  }, 500)
})
```

#### 移除JSPlugin

```javascript
JDBridge.unregisterPlugin('JsPluginName')
```

#### 默认JSPlugin

JS可注册默认处理，原生调用时可不指定JS模块名

```javascript
JDBridge.registerDefaultPlugin(function (params, callback) {
  showLog('Default JS plugin invoked by native, params = ' + JSON.stringify(params))
  callback('Default JS plugin returns ' + JSON.stringify(params))
})
```

## JS等待初始化

请等JDBridge初始化好后使用JS功能。可使用以下代码等待初始化。

```javascript
function connectJDBridge(callback) {
  if (window.JDBridge) {
  	callback(JDBridge)
  } else {
  	window.addEventListener(
  		'JDBridgeReady',
  		function () {
  			callback(JDBridge)
  		},
  		false
  	);
  }
}

//run this function
connectJDBridge(function (bridge) {
  showLog('JDBridge is ready.')
  //do your work with JDBridge
})
```

## Debug模式

默认情况下`JDBridge` 不会输出debug log，您可以用以下方法展示log。

```javascript
JDBridge.setDebug(true);
```

## WebView原生事件通知

我们基于H5最熟悉的window.addEventListener实现了一套事件通知机制

#### XWebView 默认支持事件

原生需使用`XWebView`时才可使用

* webView 可见性
```javascript
    window.addEventListener('ContainerShow', function(event){
        alert(event);
    }, false);
    window.addEventListener('ContainerHide', function(event){
        alert(event);
    }, false);
```

* App 进入前后台(only iOS)
```javascript
    window.addEventListener('AppShow', function(event){
        alert(event);
    }, false);
    window.addEventListener('AppHide', function(event){
        alert(event);
    }, false);
```

#### 监听自定义事件

```javascript
window.addEventListener('customEvent', function(event){
	alert(JSON.parse(event.params));
}, false);
```

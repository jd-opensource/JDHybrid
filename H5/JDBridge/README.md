> [简体中文文档](./README-zh-CN.md)

# JDBridge JS

## 引入

```javascript
//npm install jdhybrid_jdbridge
var JDBridge = require("jdhybrid_jdbridge")
```

Use APIs in the `JDBridge` object to communicate with native

## Call Native Plugin

#### JS Call Native Plugin1 (callback only once)

```javascript
// call function
var callback = function (result) {
	showLog('Received result from MyNativePlugin, result = ' + result)
}
// NativePluginName 
// action type:string
// params type:string,json
JDBridge.callNative('NativePlugin', {action: 'MyAction', params: params, success: callback})
```

#### JS Call Native Plugin2（Callback Continuouslly）

```javascript
var successCallback = function (result) {
	showLog('Received success from MySequenceNativePlugin, result = ' + result)
}
var progressCallback = function (result, response) {
	showLog('Received progress from MySequenceNativePlugin, complete = ' + response.complete + ', msg = ' + response.msg + ', result = ' + result)
}

JDBridge.callNative({name: 'NativePlugin', params: params, success: successCallback, progress: progressCallback})
```

#### JS Call Default Plugin

JS will call a default plugin if no plugin name specify clearly

```javascript
var callback = function (result, response) {
	showLog('Received result from native, complete = ' + response.complete + ', msg = ' + response.msg + ', result = ' + result)
}
JDBridge.callNative({params: params, success: callback})
```



## Register JSPlugin

#### Callback Only Once

```javascript
//JsPluginName
//Sync return
JDBridge.registerPlugin('JsPluginName', function (params) {
  showLog('MySyncJsPlugin invoked by native, params = ' + JSON.stringify(params))
  return JSON.stringify(result)
})

//Async return
JDBridge.registerPlugin('JsPluginName', function (params, callback) {
  showLog('MyAsyncJsPlugin invoked by native, params = ' + JSON.stringify(params))
  callback(JSON.stringify(result))
})

//may fail
JDBridge.registerPlugin('JsPluginName', function (params, callback) {
  showLog('MyAsyncJsPlugin invoked by native, params = ' + JSON.stringify(params))
  var isSuccess = true;//false
  callback(JSON.stringify(result), isSuccess)
})
```

#### Callback Continuouslly

```javascript
//JsPluginName
//callback，complete indicates finished or not
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

#### Remove JSPlugin

```javascript
JDBridge.unregisterPlugin('JsPluginName')
```



#### Default JSPlugin

JS can register a default plugin that native can call without plugin name

```javascript
JDBridge.registerDefaultPlugin(function (params, callback) {
  showLog('Default JS plugin invoked by native, params = ' + JSON.stringify(params))
  callback('Default JS plugin returns ' + JSON.stringify(params))
})
```



## JS Initial

Please use all js functions after JDBridge is initialized. You can use following code to get called after initialized.

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

## Debug Mode

By default, `JDBridge` will not show logs. You can enable debug mode to show them.

```javascript
JDBridge.setDebug(true);
```

## WebView Event

We defined webview event mechanism with a friendly way ----- window.addEventListener

#### XWebView Default Event

* webView visible

```javascript
    window.addEventListener('ContainerShow', function(event){
        alert(event);
    }, false);
    window.addEventListener('ContainerHide', function(event){
        alert(event);
    }, false);
```

* App enter foreground/background(only iOS)

```javascript
    window.addEventListener('AppShow', function(event){
        alert(event);
    }, false);
    window.addEventListener('AppHide', function(event){
        alert(event);
    }, false);
```

#### Listen Custom Event

```javascript
window.addEventListener('customEvent', function(event){
	alert(JSON.parse(event.params));
}, false);
```

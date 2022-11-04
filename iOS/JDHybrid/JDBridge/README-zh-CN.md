# JDBridge iOS



## 通过cocoapods集成JDBridge，在podfile文件中添加：

```ruby
pod 'JDHybrid/JDBridge'
```
## JDBridge 简介

通用的原生与JS通信方法库。逻辑执行流程图请查阅[此处](../../../doc/progress.md)

## Native call JS

 iOS既可以利用JDBridgeManager来添加Bridge能力，也可使用`XWebView`作为WebView容器来使用Bridge能力。

**XWebView创建实例后即可调用JS，无需等待Web加载完毕，内部会自动在JS准备好时分发之前触发的调用。**

### JDBridgeManager初始化

```objective-c
//  返回JDBridgeManager实例，需业务retain
//  WebView，添加jsbridge能力的webview实例
+ (nullable JDBridgeManager *)bridgeForWebView:(WKWebView *)webView;
```
### 添加messageHandler

```objective-c
// 添加MessageHandler，默认添加了XWebView、JDBridge
- (void)addScriptMessageHandlers:(NSArray *)messageHanders

```

### 一、 Native Call JS API

#### 调用JS模块（单次回调）

```objective-c
//  JsPluginName为JS模块名，供原生调用，String
//  params为参数，可为任意能被JSON化的类型
- (void)callJSWithPluginName:(NSString *)pluginName
                      params:(id)message
                    callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback;
```

#### 调用JS模块（持续回调）

可用于触发JS下载等长时间的，会持续回调多次的场景。

```objective-c
// JsPluginName为JS模块名，供原生调用，String
//  params为参数，可为任意能被JSON化的类型
// callback 会调用多次，需jsplugin与native协商好进度描述机制

- (void)callJSWithPluginName:(nullable NSString *)pluginName
                      params:(nullable id)message
                    progress:(void(^)(id _Nullable obj))progress
                    callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback;
```

#### 调用JS默认处理模块

若JS注册了默认处理，原生调用时可不指定JS模块名

```objective-c
- (void)callDefaultJSBridgeWithParams:(id)message
                             callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback;

```



### 二、 JS Call Native

实现自定义组件：继承JDBridgeBasePlugin，实现方法

```objective-c
- (void)excute:(NSString *)action params:(NSDictionary *)params callback:(JDBridgeCallBack *)jsBridgeCallback
```
来接收h5的参数，并通过
* jsBridgeCallback.onSuccess
* jsBridgeCallback.onSuccessProgress、
* jsBridgeCallback.onError

其中之一进行回调

#### 单次回调

```objective-c
// NativePluginName为原生模块名（如：MyNativePlugin），提供给JS调用
@interface MyNativePlugin: JDBridgeBasePlugin

@end


@implementation MyNativePlugin

- (void)excute:(NSString *)action params:(NSDictionary *)params callback:(JDBridgeCallBack *)jsBridgeCallback{
    NSLog(@"%@,%@",action,params);
    if (jsBridgeCallback.onSuccess) {
        jsBridgeCallback.onSuccess(@"Hello, I am Native");
    }
}

@end

```

#### 持续多次回调

```objective-c
// NativePluginName为原生模块名，提供给JS调用
@interface MySequenceNativePlugin : JDBridgeBasePlugin

@end

@implementation MySequenceNativePlugin

- (void)excute:(NSString *)action params:(NSDictionary *)params callback:(JDBridgeCallBack *)jsBridgeCallback{
    __block float progress = 0.0;
    __block NSInteger index = 0;
    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (index++<10) {
            progress += 0.1;
            if (jsBridgeCallback.onSuccessProgress) {
                jsBridgeCallback.onSuccessProgress(@{@"progress":@(progress)}, progress);
            }
        }
    }];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

@end
```

#### 默认原生处理

原生注册默认处理模块，JS调用时可不指定特定模块名称

```objective-c
- (void)registerDefaultPlugin:(JDBridgeBasePlugin *)defaultJsPlugin
```


| [简体中文文档](./README-zh-CN.md)

# JDBridge iOS


## Cocoapods

add

```ruby
pod 'JDHybrid/JDBridge'
```
in your podfile

## JDBridge Introduction

General Native and JS communication library. Please refer to the logic execution flow chart [here](../../../doc/progress.md)

You can add bridge ability by `JDBridge` (JDBridgeManager) or `XWebView`

## Native call JS

**JDBridge can call JS after creating an instance, without waiting for the web to load. The call will be triggered automatically when JS is ready.**

### JDBridgeManager Initialize

```objective-c
//  return JDBridgeManager instance，You should retain it
//  WebView，Your WebView
+ (nullable JDBridgeManager *)bridgeForWebView:(WKWebView *)webView;
```

### Add MessageHandler

```objective-c
// add MessageHandler，default: XWebView、JDBridge
- (void)addScriptMessageHandlers:(NSArray *)messageHanders

```

### Native Call JS API

#### Call JS Module（Callback Only Once）

```objective-c
//  JsPluginName，String
//  Params，Any type that can be JSON
- (void)callJSWithPluginName:(NSString *)pluginName
                      params:(id)message
                    callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback;
```

#### Call JS Module（Callback Continuouslly)

```objective-c
// JsPluginName，String
//  params，Any type that can be JSON
//progress, block
// callback, block

- (void)callJSWithPluginName:(nullable NSString *)pluginName
                      params:(nullable id)message
                    progress:(void(^)(id _Nullable obj))progress
                    callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback;
```

#### Call JS Default Plugin

```objective-c
- (void)callDefaultJSBridgeWithParams:(id)message
                             callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback;

```



### Native Plugin (JS Call Native)

CustomPlugin：inherits JDBridgeBasePlugin，and implements method

```objective-c
- (void)excute:(NSString *)action params:(NSDictionary *)params callback:(JDBridgeCallBack *)jsBridgeCallback
```

* jsBridgeCallback.onSuccess //for success
* jsBridgeCallback.onSuccessProgress // for progress
* jsBridgeCallback.onError //for error

callback with one of these blocks

#### Native Plugin(Callback Only once)

e.g: 

```objective-c
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

#### Native Plugin (Callback Continuouslly)

```objective-c
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

#### Native Default Plugin

Native registers A default plugin which js can call without plugin name

```objective-c
- (void)registerDefaultPlugin:(JDBridgeBasePlugin *)defaultJsPlugin
```


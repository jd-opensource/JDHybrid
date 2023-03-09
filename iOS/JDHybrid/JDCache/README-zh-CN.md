# JDCache

[![Version](https://img.shields.io/cocoapods/v/XBridge.svg?style=flat)](https://cocoapods.org/pods/JDHybrid/JDCache)
[![License](https://img.shields.io/cocoapods/l/XBridge.svg?style=flat)](https://cocoapods.org/pods/JDHybrid/JDCache)
[![Platform](https://img.shields.io/cocoapods/p/XBridge.svg?style=flat)](https://cocoapods.org/pods/JDHybrid/JDCache)

JDCache iOS端内部使用WKURLSchemeHandler协议，通过拦截所有http/https的请求，匹配本地离线资源。JDCache中提供HTML预加载能力，并且内置了HTML匹配器和网络请求匹配器，只需使用者实现自己的离线匹配逻辑。


## 依赖

JDCache 支持 [CocoaPods](https://cocoapods.org) 安装使用，仅需要在您的Podfile添加:

```ruby
pod 'JDHybrid/JDCache'
```

参考下面教程创建测试离线包

[离线包生成](../../../nodejs/README.md)

## 基本使用

#### 一、初始化JDCache
JDCache使用单例创建，并设置netCache网络缓存代理。netCache实例需满足JDURLCacheDelegate协议，推荐使用YYCache。

```objc
@protocol JDURLCacheDelegate <NSObject>
- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key;
- (id<NSCoding>)objectForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;
- (void)removeAllObjects;
@end
```

#### 二、开启Hybrid

仅需一行代码即可开启Hybrid：

```objc
configuration.loader.enable = YES;
```

注意：此代码必须在使用configuration创建WKWebView实例之前才生效，例如：

```objc
WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
configuration.loader.enable = YES;
WKWebView *webview = [WKWebView initWithFrame:frame configuration:configuration];
```

#### 三、创建匹配器

1. 创建单个匹配器必须实现JDResourceMatcherImplProtocol协议
   
    ```objc
    @protocol JDResourceMatcherImplProtocol <NSObject>
    - (BOOL)canHandleWithRequest:(NSURLRequest *)request;

    - (void)startWithRequest:(NSURLRequest *)request
            responseCallback:(JDNetResponseCallback)responseCallback
                dataCallback:(JDNetDataCallback)dataCallback
                failCallback:(JDNetFailCallback)failCallback
            successCallback:(JDNetSuccessCallback)successCallback
            redirectCallback:(JDNetRedirectCallback)redirectCallback;
    @end
    ```
    api说明：

    ```objc
    - (BOOL)canHandleWithRequest:(NSURLRequest *)request;
    ```

    此api根据传入的NSURLRequest实例，需返回是否拦截处理。若返回YES，需要在下一个api回调response、data、fail或success等数据。若返回NO，则会传递给下一个匹配器处理。

    ```objc
    - (void)startWithRequest:(NSURLRequest *)request
            responseCallback:(JDNetResponseCallback)responseCallback
                dataCallback:(JDNetDataCallback)dataCallback
                failCallback:(JDNetFailCallback)failCallback
            successCallback:(JDNetSuccessCallback)successCallback
            redirectCallback:(JDNetRedirectCallback)redirectCallback;
    ```
    
    此api根据传入的NSURLRequest实例，回调response、data、fail或success等数据。上一个api若返回YES，此api需要正常回调数据；若返回NO，则此api不会被调用。

2. 将所有的匹配器，以数组的形式赋值给JDCacheLoader实例的matchers字段，JDCache在拦截到请求时，会按顺序依次传递给数组中的匹配器去处理。例如：

    ```objc
    configuration.loader.matchers = @[mapResourceMatcher,aaaResourceMatcher,bbbResourceMatcher];
    ```

## 更多使用

#### 降级

通过以下方法来降级：

```objc
configuration.loader.degrade = YES;
```
设置完成后，在本次的WebView加载中，将会全部走网络请求，不使用匹配器资源。

#### HTML预加载

通过以下步骤来执行预加载：

1. 创建JDCachePreload实例

```objc
JDCachePreload *preload = [JDCachePreload new];
preload.request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.jd.com"]];
preload.enable = YES;
[preload startPreload];
```

2. 将JDCachePreload实例赋值给loader的preload字段
   
```objc
configuration.loader.preload = preload;
```

设置完成后，在JDCache拦截到此HTML的请求后会优先使用预加载数据。



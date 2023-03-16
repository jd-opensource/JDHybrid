# JDCache

The JDCache iOS side is designed based on the [WKURLSchemeHandler](https://developer.apple.com/documentation/webkit/wkurlschemehandler) protocol,By intercepting http/https requests, it matches local offline resources and speeds up the loading of H5 pages.Has the following characteristics:
+ code without intrusion
+ No transformation cost for H5 service access
+ Flexible, customizable matchmaking strategies

## Dependencies

JDCache is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'JDHybrid/JDCache'
```
First, You can generate offline package:

[Offline Package Produce](../../../nodejs/README.md)

## Basic usage

#### 1、JDCache install
Initialize JDCache when the APP launch, set the network cache delegate, and whether to enable the log.
* netCache is used to cache network resources, complying with the [standard http cacheing protocol](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching). The instance needs to extend the JDURLCacheDelegate protocol, and YYCache is recommended.

```objc
[JDCache shareInstance].netCache = self.xhCache;
[JDCache shareInstance].LogEnabled = YES;
```

#### 2、Hybrid Enable With Configuration
Hybrid can be enabled with just one line of code:

```objc
configuration.loader.enable = YES;
```

* Note: This code must be set before using configuration to create a WKWebView instance to take effect.

#### 3、Create matchers
1. Creating a matcher must implement the JDResourceMatcherImplProtocol protocol

```objc
@protocol JDResourceMatcherImplProtocol <NSObject>
// Description: According to the incoming NSURLRequest instance, the api needs to return whether to intercept or not.
- (BOOL)canHandleWithRequest:(NSURLRequest *)request;

// Description: This API calls back data such as response, data, fail or success according to the incoming NSURLRequest instance.
// * If the API `canHandleWithRequest:` returns YES, this API needs to call back data normally;
// * If API `canHandleWithRequest:` returns NO, this API will not be called.
- (void)startWithRequest:(NSURLRequest *)request
        responseCallback:(JDNetResponseCallback)responseCallback
            dataCallback:(JDNetDataCallback)dataCallback
            failCallback:(JDNetFailCallback)failCallback
        successCallback:(JDNetSuccessCallback)successCallback
        redirectCallback:(JDNetRedirectCallback)redirectCallback;
@end
```

2. set loader's matchers, such as：

```objc
configuration.loader.matchers = @[mapResourceMatcher,aaaResourceMatcher,bbbResourceMatcher];
```
* All matchers are assigned to the matchers field of the JDCacheLoader instance in the form of an array. When JDCache intercepts a request, it will be passed to the matchers in the array in order for processing.

## More usage

#### HTML preload
Perform preloading by following these steps:
1. create a JDCachePreload instance

```objc
JDCachePreload *preload = [JDCachePreload new];
preload.request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.jd.com"]];
preload.enable = YES;
[preload startPreload];
```

2. Assign the JDCachePreload instance to the preload field of the loader

```objc
configuration.loader.preload = preload;
```
then, the preloaded data will be used first after JDCache intercepts the HTML request.
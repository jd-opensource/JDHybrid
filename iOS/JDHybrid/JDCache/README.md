# XCache

[![Version](https://img.shields.io/cocoapods/v/XBridge.svg?style=flat)](https://cocoapods.org/pods/JDHybrid/XCache)
[![License](https://img.shields.io/cocoapods/l/XBridge.svg?style=flat)](https://cocoapods.org/pods/JDHybrid/XCache)
[![Platform](https://img.shields.io/cocoapods/p/XBridge.svg?style=flat)](https://cocoapods.org/pods/JDHybrid/XCache)


## Installation

XCache is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'JDHybrid/XCache'
```
First, You can generate offline package:

[Offline Package Produce](../../../nodejs/README.md)

## XCache API


#### 1、Hybrid Enable

```objc
WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
configuration.xh_config.isEnabled = YES;
```

#### 2、Hybrid Enable With Configuration
1). set Hybrid delegate<br>

    a. import header file
```objective-c
#if __has_include(<JDHybrid/JDHybrid-umbrella.h>)
#import <JDHybrid/JDHybrid-umbrella.h>
#else
#import "JDHybrid.h"
#endif
```
    b. set delegate
```objc
[JDHybrid hybrid].delegate = self;
```

    c. implements delegate method
    
```objc
- (id<XHDataSource>)sourceWithUrl:(NSString *)url{
    XHLocalFileModel *model = [XHLocalFileModel new];
    model.path = "xxx";
    return model;   
}   
```
    If you custom your offline package, please implements method sourceMap in XHDataSource, and returned data format should like:

```json
{
    "host1":{"path1":"relative path1"},
    "host2":{"path1":"relative path2"}
}
```
    

2). Set the entry URL when initializing WebView. The entry URL will decide whether to use hybrid to load according to the returned path from delegate method implemented above

```objc
WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
configuration.xh_config.url = "https://www.jd.com";
```

#### 3、Add Custom SchemeHandlers

By adding a custom interception policy, you can modify all network resources requested during the loading process of WebView, and interrupt and modify them.


1). Add Scheme 
```objc
WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
[configuration.xh_config addCustomHandlerScheme:@"hybrid"];
```
   **Note: It is illegal when you want to set some resources's scheme with custom scheme in http(s) pages.**

2). Add interception policy

   a. Add interception policy to a single webView
```objc
WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
[configuration.xh_config registerUrlSchemeHandlers:@[[XHURLSchemeHandler class]]];
```
   b. The delegate method of hybrid returns the policy that can intercept all WebView requests
      
```objc
- (NSArray <Class>*)customURLSchemeHandlerClasses
```
3). Create a subclass that inherits XHURLSchemeHandler to implement the interception strategy. The subclass needs to implement the following methods

```objc
- (BOOL)canHandleWithRequest:(NSURLRequest *)request;
- (void)startURLSchemeTask:(id <XHURLSchemeTask>)urlSchemeTask;
- (void)stopURLSchemeTask:(id <XHURLSchemeTask>)urlSchemeTask;
```

#### 4、 HTML Preload

It is used to preload HTML resources before WebView loading, and directly load cached data while H5 loading to improve loading performance.

1). Create HTML preload class
```objc
XHPreload *preload = [XHPreload preloadURL:@"https://www.jd.com"];
```
2). Set preload ability when initializing WebView

```objc
WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
configuration.xh_config.preload = preload;
```
The preloaded data cannot be used multiple times and will release after being used

#### 5、 Other API
1). Add custom request header

Implements method
```objc
- (NSDictionary *)customHeaders{
    return @{
        @"native":@1,
    };
}
```

2). Modify preloading url

Implements method
```objc

- (void)preloadHtmlLoaderWithURL:(NSString *)url complete:(void (^) (NSString *url))complete{
   complete(url);
}

```

3). Add network cache

Implements method
```objc
- (id <XHCacheDelegate>)networkCache;
```

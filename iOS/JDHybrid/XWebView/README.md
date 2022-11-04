> [简体中文文档](README-zh-CN.md)

# XWebView

## Cocoapods Install XWebView
```ruby
pod 'JDHybrid/XWebView'
```

## XWebView Introduction

XWebView provides a WebView container which inherits UIView and adds WKWebView as a child view. The container provides support for the following capabilities:

### KVO Observer

```objective-c
/// KVO, loading progress
@property(nonatomic, assign, readonly)float                       estimatedProgress;

/// KVO, document.title
@property(nonatomic, copy, readonly)NSString                      *title;

/// KVO, loading URL
@property(nonatomic, strong, readonly)NSURL                       *URL;
```

### JSBridge Support（Base On JDBridge）
```objective-c
@property(nonatomic, strong, readonly)JDBridgeManager              *jsBridgeManager;

```

### WKWebViewConfigure 
```objective-c
/// default
+ (WKWebViewConfiguration *)defaultConfiguration;

/// modify wkconfiguration
/// @param configuration the configuration you want to repair
/// @param required weather need useraction
- (void)configuration:(WKWebViewConfiguration *)configuration requiringUserActionForPlayback:(BOOL)required;
```

### WKWebView UIDelegate Default Implementation

```objective-c
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler;

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler;

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler;
```

### Add UserSciprt
```objective-c
- (void)addUserScript:(NSString *)javaScript
        injectionTime:(WKUserScriptInjectionTime)injectTime
     forMainFrameOnly:(BOOL)onlyForMainFrame;
```


### WebView JSBridge
```objective-c

- (void)registerMessageHandlers:(NSArray *)messageHandlers;

- (void)registerDefaultPlugin:(JDBridgeBasePlugin *)defaultJsPlugin;

- (void)callDefaultJSBridgeWithParams:(id)message
                             callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback;

- (void)callJSWithPluginName:(nullable NSString *)pluginName
                      params:(nullable id)message
                    callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback;

- (void)callJSWithPluginName:(nullable NSString *)pluginName
                      params:(nullable id)message
                    progress:(void(^)(id _Nullable obj))progress
                    callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback;
```

### WebView Event
```objective-c
/// App or webview event to h5
/// @param eventName eventName
- (void)dispatchEvent:(NSString *)eventName;

/// App or webview event to h5 with params
/// @param eventName eventName
/// @param params params
- (void)dispatchEvent:(NSString *)eventName params:(nullable NSDictionary *)params;

/// webview will appear
- (void)viewWillAppear;

/// webview will disappear
- (void)viewWillDisAppear;
```

### WebView delegate 

```objective-c
- (void)webView:(WebView *)webView beforeDecidePolicyForNavigationAction:(WKNavigationAction *)navigationAction;
- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;
- (void)webView:(WebView *)webView afterDecidePolicyForNavigationAction:(WKNavigationAction *)navigationAction;
- (void)webView:(WebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler;
- (void)webView:(WebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation;
- (void)webView:(WebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation;
- (void)webView:(WebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error;
- (void)webView:(WebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation;
- (void)webView:(WebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation;
- (void)webView:(WebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error;
- (void)webView:(WebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler;
- (void)webViewWebContentProcessDidTerminate:(WebView *)webView;
- (void)webViewDidClose:(WebView *)webView;
```
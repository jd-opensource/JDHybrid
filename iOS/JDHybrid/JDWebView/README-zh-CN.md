# JDWebView

## cocoapods 使用JDWebView
```ruby
pod 'JDHybrid/JDWebView'
```

## JDWebView简介

JDWebView提供了容器WebView继承了UIView，并添加了WKWebView作为子View，容器提供了以下几种能力的支持

### KVO监听

```objective-c
/// KVO, loading progress
@property(nonatomic, assign, readonly)float                       estimatedProgress;

/// KVO, document.title
@property(nonatomic, copy, readonly)NSString                      *title;

/// KVO, loading URL
@property(nonatomic, strong, readonly)NSURL                       *URL;
```

### JSBridge的支持（基于JDBridge）
```objective-c
@property(nonatomic, strong, readonly)JDBridgeManager              *jsBridgeManager;

```

### WKWebViewConfigure的默认设置与音视频播放行为控制
```objective-c
/// default
+ (WKWebViewConfiguration *)defaultConfiguration;

/// repair wkconfiguration
/// @param configuration the configuration you want to repair
/// @param required weather need useraction
- (void)configuration:(WKWebViewConfiguration *)configuration requiringUserActionForPlayback:(BOOL)required;
```

### WKWebView UIDelegate的默认实现

```objective-c
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler;

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler;

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler;
```

### 添加UserSciprt
```objective-c
- (void)addUserScript:(NSString *)javaScript
        injectionTime:(WKUserScriptInjectionTime)injectTime
     forMainFrameOnly:(BOOL)onlyForMainFrame;
```


### WebView JSBridge能力
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

### WebView delegate （基于WKNavigationDelegate与UIDelegate）

```objective-c
- (void)webView:(JDWebViewContainer *)webView beforeDecidePolicyForNavigationAction:(WKNavigationAction *)navigationAction;
- (void)webView:(JDWebViewContainer *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;
- (void)webView:(JDWebViewContainer *)webView afterDecidePolicyForNavigationAction:(WKNavigationAction *)navigationAction;
- (void)webView:(JDWebViewContainer *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler;
- (void)webView:(JDWebViewContainer *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation;
- (void)webView:(JDWebViewContainer *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation;
- (void)webView:(JDWebViewContainer *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error;
- (void)webView:(JDWebViewContainer *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation;
- (void)webView:(JDWebViewContainer *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation;
- (void)webView:(JDWebViewContainer *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error;
- (void)webView:(JDWebViewContainer *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler;
- (void)webViewWebContentProcessDidTerminate:(JDWebViewContainer *)webView;
- (void)webViewDidClose:(JDWebViewContainer *)webView; //when js call window.close;
```
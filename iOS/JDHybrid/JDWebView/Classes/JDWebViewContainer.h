//
//  JDWebView.h
//  JDBridge
/*
 MIT License

Copyright (c) 2022 JD.com, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class JDBridgeManager,JDBridgeBasePlugin;
@protocol WebViewDelegate;

NS_ASSUME_NONNULL_BEGIN

/// WebView Container
@interface JDWebViewContainer : UIView

/// real WKWebView
@property(nonatomic, strong, readonly)WKWebView                   *realWebView;

@property(nonatomic, weak)id<WebViewDelegate>                     delegate;

/// jsbridge manager
@property(nonatomic, strong, readonly)JDBridgeManager              *jsBridgeManager;

/// custom UA
@property(nonatomic, copy)NSString                                *customUserAgent;

/// KVO, loading progress
@property(nonatomic, assign, readonly)float                       estimatedProgress;

/// KVO, document.title
@property(nonatomic, copy, readonly)NSString                      *title;

/// KVO, loading URL
@property(nonatomic, strong, readonly)NSURL                       *URL;

/// default
+ (WKWebViewConfiguration *)defaultConfiguration;


/// repair wkconfiguration
/// @param configuration the configuration you want to repair
/// @param required weather need useraction
- (void)configuration:(WKWebViewConfiguration *)configuration requiringUserActionForPlayback:(BOOL)required;

/// initialize JDWebView by defaultConfiguration
/// @param frame frame
- (instancetype)initWithFrame:(CGRect)frame;

/// initialize JDWebView by custom configuration
/// @param frame frame
/// @param configuration custom configuration
- (instancetype)initWithFrame:(CGRect)frame configuration:(nonnull WKWebViewConfiguration *)configuration;

/// add javascript to webview
/// @param javaScript custom javasript string
/// @param injectTime injectTime
/// @param onlyForMainFrame onlyForMainFrame description
- (void)addUserScript:(NSString *)javaScript
        injectionTime:(WKUserScriptInjectionTime)injectTime
     forMainFrameOnly:(BOOL)onlyForMainFrame;

/// if had history
- (BOOL)canGoBack;

/// go previous page
- (void)goBack;

/// if had next page
- (BOOL)canGoForward;

/// go next page
- (void)goForward;

/// stop loading
- (void)stopLoading;

/// isloading?
- (BOOL)isLoading;

@end

@interface JDWebViewContainer (Load)

/// load a url string
/// @param urlString urlstring
- (void)loadURLString:(NSString *)urlString;


/// load a nsurl
/// @param url url
- (void)loadURL:(NSURL *)url;

/// load a request
/// @param request request
- (void)loadRequest:(NSURLRequest *)request;

/// load a file
/// @param URL file url
/// @param readAccessURL for security, specify a url webview can load
- (void)loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL;

/// load htmlstring
/// @param htmlString htmlstring
/// @param baseURL htmlstring location
- (void)loadHTMLString:(nonnull NSString *)htmlString baseURL:(nullable NSURL *)baseURL;

@end


@interface JDWebViewContainer (Event)

/// App or webview event to h5
/// @param eventName eventName
- (void)dispatchEvent:(NSString *)eventName;

/// App or webview event to h5 with params
/// @param eventName eventName
/// @param params params
- (void)dispatchEvent:(NSString *)eventName params:(nullable id)params;

/// webview will appear
- (void)viewWillAppear;

/// webview will disappear
- (void)viewWillDisAppear;

@end


@interface JDWebViewContainer (JSBridge)


/// resgister js message handlers
/// @param messageHandlers messageHandlers Array
- (void)registerMessageHandlers:(NSArray *)messageHandlers;


/// set default plugin name, which should inherited JDBridgeBasePlugin
/// @param defaultJsPlugin  plugin
- (void)registerDefaultPlugin:(JDBridgeBasePlugin *)defaultJsPlugin;

/// call default js plugin which named with prooperty defaultJsPluginName
/// @param message message, eg: built_in NSDictionary、NSArray、NSString、 NSNumber
/// @param callback callback from js.
- (void)callDefaultJSBridgeWithParams:(id)message
                             callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback;

///  call  jsplugin  name
/// @param pluginName  js plugin name
/// @param message  message, eg: built_in NSDictionary、NSArray、NSString、 NSNumber
/// @param callback callback from js.
- (void)callJSWithPluginName:(nullable NSString *)pluginName
                      params:(nullable id)message
                    callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback;

/// call js plugin with progress and callback
/// @param pluginName plugin name
/// @param message message, it must be NSString, NSArray, NSNumber, NSDictionary
/// @param progress progress callback
/// @param callback final callback
- (void)callJSWithPluginName:(nullable NSString *)pluginName
                      params:(nullable id)message
                    progress:(void(^)(id _Nullable obj))progress
                    callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback;

@end


@protocol WebViewDelegate <NSObject>
@optional
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
@end

NS_ASSUME_NONNULL_END

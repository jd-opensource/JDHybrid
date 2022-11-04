//
//  XWebView.h
//  JDBridge
//
//  Created by mabaoyan on 2022/6/28.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class JDBridgeManager,JDBridgeBasePlugin;
@protocol WebViewDelegate;

NS_ASSUME_NONNULL_BEGIN

/// WebView Container
@interface XWebViewContainer : UIView

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

/// initialize XWebView by defaultConfiguration
/// @param frame frame
- (instancetype)initWithFrame:(CGRect)frame;

/// initialize XWebView by custom configuration
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

/// load a request
/// @param request request
- (void)loadRequest:(NSURLRequest *)request;

/// load a file
/// @param URL file url
/// @param readAccessURL for security, specify a url webview can load
- (void)loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL;


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


@interface XWebViewContainer (Event)

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


@interface XWebViewContainer (JSBridge)


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
- (void)webView:(XWebViewContainer *)webView beforeDecidePolicyForNavigationAction:(WKNavigationAction *)navigationAction;
- (void)webView:(XWebViewContainer *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;
- (void)webView:(XWebViewContainer *)webView afterDecidePolicyForNavigationAction:(WKNavigationAction *)navigationAction;
- (void)webView:(XWebViewContainer *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler;
- (void)webView:(XWebViewContainer *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation;
- (void)webView:(XWebViewContainer *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation;
- (void)webView:(XWebViewContainer *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error;
- (void)webView:(XWebViewContainer *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation;
- (void)webView:(XWebViewContainer *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation;
- (void)webView:(XWebViewContainer *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error;
- (void)webView:(XWebViewContainer *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler;
- (void)webViewWebContentProcessDidTerminate:(XWebViewContainer *)webView;
- (void)webViewDidClose:(XWebViewContainer *)webView; //when js call window.close;
@end

NS_ASSUME_NONNULL_END

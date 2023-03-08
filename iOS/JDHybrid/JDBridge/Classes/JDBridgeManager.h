//
//  JDBridgeManager.h
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


#import <Foundation/Foundation.h>
#import "JDBridgeBasePlugin.h"
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

/// An Object to manager jsbridge
@interface JDBridgeManager : NSObject

//you may have the same bridge with WKScriptMessageHandler. just turn your bridge instance here.
@property(nonatomic, weak)id<WKScriptMessageHandler>       jdBridgeDelegate;

/// return a  manager
/// @param webView  wkwebview instance only, or will return nil.
/// important : JDBridgeManager ----> weak ----> webView, so you must make it strong in other instance
+ (nullable JDBridgeManager *)bridgeForWebView:(WKWebView *)webView;

/// to add your custom message handlers, you may add serval handlers for diffent functions.
/// eg.
///  messageHandler is@[@"XWebView"] .
/// window.webkit.messageHandlers.XWebView.postMessage(obj) can invoke
/// we had remove messagehandlers while JDBridgeManager dealloc
/// @param messageHanders  messageHandlers
- (void)addScriptMessageHandlers:(NSArray<NSString *> *)messageHanders;

/// remove all messageHandlers, it is not required!
- (void)unregisterScriptMessageHandler;

/// add userscript
/// @param userScript userscript
/// @param injectTime injecttime
/// @param forMainFrameOnly position
- (void)addUserScript:(NSString *)userScript
           injectTime:(WKUserScriptInjectionTime)injectTime
     forMainFrameOnly:(BOOL)forMainFrameOnly;

@end


@interface JDBridgeManager (JSAPI)

/// for jsbridge: if page is changed, we reset some state
- (void)resetJsContext;

/// register default jsPlugin
/// @param defaultPlugin default jsPlugin
- (void)registerDefaultPlugin:(JDBridgeBasePlugin *)defaultPlugin;

/// call default js plugin which named with prooperty defaultJsPluginName
/// @param message message, eg: built_in NSDictionary、NSArray、NSString、 NSNumber
/// @param callback callback from js.
- (void)callDefaultPluginWithParams:(id)message
                             callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback;

///Call js plugin with callback
/// @param message message, it must be NSString, NSArray, NSNumber, NSDictionary
/// @param pluginName jsplugin name
/// @param callback callback from webview.
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
                    progress:(nullable void(^)(id _Nullable obj))progress
                    callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback;

@end


@interface JDBridgeManager (Event)

/// App or webview event to h5
/// @param eventName eventName
- (void)dispatchEvent:(NSString *)eventName;

/// App or webview event to h5 with params
/// @param eventName eventName
/// @param params params: NSArray, NSString, NSDictionary, NSNumber
- (void)dispatchEvent:(NSString *)eventName params:(id _Nullable)params;

@end




NS_ASSUME_NONNULL_END



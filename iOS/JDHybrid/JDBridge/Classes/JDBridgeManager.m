//
//  JDBridgeManager.m
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


#import "JDBridgeManager.h"
#import "JDBridgePluginUtils.h"
#import <WebKit/WebKit.h>
#import "JDBridgeBasePlugin.h"
#import "JDBridgeManagerPrivate.h"
#import "JDBridgeBasePluginPrivate.h"
#import "_jdbridge.h"

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)

static NSString *KJDBridgeDefaultPlugin = @"JDBridgeDefaultPlugin";

static NSString *KInjectJS = @";(function(){if(window.XWebView===undefined){window.XWebView={};window.XWebView.callNative=function(module,method,params,callbackName,callbackId){window.webkit.messageHandlers.XWebView.postMessage({'plugin':module,'method':method,'params':params,'callbackName':callbackName,'callbackId':callbackId})};window.XWebView._callNative=function(jsonstring){window.webkit.messageHandlers.XWebView.postMessage(jsonstring)}}})();";

static NSString *KJDBridgeInnerMethod = @"window.JDBridge && window.JDBridge._handleRequestFromNative && window.JDBridge._handleRequestFromNative";

@interface JDBridgeMessageHandler : NSObject<WKScriptMessageHandler>

@property (nonatomic, strong)NSMutableDictionary        *jdBridgePluginMap;
@property (nonatomic, weak)id<WKScriptMessageHandler>    jdBridgeDelegate;
@property (nonatomic, weak)id<JDBridgeInnerProtocol>     jdBridgeInnerDelegate;
@property (nonatomic, strong)JDBridgeBasePlugin          *defaultPlugin;

@end

@implementation JDBridgeMessageHandler
{
    WKUserContentController * _userContentController;
}


#pragma mark --- WKWebView javascript

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    _userContentController = userContentController;
    if ([NSThread isMainThread]) {
        [self invokeJsMethodWithMessage:message];
    }
    else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self invokeJsMethodWithMessage:message];
        });
    }
    
}

- (void)invokeJsMethodWithMessage:(WKScriptMessage *)message{
    NSDictionary *body = message.body;
    if ([body isKindOfClass:[NSString class]]) {
        body = [JDBridgePluginUtils jsonStrToDictionary:(NSString *)body];
    }
    
    NSString *pluginName = nil;
    if ([JDBridgePluginUtils validateDictionary:body]) {
        pluginName = body[KJDBridgePlugin];
    }
    if ([JDBridgePluginUtils validateString:pluginName]) {
        [self invokeJsMethodWithBody:body message:message];
        return;
    }
    
    //maybe you have other choice!!!!
    if (self.jdBridgeDelegate && [self.jdBridgeDelegate respondsToSelector:@selector(userContentController:didReceiveScriptMessage:)]) {
        [self.jdBridgeDelegate userContentController:_userContentController didReceiveScriptMessage:message];
    }
}

- (void)invokeJsMethodWithBody:(NSDictionary *)body message:(WKScriptMessage *)message{
    NSString *pluginName = body[KJDBridgePlugin] ? body[KJDBridgePlugin] : @"";
    NSString *method = body[KJDBridgeMethod]?:body[KJDBridgeAction];
    NSDictionary *params = body[KJDBridgeParams];
    if ([params isKindOfClass:[NSString class]]) {//if js post a jsonString, try parse it!
        params = [JDBridgePluginUtils jsonStrToDictionary:(NSString *)params]?:body[KJDBridgeParams]; //if parse json fail，then keep it
    }
    
    JDBridgeCallBack *callback = [JDBridgeCallBack callback]; //once call one callback
    callback.message = message;
    
    JDBridgeBasePlugin *plugin = self.jdBridgePluginMap[pluginName];
    if (!plugin) {//first call bridge
        plugin = [[NSClassFromString(pluginName) alloc] init];
        
        // no plugin named "pluginName"
        if (!plugin || ![plugin isKindOfClass:[JDBridgeBasePlugin class]]) {
            // when met invalid plugin, then we set default plugin here! make sure user setting first
            plugin = self.defaultPlugin?:self.jdBridgePluginMap[KJDBridgeDefaultPlugin];
            [plugin inValidBridgeCallBack:callback message:@"plugin not found"];
            return;
        }
        
        //just do it once
        if ([JDBridgePluginUtils validateString:pluginName]) {
            self.jdBridgePluginMap[pluginName] = plugin;
        }
    }
    
    if ([plugin isKindOfClass:[_jdbridge class]]) {
        [(_jdbridge *)plugin setJDBridgeDelegate:self.jdBridgeInnerDelegate];
    }
    
    if ([plugin respondsToSelector:@selector(excute:params:callback:)]) {
        BOOL isInvoked = [plugin excute:method params:params callback:callback];
        if (!isInvoked) {
            [plugin inValidBridgeCallBack:callback message:@"plugin not found"];
        }
    }
}

//lazy load
- (NSMutableDictionary *)jdBridgePluginMap{
    if (!_jdBridgePluginMap) {
        _jdBridgePluginMap = [NSMutableDictionary dictionary];
        _jdBridgePluginMap[KJDBridgeDefaultPlugin] = [JDBridgeBasePlugin new];
    }
    return _jdBridgePluginMap;
}

@end


@interface JDBridgeManager ()<JDBridgeInnerProtocol>

@property (nonatomic, weak)WKWebView                    *jdBridgeWebView;
@property (nonatomic, strong)NSMutableArray             *jdBridgeHandlers;
@property (nonatomic, strong)JDBridgeMessageHandler     *jdBridgeMessageHandler;
@property (nonatomic, strong)NSMutableDictionary        *nativeCallbackMap;
@property (nonatomic, strong)NSMutableDictionary        *nativeProgressMap;
@property (nonatomic, strong)NSMutableArray             *nativeCallJsQueue;

@end

@implementation JDBridgeManager
{
    NSInteger                  _callbackId;
    BOOL                       _jsInit;
}

+ (nullable JDBridgeManager *)bridgeForWebView:(WKWebView *)webView{
    if (webView && [webView isKindOfClass:[WKWebView class]]) {
        return [[[self class] alloc] initWithWebView:webView];
    }
    else{
        return nil;//only support wkwebview
    }
}

- (void)dealloc{
    [self _removeAllScripts];
    [self _unregisterScriptMessageHandler];
}

- (void)setJdBridgeDelegate:(id<WKScriptMessageHandler>)jdBridgeDelegate{
    _jdBridgeMessageHandler.jdBridgeDelegate = jdBridgeDelegate;
}

- (instancetype)initWithWebView:(WKWebView *)webView{
    if (self = [super init]) {
        _jdBridgeWebView = webView;
        _jdBridgeHandlers = [NSMutableArray arrayWithObjects:@"XWebView",@"JDBridge", nil];
        _jdBridgeMessageHandler = [JDBridgeMessageHandler new];
        _jdBridgeMessageHandler.jdBridgeInnerDelegate = (id<JDBridgeInnerProtocol>)self;
        [self _initializeJSBridge];
    }
    return self;
}

- (void)addScriptMessageHandlers:(NSArray *)messageHanders {
    NSArray *moduleArr = [self.jdBridgeHandlers copy];
    if(messageHanders) {
        for (NSString *handlerName in messageHanders) {
            if(![moduleArr containsObject:handlerName]) {
                [self.jdBridgeHandlers addObject:handlerName];
            }
        }
    }
    [self _registerMessageHandlers];
}

- (void)_registerScriptMessageHandler {
    for (NSString *moduleName in self.jdBridgeHandlers) {
        [_jdBridgeWebView.configuration.userContentController addScriptMessageHandler:self.jdBridgeMessageHandler name:moduleName];
    }
}

- (void)_unregisterScriptMessageHandler {
    for (NSString *moduleName in self.jdBridgeHandlers) {
        [_jdBridgeWebView.configuration.userContentController removeScriptMessageHandlerForName:moduleName];
    }
}

- (void)unregisterScriptMessageHandler{
    [self _unregisterScriptMessageHandler];
}


- (void)_initializeJSBridge{
    [self _registerMessageHandlers];
    [self _addUserScript:KInjectJS // we inject some javascript to unify iOS&Android
             injectTime:WKUserScriptInjectionTimeAtDocumentStart
       forMainFrameOnly:NO];
}

- (void)_registerMessageHandlers{
    @try {
        [self _unregisterScriptMessageHandler];// if you add handlers repeatlly, it will be crash.
        [self _registerScriptMessageHandler];
    }
    @catch (NSException *exception) {
        NSLog(@"attempt to add scripthandler existed!");
    }
}

#pragma mark -- Userscript

- (void)addUserScript:(NSString *)userScript
           injectTime:(WKUserScriptInjectionTime)injectTime
     forMainFrameOnly:(BOOL)forMainFrameOnly{
    [self _addUserScript:userScript injectTime:injectTime forMainFrameOnly:forMainFrameOnly];
}

- (void)_addUserScript:(NSString *)userScript
           injectTime:(WKUserScriptInjectionTime)injectTime
     forMainFrameOnly:(BOOL)forMainFrameOnly{
    WKUserScript *xscript = [[WKUserScript alloc] initWithSource:userScript
                                                   injectionTime:injectTime
                                                forMainFrameOnly:forMainFrameOnly];
    [self.jdBridgeWebView.configuration.userContentController addUserScript:xscript];
}

- (void)_removeAllScripts{
    [_jdBridgeWebView.configuration.userContentController removeAllUserScripts];
}

#pragma mark -- js plugin

- (NSMutableDictionary *)nativeCallbackMap{
    if (!_nativeCallbackMap) {
        _nativeCallbackMap = [NSMutableDictionary dictionary];
    }
    return _nativeCallbackMap;
}

- (NSMutableDictionary *)nativeProgressMap{
    if (!_nativeProgressMap) {
        _nativeProgressMap = [NSMutableDictionary dictionary];
    }
    return _nativeProgressMap;
}

- (NSMutableArray *)nativeCallJsQueue{
    if (!_nativeCallJsQueue) {
        _nativeCallJsQueue = [NSMutableArray array];
    }
    return _nativeCallJsQueue;
}

- (void)resetJsContext{
    _jsInit = NO;
    [self.nativeCallbackMap removeAllObjects];
}

- (void)registerDefaultPlugin:(JDBridgeBasePlugin *)defaultPlugin{
    _jdBridgeMessageHandler.defaultPlugin = defaultPlugin;
}

- (void)callDefaultPluginWithParams:(id)message
                             callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback{
    [self callJSWithPluginName:nil params:message callback:callback];
}

- (void)callJSWithPluginName:(NSString *)pluginName
                      params:(id)message
                    callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback{
    [self callJSWithPluginName:pluginName params:message progress:nil callback:callback];
}

- (void)callJSWithPluginName:(NSString *)pluginName
                      params:(id)message
                    progress:(nullable void(^)(id _Nullable obj))progress
                    callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback{
    NSString *eventKey = [NSString stringWithFormat:@"n2js_%@", @(_callbackId++)];
    NSDictionary *dic = @{
        KJDBridgeStatus:     @"0",
        KJDBridgeParams:     message?:@"",
        KJDBridgeMsg:        @"",
        KJDBridgePlugin:     pluginName?:@"",
        KJDBridgeCallbackId: eventKey
    };
    if (!_jsInit) {
        self.nativeCallbackMap[eventKey] = callback;
        self.nativeProgressMap[eventKey] = progress;
        [self.nativeCallJsQueue addObject:dic];
        return;
    }
    
    [self processNativeCallJsWithParams:dic];
}

- (void)processNativeCallJsWithParams:(NSDictionary *)params{
    NSString *str = [JDBridgePluginUtils serializeMessage:params];
    if (!str) {
        return;
    }
    NSString *callBackStr = [NSString stringWithFormat:@"%@(\'%@\')",KJDBridgeInnerMethod,str];
    [_jdBridgeWebView evaluateJavaScript:callBackStr completionHandler:nil];
}


#pragma mark -- js event

- (void)dispatchEvent:(NSString *)eventName{
    [self dispatchEvent:eventName params:nil];
}

- (void)dispatchEvent:(NSString *)eventName params:(id _Nullable)params{
    id detail = nil;
    if ([params isKindOfClass:[NSString class]] || [params isKindOfClass:[NSNumber class]]) {
        detail = params;
    }
    else if (![NSJSONSerialization isValidJSONObject:params]){
        detail = [params description];
    }
    else{
        detail = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:params options:0 error:nil] encoding:NSUTF8StringEncoding];
    }
    
    NSString *eventjs = [NSString stringWithFormat:@";(function(){var jdbridgeEvent = new CustomEvent('%@', {'detail': %@}); window.dispatchEvent(jdbridgeEvent);})()", eventName, detail];
    [self.jdBridgeWebView evaluateJavaScript:eventjs completionHandler:nil];
}

#pragma mark -- JDBridgeInnerProtocol

- (void)jsbridgeInit{
    _jsInit = YES;
    if (self.nativeCallJsQueue.count>0) {
        for (NSDictionary *dic in self.nativeCallJsQueue) {
            [self processNativeCallJsWithParams:dic];
        }
    }
}

- (void)jsbridgeResponseWithCallbackId:(NSString *)callbackId params:(id)params error:(NSError *)error{
    if (![JDBridgePluginUtils validateString:callbackId]) {
        return;
    }
    BOOL complete = [params[KJDBridgeComplete] boolValue];
    if (!complete) {
        void(^progressBlock)(id _Nullable obj) = self.nativeProgressMap[callbackId];
        if (progressBlock) {
            progressBlock(params[KJDBridgeData]);
        }
    }
    if (complete) {
        void(^block)(id _Nullable obj, NSError * _Nullable error) = self.nativeCallbackMap[callbackId];
        if (block) {
            block(params[KJDBridgeData], error);
        }
        [self.nativeCallbackMap removeObjectForKey:callbackId];
        [self.nativeProgressMap removeObjectForKey:callbackId];
    }
}

@end


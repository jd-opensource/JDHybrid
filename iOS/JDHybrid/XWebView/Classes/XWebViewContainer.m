//
//  XWebView.m
//  JDBridge
//
//  Created by mabaoyan on 2022/6/28.
//

#import "XWebViewContainer.h"
#import "JDBridgeManager.h"
#import "JDBridgePluginUtils.h"

typedef void(^WebKitAlertBlock)(void);

@interface XWebViewContainer()

@property(nonatomic, copy)WebKitAlertBlock              alertBlock;
@property(nonatomic, copy)WebKitAlertBlock              confirmBlock;
@property(nonatomic, copy)WebKitAlertBlock              textInputBlock;
@property(nonatomic, strong)UIAlertController           *alertCtrl;

@end


@interface XWebViewContainer()<WKUIDelegate, WKNavigationDelegate>

@property(nonatomic, strong, readwrite)JDBridgeManager              *jsBridgeManager;
@property(nonatomic, strong, readwrite)WKWebView                   *realWebView;
@property(nonatomic, assign, readwrite)float                       estimatedProgress;
@property(nonatomic, copy, readwrite)NSString                      *title;
@property(nonatomic, strong, readwrite)NSURL                       *URL;

@end

@implementation XWebViewContainer

+ (WKProcessPool *)processPool{
    static dispatch_once_t onceToken;
    static WKProcessPool *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [WKProcessPool new];
    });
    return sharedInstance;
}

+ (WKWebViewConfiguration *)defaultConfiguration{
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    WKPreferences *preferences = [WKPreferences new];
    preferences.javaScriptCanOpenWindowsAutomatically = YES;
    
    configuration.processPool = [XWebViewContainer processPool];
    if (@available(iOS 13.0, *)) {
        configuration.defaultWebpagePreferences.preferredContentMode = WKContentModeMobile;
    }
    configuration.allowsInlineMediaPlayback = YES;
    return configuration;
}

- (void)configuration:(WKWebViewConfiguration *)configuration requiringUserActionForPlayback:(BOOL)required{
        if (@available(iOS 10.0, *)) {
            if (required) {
                configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeAll;
            }
            else{
                configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
            }
        } else {
            // Fallback on earlier versions
            configuration.requiresUserActionForMediaPlayback = required;
        }
}

- (void)dealloc{
    [_realWebView removeObserver:self forKeyPath:@"estimatedProgress"];
    [_realWebView removeObserver:self forKeyPath:@"title"];
    [_realWebView removeObserver:self forKeyPath:@"URL"];
    
    if (_alertBlock) _alertBlock();
    if (_confirmBlock) _confirmBlock();
    if (_textInputBlock) _textInputBlock();

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame configuration:[XWebViewContainer defaultConfiguration]];
}

- (instancetype)initWithFrame:(CGRect)frame configuration:(nonnull WKWebViewConfiguration *)configuration{
    if (self = [super initWithFrame:frame]) {
        _realWebView = [[WKWebView alloc]initWithFrame:self.bounds configuration:configuration];
        _jsBridgeManager = [JDBridgeManager bridgeForWebView:_realWebView];
        _realWebView.UIDelegate = (id<WKUIDelegate>)self;
        _realWebView.navigationDelegate = (id<WKNavigationDelegate>)self;
        [_realWebView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
        [_realWebView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
        [_realWebView addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionNew context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_xWebViewDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_xWebViewWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

        [self addSubview:self.realWebView];
    }
    return self;
}


- (void)addUserScript:(NSString *)javaScript
        injectionTime:(WKUserScriptInjectionTime)injectTime
     forMainFrameOnly:(BOOL)onlyForMainFrame{
    WKUserScript *userscript = [[WKUserScript alloc] initWithSource:javaScript
                                                      injectionTime:injectTime
                                                   forMainFrameOnly:onlyForMainFrame];
    [self.realWebView.configuration.userContentController addUserScript:userscript];
}

- (void)loadRequest:(NSURLRequest *)request{
    [_realWebView loadRequest:request];
}

- (void)loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL{
    [_realWebView loadFileURL:URL allowingReadAccessToURL:readAccessURL];
}

- (void)setCustomUserAgent:(NSString *)customUserAgent{
    _realWebView.customUserAgent = customUserAgent;
}

- (BOOL)canGoBack{
    return [_realWebView canGoBack];
}

- (void)goBack{
    [_realWebView goBack];
}

- (BOOL)canGoForward{
    return [_realWebView goForward];
}

- (void)goForward{
    [_realWebView goForward];
}

- (void)stopLoading {
    [_realWebView stopLoading];
}

- (BOOL)isLoading {
    return [_realWebView isLoading];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"estimatedProgress"] && [change[NSKeyValueChangeNewKey] isKindOfClass:[NSNumber class]])
    {
        self.estimatedProgress = [change[NSKeyValueChangeNewKey] doubleValue];
    }
    else if([keyPath isEqualToString:@"title"] && [change[NSKeyValueChangeNewKey] isKindOfClass:[NSString class]])
    {
        self.title = change[NSKeyValueChangeNewKey];
    }
    else if ([keyPath isEqualToString:@"URL"] && [change[NSKeyValueChangeNewKey] isKindOfClass:[NSURL class]]){
        self.URL = change[NSKeyValueChangeNewKey];
    }
    else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -- XWebView JSBridge

- (void)registerDefaultPlugin:(JDBridgeBasePlugin *)defaultJsPlugin{
    [self.jsBridgeManager registerDefaultPlugin:defaultJsPlugin];
}

- (void)registerMessageHandlers:(NSArray *)messageHandlers{
    [self.jsBridgeManager addScriptMessageHandlers:messageHandlers];
}

- (void)callDefaultJSBridgeWithParams:(id)message
                             callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback{
    [self callJSWithPluginName:nil params:message callback:callback];
}

- (void)callJSWithPluginName:(nullable NSString *)pluginName
                      params:(nullable id)message
                    callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback{
    [self.jsBridgeManager callJSWithPluginName:pluginName
                                        params:message
                                      callback:callback];
}

- (void)callJSWithPluginName:(nullable NSString *)pluginName
                      params:(nullable id)message
                    progress:(void(^)(id _Nullable obj))progress
                    callback:(void(^)(id _Nullable obj, NSError * _Nullable error))callback{
    [self.jsBridgeManager callJSWithPluginName:pluginName
                                        params:message
                                      progress:progress
                                      callback:callback];
}


#pragma mark -- XWebView Event
- (void)viewWillAppear{
    [self dispatchEvent:@"ContainerShow"];
}

- (void)viewWillDisAppear{
    [self dispatchEvent:@"ContainerHide"];
}

- (void)_xWebViewDidEnterBackground:(NSNotification *)notification {
    [self dispatchEvent:@"AppHide"];
}

- (void)_xWebViewWillEnterForeground:(NSNotification *)notification {
    [self dispatchEvent:@"AppShow"];
}


- (void)dispatchEvent:(NSString *)eventName{
    [self dispatchEvent:eventName params:nil];
}

- (void)dispatchEvent:(NSString *)eventName params:(nullable id)params{
    [self.jsBridgeManager dispatchEvent:eventName params:params];
}

#pragma mark -- NavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    if ([self.delegate respondsToSelector:@selector(webView:beforeDecidePolicyForNavigationAction:)]) {
        [self.delegate webView:self beforeDecidePolicyForNavigationAction:navigationAction];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:_cmd]) {
        [self.delegate webView:self decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    }
    else{
        decisionHandler(WKNavigationActionPolicyAllow);
    }
    
    if ([self.delegate respondsToSelector:@selector(webView:afterDecidePolicyForNavigationAction:)]) {
        [self.delegate webView:self afterDecidePolicyForNavigationAction:navigationAction];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    if (self.delegate && [self.delegate respondsToSelector:_cmd]) {
        [self.delegate webView:self decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
    }
    else{
        decisionHandler(WKNavigationResponsePolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation{
    [self.jsBridgeManager resetJsContext];
    if (self.delegate && [self.delegate respondsToSelector:_cmd]) {
        [self.delegate webView:self didStartProvisionalNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation{
    if (self.delegate && [self.delegate respondsToSelector:_cmd]) {
        [self.delegate webView:self didReceiveServerRedirectForProvisionalNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error{
    if (self.delegate && [self.delegate respondsToSelector:_cmd]) {
        [self.delegate webView:self didFailProvisionalNavigation:navigation withError:error];
    }
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation{
    if (self.delegate && [self.delegate respondsToSelector:_cmd]) {
        [self.delegate webView:self didCommitNavigation:navigation];
    }}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation{
    if (self.delegate && [self.delegate respondsToSelector:_cmd]) {
        [self.delegate webView:self didFinishNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error{
    if (self.delegate && [self.delegate respondsToSelector:_cmd]) {
        [self.delegate webView:self didFailNavigation:navigation withError:error];
    }
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    if (self.delegate && [self.delegate respondsToSelector:_cmd]) {
        [self.delegate webView:self didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
    }
    else{
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
    if (self.delegate && [self.delegate respondsToSelector:_cmd]) {
        [self.delegate webViewWebContentProcessDidTerminate:self];
    }
    else{
        [webView reload];
    }
}

#pragma mark --- UIDelegate

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    __block BOOL hasFinished = NO;//有可能崩溃！！！！！！
    if (self.alertBlock) {
        self.alertBlock();
    }
    self.alertBlock = ^{
        if (!hasFinished) {
            completionHandler();
            hasFinished = YES;
        }
    };
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    NSString *buttonTitle = @"确定";
    
    [alertController addAction:[UIAlertAction actionWithTitle:buttonTitle
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
        if (!hasFinished) {
            completionHandler();
            hasFinished = YES;
        }
    }]];
    
    if (self.alertCtrl)
    {
        [self.alertCtrl dismissViewControllerAnimated:NO
                                           completion:NULL];
        self.alertCtrl = nil;
    }
    
    self.alertCtrl = alertController;
    
    [[self webviewController] presentViewController:self.alertCtrl animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler{
    if (self.confirmBlock) {
        self.confirmBlock();
    }
    __block BOOL hasFinished = NO;//有可能崩溃！！！！！！
    self.confirmBlock = ^{
        if (!hasFinished) {
            completionHandler(NO);
            hasFinished = YES;
        }
    };
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    NSString *confirmTitle = @"确定";
    NSString *cancelTitle = @"取消";
    
    [alertController addAction:[UIAlertAction actionWithTitle:confirmTitle
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
        if (!hasFinished) {
            completionHandler(YES);
            hasFinished = YES;
        }
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:cancelTitle
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action){
        if (!hasFinished) {
            completionHandler(NO);
            hasFinished = YES;
        }
    }]];
    
    if (self.alertCtrl)
    {
        [self.alertCtrl dismissViewControllerAnimated:NO
                                           completion:NULL];
        self.alertCtrl = nil;
    }
    
    self.alertCtrl = alertController;

    [[self webviewController] presentViewController:self.alertCtrl animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler{
    if (self.textInputBlock) {
        self.textInputBlock();
    }
    __block BOOL hasFinished = NO;//有可能崩溃！！！！！！
    self.textInputBlock = ^{
        if (!hasFinished) {
            completionHandler(nil);
            hasFinished = YES;
        }
    };
    //js 里面的prompt实现，如果不实现，网页的prompt函数无效
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = defaultText;
    }];
    
    NSString *doneTitle = @"完成";
    [alertController addAction:[UIAlertAction actionWithTitle:doneTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *input = ((UITextField *)alertController.textFields.firstObject).text;
        if (!hasFinished) {
            completionHandler(input);
            hasFinished = YES;
        }
    }]];
    
    NSString *cancelTitle = @"取消";
    [alertController addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        if (!hasFinished) {
            completionHandler(nil);
            hasFinished = YES;
        }
    }]];
    
    if (self.alertCtrl)
    {
        [self.alertCtrl dismissViewControllerAnimated:NO
                                           completion:NULL];
        self.alertCtrl = nil;
    }
    
    self.alertCtrl = alertController;
    
    [[self webviewController] presentViewController:self.alertCtrl animated:YES completion:nil];
}

//window.open()
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{
    if(navigationAction.targetFrame == nil || !navigationAction.targetFrame.isMainFrame)
    {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

//window.close() called;
- (void)webViewDidClose:(WKWebView *)webView{
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate webViewDidClose:self];
    }
}


- (UIViewController *)webviewController {
    id vc = self;
    while (![vc isKindOfClass:[UIViewController class]]) {
        vc = [vc nextResponder];
    }
    return (UIViewController *)vc;
}

@end

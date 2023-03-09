//
//  JDWebViewController.m
//  JDHybrid_Example
//
//  Created by wangxiaorui19 on 2023/3/9.
//  Copyright © 2023 maxiaoliang8. All rights reserved.
//

#import "JDWebViewController.h"
#import "MyDefaultPlugin.h"
#import "JDWebViewContainer.h"

@interface JDWebViewController ()<WebViewDelegate>
@property (nonatomic, strong) JDWebViewContainer * webView;
@end

@implementation JDWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"JDWebView&JDBridge";
    
    [self.view addSubview:self.webView];
    self.webView.delegate = self;
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView registerDefaultPlugin:[MyDefaultPlugin new]];
    
    NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:@"jdbridge_demo" withExtension:@"html"];
    [self.webView loadFileURL:fileUrl allowingReadAccessToURL:fileUrl];
        
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [_webView viewWillAppear];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [_webView viewWillDisAppear];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"title"] && [change[NSKeyValueChangeNewKey] isKindOfClass:[NSString class]])
    {
        self.title = change[NSKeyValueChangeNewKey];
    }
    else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)webView:(JDWebViewContainer *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    decisionHandler(WKNavigationActionPolicyAllow);
    NSLog(@"stamp:%@",@([[NSDate date] timeIntervalSince1970] * 1000));
}

- (void)webView:(JDWebViewContainer *)webView didFinishNavigation:(WKNavigation *)navigation{
    [_webView dispatchEvent:@"ContainerShow" params:nil];
//    [_webView dispatchEvent:@"ContainerShow" params:@"test"];
//    [_webView dispatchEvent:@"ContainerShow" params:@[@"777",@"888"]];
//    [_webView dispatchEvent:@"ContainerShow" params:@(YES)];

    NSLog(@"stamp:%@",@([[NSDate date] timeIntervalSince1970] * 1000));
    
    [self.webView callJSWithPluginName:@"MySequenceJsPlugin" params:@{@"a":@"b"} progress:^(id _Nullable obj){
        NSLog(@"sequence---progress:%@", obj);
    } callback:^(id  _Nullable obj, NSError * _Nullable error) {
        NSLog(@"sequence---:%@",obj);
    }];
    [self.webView callJSWithPluginName:@"MyAsyncJsPlugin" params:@{@"a":@"b"} callback:^(id  _Nullable obj, NSError * _Nullable error) {
        NSLog(@"Async---:%@",obj);
    }];
    [self.webView callJSWithPluginName:@"MySyncJsPlugin" params:@{@"a":@"b"} callback:^(id  _Nullable obj, NSError * _Nullable error) {
        NSLog(@"Sync---:%@",obj);
    }];
    [self.webView callDefaultJSBridgeWithParams:@{@"a":@"b"} callback:^(id  _Nullable obj, NSError * _Nullable error) {
        NSLog(@"default---:%@",obj);
    }];

}

#pragma mark -

- (JDWebViewContainer *)webView {
    if (!_webView) {
        CGFloat y = self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
        CGSize size = UIScreen.mainScreen.bounds.size;
        _webView = [[JDWebViewContainer alloc] initWithFrame:CGRectMake(0, y, size.width, size.height - y) configuration:[JDWebViewContainer defaultConfiguration]];
    }
    return _webView;
}


@end

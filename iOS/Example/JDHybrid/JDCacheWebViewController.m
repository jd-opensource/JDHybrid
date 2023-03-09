//
//  JDCacheWebViewController.m
//  JDHybrid_Example
//
//  Created by wangxiaorui19 on 2023/3/9.
//  Copyright © 2023 maxiaoliang8. All rights reserved.
//

#import "JDCacheWebViewController.h"
#import "JDMapResourceMatcher.h"
#import "JDHybrid.h"
#import "JDCache.h"
#import <JDHybrid/JDHybrid-umbrella.h>
//#import "JDHybrid-umbrella.h"

@interface JDCacheWebViewController ()
@property (nonatomic, strong) WKWebView * webView;
@end

@implementation JDCacheWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat y = self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
    CGSize size = UIScreen.mainScreen.bounds.size;
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    
    switch (self.H5LoadType) {
        case JDCacheH5LoadTypePure:
        {
            
        }
            break;
        case JDCacheH5LoadTypeNativeNetwork:
        {
            configuration.loader.enable = YES;
        }
            break;
        case JDCacheH5LoadTypeLocalResource:
        {
            configuration.loader.enable = YES;
            NSString *rootPath = [[NSBundle mainBundle] pathForResource:@"resource" ofType:@""];
            if ([[NSFileManager defaultManager] fileExistsAtPath:rootPath]) {
                JDMapResourceMatcher *mapResourceMatcher = [[JDMapResourceMatcher alloc] initWithRootPath:rootPath];
                configuration.loader.matchers = @[mapResourceMatcher];
            }
        }
            break;
        case JDCacheH5LoadTypeLocalResourceAndPreload:
        {
            configuration.loader.enable = YES;
            NSString *rootPath = [[NSBundle mainBundle] pathForResource:@"resource" ofType:@""];
            if ([[NSFileManager defaultManager] fileExistsAtPath:rootPath]) {
                JDMapResourceMatcher *mapResourceMatcher = [[JDMapResourceMatcher alloc] initWithRootPath:rootPath];
                configuration.loader.matchers = @[mapResourceMatcher];
            }
            JDCachePreload *preload = [JDCachePreload new];
            NSURLRequest *preloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:XHLoadURL]];
            NSMutableURLRequest *requestM = [preloadRequest mutableCopy];
            NSString *ua = @"Mozilla/5.0 (iPhone; CPU iPhone OS 15_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148";
            NSString *accept = @"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";
            [requestM setValue:ua forHTTPHeaderField:@"User-Agent"];
            [requestM setValue:accept forHTTPHeaderField:@"Accept"];
            preload.request = [requestM copy];
            preload.enable = YES;
            [preload startPreload];
            configuration.loader.preload = preload;
        }
            break;
        case JDCacheH5LoadTypeLocalDegrade:
        {
            configuration.loader.enable = YES;
            NSString *rootPath = [[NSBundle mainBundle] pathForResource:@"resource" ofType:@""];
            if ([[NSFileManager defaultManager] fileExistsAtPath:rootPath]) {
                JDMapResourceMatcher *mapResourceMatcher = [[JDMapResourceMatcher alloc] initWithRootPath:rootPath];
                configuration.loader.matchers = @[mapResourceMatcher];
            }
            __weak typeof(self)weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                JDCacheLog(@"开启降级，url: %@", XHLoadURL);
                __strong typeof(weakSelf)self = weakSelf;
                configuration.loader.degrade = YES;
                [self.webView reload];
            });
        }
            break;
        default:
            break;
    }
    _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, y, size.width, size.height - y) configuration:configuration];
    [self.view addSubview:_webView];

    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:XHLoadURL]]];
}

@end

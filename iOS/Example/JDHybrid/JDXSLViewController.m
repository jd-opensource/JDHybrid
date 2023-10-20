//
//  JDXSLViewController.m

//
//  Created by zhoubaoyang on 2023/6/16.
//

#import "JDXSLViewController.h"
#import <WebKit/WebKit.h>
#import "JDXSLManager.h"
#import "JDBridgeManager.h"


@interface JDXSLViewController () <WKNavigationDelegate,WKUIDelegate, WKScriptMessageHandler>

@property (nonatomic, strong)JDBridgeManager *bridgeManager;


@end

@implementation JDXSLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blueColor];
    WKWebView* webView = nil;
    if (!webView) {
        WKWebViewConfiguration* configuration = [[NSClassFromString(@"WKWebViewConfiguration") alloc] init];
        webView = [[NSClassFromString(@"WKWebView") alloc] initWithFrame:self.view.bounds configuration:configuration];
        WKPreferences *preferences = [NSClassFromString(@"WKPreferences") new];
        preferences.javaScriptCanOpenWindowsAutomatically = YES;
        configuration.preferences = preferences;
        configuration.processPool = [self processPool];
        configuration.userContentController = [[WKUserContentController alloc] init];
        configuration.allowsInlineMediaPlayback = YES;
        if ([configuration respondsToSelector:@selector(setMediaPlaybackRequiresUserAction:)]) {
            configuration.mediaPlaybackRequiresUserAction = YES;
        }
        else if([configuration respondsToSelector:@selector(setRequiresUserActionForMediaPlayback:)]){
            configuration.requiresUserActionForMediaPlayback = YES;
        }
        else if([configuration respondsToSelector:@selector(setMediaTypesRequiringUserActionForPlayback:)]){
            configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeAll;
        }
        webView.UIDelegate = self;
        webView.navigationDelegate = self;
    }
    webView.backgroundColor = [UIColor grayColor];
    [self.view addSubview:webView];
    _bridgeManager = [JDBridgeManager bridgeForWebView:webView];
    [[JDXSLManager shareManager] initXslManagerWithWebView:webView];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"xsl-index" ofType:@"html"]]]];
}

- (WKProcessPool *)processPool{
    static WKProcessPool *pool = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        pool = [[WKProcessPool alloc] init];
    });
    return pool;
}

@end

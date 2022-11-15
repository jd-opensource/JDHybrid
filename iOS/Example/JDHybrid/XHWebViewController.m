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

#import "XHWebViewController.h"
#if __has_include(<JDHybrid/JDHybrid-umbrella.h>)
#import <JDHybrid/JDHybrid-umbrella.h>
#else
#import "JDHybrid.h"
#endif
#import "MyDefaultPlugin.h"

@interface XHWebViewController ()<WebViewDelegate>

@property (nonatomic, strong) JDWebViewContainer * webView;

@end


@implementation XHWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat y = self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
    CGSize size = UIScreen.mainScreen.bounds.size;
    if (!_configuration) {
        _configuration = [JDWebViewContainer defaultConfiguration];
    }
    _webView = [[JDWebViewContainer alloc] initWithFrame:CGRectMake(0, y, size.width, size.height - y) configuration:_configuration];
    [self.view addSubview:_webView];
    [_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    _webView.delegate = self;
    [_webView registerDefaultPlugin:[MyDefaultPlugin new]];
    if (self.loadLocalFile) {
        NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:@"jdbridge_demo" withExtension:@"html"];
        [_webView loadFileURL:fileUrl allowingReadAccessToURL:fileUrl];
        return;
    }
    [_webView loadURLString:XHLoadURL];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

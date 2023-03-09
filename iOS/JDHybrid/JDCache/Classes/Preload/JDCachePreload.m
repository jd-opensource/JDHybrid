//
//  JDCachePreload.m
//  JDHybrid
//
//  Created by wangxiaorui19 on 2022/12/9.
//

#import "JDCachePreload.h"
#import "JDNetworkSession.h"
#import "JDUtils.h"
#import "JDPreloadHtmlMatcher.h"
#import <pthread.h>

@interface JDPreloadHtmlMatcher (preload)

- (instancetype)initWithRequest:(NSURLRequest *)request delegate:(nullable id)delegate ;

- (void)preloadCallBackWithResponse:(NSURLResponse * _Nonnull)response originRequest:(NSURLRequest *)request;

- (void)preloadCallBackWithData:(NSData * _Nonnull)data  originRequest:(NSURLRequest *)request;

- (void)preloadCallBackFinshWithOriginRequest:(NSURLRequest *)request;

- (void)preloadCallBackWithError:(NSError * _Nonnull)error originRequest:(NSURLRequest *)request;

- (void)preloadCallBackRedirectWithResponse:(NSURLResponse *)response
                                 newRequest:(NSURLRequest *)redirectRequest
                           redirectDecision:(JDNetRedirectDecisionCallback)redirectDecisionCallback;

@end

@interface JDCachePreload ()<JDPreloadHtmlMatcherDataSource>

@property (nonatomic, strong) JDNetworkSession * networkSession;

@property (nonatomic, strong) JDPreloadHtmlMatcher *preloadMatcher;

@property (nonatomic, copy) JDNetResponseCallback responseCallback;

@property (nonatomic, copy) JDNetDataCallback dataCallback;

@property (nonatomic, copy) JDNetFailCallback failCallback;

@property (nonatomic, copy) JDNetSuccessCallback successCallback;

@end

@implementation JDCachePreload {
    BOOL _htmlPreloadResume; // 是否发起预加载
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _enable = NO;
        _htmlPreloadResume = NO;
    }
    return self;
}

- (JDPreloadHtmlMatcher *)defaultPreloadMatcher {
    return self.preloadMatcher;
}

- (void)startPreload {
    if (!self.enable || !self.request || _htmlPreloadResume) {
        return;
    }
    JDCacheLog(@"开始HTML预加载，url: %@", self.request.URL.absoluteString);
    JDWeak(self)
    JDNetworkDataTask *task = [self.networkSession dataTaskWithRequest:self.request
                                                      responseCallback:^(NSURLResponse * _Nonnull response) {
        JDStrong(self)
        if (!self) {
            return;
        }
        JDCacheLog(@"HTML预加载请求回调response，url: %@", self.request.URL.absoluteString);
        [self.preloadMatcher preloadCallBackWithResponse:response originRequest:self.request];
    } dataCallback:^(NSData * _Nonnull data) {
        JDStrong(self)
        if (!self) {
            return;
        }
        JDCacheLog(@"HTML预加载请求回调data，length: %ld, url: %@", data.length, self.request.URL.absoluteString);
        [self.preloadMatcher preloadCallBackWithData:data originRequest:self.request];
    } successCallback:^{
        JDStrong(self)
        if (!self) {
            return;
        }
        JDCacheLog(@"HTML预加载请求回调finish，url: %@", self.request.URL.absoluteString);
        [self.preloadMatcher preloadCallBackFinshWithOriginRequest:self.request];
    } failCallback:^(NSError * _Nonnull error) {
        JDStrong(self)
        if (!self) {
            return;
        }
        JDCacheLog(@"HTML预加载请求回调error，url: %@", self.request.URL.absoluteString);
        [self.preloadMatcher preloadCallBackWithError:error originRequest:self.request];
    } redirectCallback:^(NSURLResponse * _Nonnull response, NSURLRequest * _Nonnull redirectRequest, JDNetRedirectDecisionCallback  _Nonnull redirectDecisionCallback) {
        JDStrong(self)
        if (!self) {
            return;
        }
        [self.preloadMatcher preloadCallBackRedirectWithResponse:response newRequest:redirectRequest redirectDecision:redirectDecisionCallback];
    }];
    [task resume];
    _htmlPreloadResume = YES;
}

#pragma mark - lazy

- (JDNetworkSession *)networkSession {
    if (!_networkSession) {
        _networkSession = [JDNetworkSession sessionWithConfiguation:[JDNetworkSessionConfiguration new]];
    }
    return _networkSession;
}

- (JDPreloadHtmlMatcher *)preloadMatcher {
    if (!_preloadMatcher) {
        _preloadMatcher = [[JDPreloadHtmlMatcher alloc] initWithRequest:self.request delegate:self];
    }
    return _preloadMatcher;
}

#pragma mark - JDPreloadHtmlMatcherDataSource

- (BOOL)htmlPreloadEnable {
    return self.enable;
}

- (BOOL)htmlPreloadResume {
    return _htmlPreloadResume;
}

@end

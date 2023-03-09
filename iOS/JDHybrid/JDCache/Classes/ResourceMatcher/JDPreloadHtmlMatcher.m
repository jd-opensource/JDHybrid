//
//  JDPreloadHtmlMatcher.m
//  JDHybrid
//
//  Created by wangxiaorui19 on 2022/12/5.
//

#import "JDPreloadHtmlMatcher.h"
#import "JDUtils.h"

@interface JDPreloadHtmlMatcher ()

@property (nonatomic, strong) NSURLRequest *request;

@property (nonatomic, weak)  id<JDPreloadHtmlMatcherDataSource> delegate;

@property (nonatomic, copy) JDNetResponseCallback responseCallback;

@property (nonatomic, copy) JDNetDataCallback dataCallback;

@property (nonatomic, copy) JDNetFailCallback failCallback;

@property (nonatomic, copy) JDNetSuccessCallback successCallback;

@property (nonatomic, copy) JDNetRedirectCallback redirectCallback;

@end

@implementation JDPreloadHtmlMatcher {
    NSURLResponse * _response;
    NSMutableArray<NSData *> *_dataArray;
    BOOL _finish;
    NSError *_error;
    NSURLResponse *_redirectResponse;
    NSURLRequest *_redirectRequest;
    JDNetRedirectDecisionCallback _redirectDecisionCallback;
    
    BOOL _havePreloadDone;
    BOOL _waitFinish;
    dispatch_queue_t _preloadQueue;
}

- (instancetype)initWithRequest:(NSURLRequest *)request delegate:(nullable id<JDPreloadHtmlMatcherDataSource>)delegate{
    self = [super init];
    if (self) {
        _request = request;
        _delegate = delegate;
        _response = nil;
        _dataArray = [NSMutableArray arrayWithCapacity:0];
        _finish = NO;
        _error = nil;
        _redirectResponse = nil;
        _redirectRequest = nil;
        _redirectDecisionCallback = nil;
        _havePreloadDone = NO;
        _waitFinish = NO;
        _preloadQueue = dispatch_queue_create("com.jdhybrid.preload", DISPATCH_QUEUE_SERIAL);
        _responseCallback = nil;
        _dataCallback = nil;
        _failCallback = nil;
        _successCallback = nil;
        _redirectCallback = nil;
    }
    return self;
}

- (void)reset {
    dispatch_queue_t queue = _preloadQueue;
    JDWeak(self)
    dispatch_async(queue, ^{
        JDStrong(self)
        if (!self) {
            return;
        }
        self.responseCallback = nil;
        self.dataCallback = nil;
        self.successCallback = nil;
        self.failCallback = nil;
        self.redirectCallback = nil;
        self->_error = nil;
        self->_response = nil;
        [self->_dataArray removeAllObjects];
        self->_finish = NO;
        self->_redirectResponse = nil;
        self->_redirectRequest = nil;
        self->_redirectDecisionCallback = nil;
        self->_havePreloadDone = YES;
    });
}

- (BOOL)canHandleWithRequest:(NSURLRequest *)request {
    BOOL enable = NO;
    if ([self.delegate respondsToSelector:@selector(htmlPreloadEnable)]) {
        enable = [self.delegate htmlPreloadEnable];
    }
    if (!enable) {
        return NO;
    }
    if (_havePreloadDone) {
        return NO;
    }
    NSURL *ruleURL = self.request.URL;
    NSURL *curURL = request.URL;
    NSString *ruleURLStr = [ruleURL.host stringByAppendingPathComponent:ruleURL.path];
    NSString *curURLStr = [curURL.host stringByAppendingPathComponent:curURL.path];
    BOOL result = [ruleURLStr isEqualToString:curURLStr];
    JDCacheLog(@"是否可以从HTML预加载获取数据：%@，url: %@", result ? @"是" : @"否" ,request.URL.absoluteString);
    return result;
}

- (void)startWithRequest:(NSURLRequest *)request
        responseCallback:(JDNetResponseCallback)responseCallback
            dataCallback:(JDNetDataCallback)dataCallback
            failCallback:(JDNetFailCallback)failCallback
         successCallback:(JDNetSuccessCallback)successCallback
        redirectCallback:(JDNetRedirectCallback)redirectCallback {
    JDCacheLog(@"获取HTML预加载数据，url: %@", request.URL.absoluteString);
    dispatch_queue_t queue = _preloadQueue;
    JDWeak(self)
    //超时处理
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), queue, ^{
        JDStrong(self)
        if (!self) {
            return;
        }
        if (self->_waitFinish) {
            return;
        }
        self->_waitFinish = YES;
        failCallback([NSError errorWithDomain:NSCocoaErrorDomain
                                         code:JDCacheErrorCodeTimeout
                                     userInfo:@{@"reason": @"html preload 超时"}]);
        [self reset];
    });
    
    dispatch_async(queue, ^{
        JDStrong(self)
        if (!self) {
            return;
        }
        if ([self.delegate respondsToSelector:@selector(htmlPreloadResume)] && ![self.delegate htmlPreloadResume]) {
            JDCacheLog(@"HTML预加载获取已存储的 error，URl: %@", request.URL.absoluteString);
            failCallback([NSError errorWithDomain:NSCocoaErrorDomain
                                             code:JDCacheErrorCodePreloadUnstart
                                         userInfo:@{@"reason": @"html preload 未开始"}]);
            self->_waitFinish = YES;
            [self reset];
            return;
        }
        
        if (self->_error) {
            JDCacheLog(@"HTML预加载获取已存储的 error，URl: %@", request.URL.absoluteString);
            failCallback([NSError errorWithDomain:NSCocoaErrorDomain
                                             code:JDCacheErrorCodePreloadError
                                         userInfo:@{@"reason": @"html preload error"}]);
            self->_waitFinish = YES;
            [self reset];
            return;
        }

        if (self->_response) {
            JDCacheLog(@"HTML预加载获取已存储的 response，URl: %@", request.URL.absoluteString);
            responseCallback(self->_response);
            self->_waitFinish = YES;
        }
        if (self->_dataArray) {
            [[self->_dataArray copy] enumerateObjectsUsingBlock:^(NSData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                JDCacheLog(@"HTML预加载获取已存储的 data，length: %ld, URl: %@", obj.length ,request.URL.absoluteString);
                dataCallback(obj);
            }];
        }
        if (self->_redirectResponse && self->_redirectRequest && self->_redirectDecisionCallback) {
            redirectCallback(self->_redirectResponse, self->_redirectRequest, self->_redirectDecisionCallback);
            self->_waitFinish = YES;
            JDCacheLog(@"获取HTML预加载请求重定向信息（已保存直接获取），response: %@, newRequest - %@",self->_redirectResponse, self->_redirectRequest);
        }
        if (self->_finish) {
            JDCacheLog(@"HTML预加载获取已存储的 finish，URl: %@", request.URL.absoluteString);
            successCallback();
            [self reset];
            return;
        }
        
        self.responseCallback = [responseCallback copy];
        self.dataCallback = [dataCallback copy];
        self.failCallback = [failCallback copy];
        self.successCallback = [successCallback copy];
        self.redirectCallback = [redirectCallback copy];
    });
}


- (void)preloadCallBackWithResponse:(NSURLResponse * _Nonnull)response originRequest:(NSURLRequest *)request{
    dispatch_queue_t queue = _preloadQueue;
    JDWeak(self)
    dispatch_async(queue, ^{
        JDStrong(self)
        if (!self) {
            return;
        }
        if (self.responseCallback) {
            JDCacheLog(@"HTML预加载直接返回 response, url: %@", request.URL.absoluteString);
            self.responseCallback(response);
            self->_waitFinish = YES;
            return;
        }
        JDCacheLog(@"HTML预加载set response, url: %@", request.URL.absoluteString);
        self->_response = response;
    });
    
}

- (void)preloadCallBackWithData:(NSData * _Nonnull)data originRequest:(NSURLRequest *)request{
    if (!data) {
        return;
    }
    dispatch_queue_t queue = _preloadQueue;
    JDWeak(self)
    dispatch_async(queue, ^{
        JDStrong(self)
        if (!self) {
            return;
        }
        if (self.dataCallback) {
            JDCacheLog(@"HTML预加载直接返回 data, length: %ld, url: %@", data.length ,request.URL.absoluteString);
            self.dataCallback(data);
            return;
        }
        JDCacheLog(@"HTML预加载set data, length: %ld,  url: %@", data.length ,request.URL.absoluteString);
        [self->_dataArray addObject:data];
    });
}

- (void)preloadCallBackFinshWithOriginRequest:(NSURLRequest *)request {
    dispatch_queue_t queue = _preloadQueue;
    JDWeak(self)
    dispatch_async(queue, ^{
        JDStrong(self)
        if (!self) {
            return;
        }
        if (self.successCallback) {
            JDCacheLog(@"HTML预加载直接返回 finish, url: %@", request.URL.absoluteString);
            self.successCallback();
            [self reset];
            return;
        }
        JDCacheLog(@"HTML预加载set finish, url: %@", request.URL.absoluteString);
        self->_finish = YES;
    });
}

- (void)preloadCallBackWithError:(NSError * _Nonnull)error originRequest:(NSURLRequest *)request{
    dispatch_queue_t queue = _preloadQueue;
    JDWeak(self)
    dispatch_async(queue, ^{
        JDStrong(self)
        if (!self) {
            return;
        }
        if (self.failCallback) {
            JDCacheLog(@"HTML预加载直接返回 error, url: %@", request.URL.absoluteString);
            self.failCallback([NSError errorWithDomain:NSCocoaErrorDomain
                                                  code:JDCacheErrorCodePreloadError
                                              userInfo:@{@"reason": @"html preload error"}]);

            [self reset];
            return;
        }
        JDCacheLog(@"HTML预加载set error, url: %@", request.URL.absoluteString);
        self->_error = error;
    });
}

- (void)preloadCallBackRedirectWithResponse:(NSURLResponse *)response
                                 newRequest:(NSURLRequest *)redirectRequest
                           redirectDecision:(JDNetRedirectDecisionCallback)redirectDecisionCallback {
    dispatch_queue_t queue = _preloadQueue;
    JDWeak(self)
    dispatch_async(queue, ^{
        JDStrong(self)
        if (!self) {
            return;
        }
        if (self.redirectCallback) {
            self.redirectCallback(response, redirectRequest, redirectDecisionCallback);
            self->_waitFinish = YES;
            JDCacheLog(@"HTML预加载发生重定向（询问过直接返回），response: %@，newRequest: %@", response, redirectRequest);
            return;
        }
        self->_redirectRequest = redirectRequest;
        self->_redirectResponse = response;
        self->_redirectDecisionCallback = [redirectDecisionCallback copy];
        JDCacheLog(@"HTML预加载发生重定向（未询问过先保存状态），response: %@，newRequest: %@", response, redirectRequest);
    });
}

@end

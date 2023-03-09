//
//  JDNetworkOperationQueue.m
//  JDBJDModule
//
//  Created by wangxiaorui19 on 2021/12/2.
//

#import "JDNetworkOperationQueue.h"
#import "JDNetworkManager.h"
#import "JDURLCache.h"
#import "JDUtils.h"
@interface JDNetworkAsyncOperation ()

@property (nonatomic, assign, getter=isExecuting) BOOL executing;
@property (nonatomic, assign, getter=isFinished) BOOL finished;
//@property (readonly, getter=isAsynchronous) BOOL asynchronous

@property (nonatomic, copy) NSURLRequest *URLRequest;
@property (nonatomic, copy) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSMutableData *data;

@property RequestTaskIdentifier currentRequestId;

@property (nonatomic, assign, readonly) BOOL canCache;

@end


@implementation JDNetworkAsyncOperation

@synthesize executing = _executing;
@synthesize finished = _finished;


- (instancetype)initWithRequest:(NSURLRequest *)request canCache:(BOOL)canCache
{
    self = [super init];
    if (self) {
        _URLRequest = request;
        _currentRequestId = -1;
        _canCache = canCache;
    }
    return self;
}

- (void)start {
    self.executing = YES;
    if (self.cancelled) {
        [self done];
        return;
    }
    
    NSMutableURLRequest *requestM = [self.URLRequest mutableCopy];
    if (self.canCache &&
        self.URLCacheHandler &&
        [self.URLCacheHandler respondsToSelector:@selector(URLCacheEnable)] &&
        [self.URLCacheHandler URLCacheEnable] &&
        [requestM.HTTPMethod isEqualToString:@"GET"]) {
            JDCachedURLResponse *cachedResponse = [[JDURLCache defaultCache] getCachedResponseWithURL:requestM.URL.absoluteString];
            if (cachedResponse && ![cachedResponse isExpired]) {
                self.responseCallback(cachedResponse.response);
                self.dataCallback(cachedResponse.data);
                self.successCallback();
                if ([self.URLCacheHandler respondsToSelector:@selector(updateCacheCapacityWithCost:)]) {
                    [self.URLCacheHandler updateCacheCapacityWithCost:cachedResponse.data.length];
                }
                [self done];
                return;
            }
            
            if (cachedResponse && [cachedResponse isExpired]) {
                if (cachedResponse.etag) {
                    [requestM setValue:cachedResponse.etag forHTTPHeaderField:@"If-None-Match"];
                }
                if (cachedResponse.lastModified) {
                    [requestM setValue:cachedResponse.lastModified forHTTPHeaderField:@"If-Modified-Since"];
                }
            }
    }
    self.URLRequest = [requestM copy];
    JDWeak(self)
    self.currentRequestId = [[JDNetworkManager shareManager]
                             startWithRequest:self.URLRequest
                             responseCallback:^(NSURLResponse * _Nonnull response) {
                                    JDStrong(self)
                                    if (!self) {
                                        return;
                                    }
                                    if (self.canCache && [response isKindOfClass:[NSHTTPURLResponse class]]) {
                                        self.response = (NSHTTPURLResponse *)response;
                                        if (self.response.statusCode == 304 &&
                                            [[JDURLCache defaultCache] getCachedResponseWithURL:self.URLRequest.URL.absoluteString]) {
                                            
                                        } else {
                                            self.responseCallback(response);
                                        }
                                    } else {
                                        self.responseCallback(response);
                                    }
                                    
                                }
                             progressCallBack:self.progressCallback 
                             dataCallback:^(NSData * _Nonnull data) {
                                    JDStrong(self)
                                    if (!self) {
                                        return;
                                    }
                                    self.dataCallback(data);
                                    if (self.data) {
                                        [self.data appendData:data];
                                    } else {
                                        self.data = [data mutableCopy];
                                    }
                                }
                             successCallback:^{
                                    JDStrong(self)
                                    if (!self) {
                                        return;
                                    }
                                    if (!self.canCache) {
                                        self.successCallback();
                                        return;
                                    }
        
                                    if (self.response.statusCode == 304 &&
                                        [[JDURLCache defaultCache] getCachedResponseWithURL:self.URLRequest.URL.absoluteString]) {
                                        JDCachedURLResponse *cachedResponse = [[JDURLCache defaultCache] updateCachedResponseWithURLResponse:self.response requestUrl:self.URLRequest.URL.absoluteString];
                                        self.responseCallback(cachedResponse.response);
                                        self.dataCallback(cachedResponse.data);
                                        self.successCallback();
                                        if (self.URLCacheHandler &&
                                            [self.URLCacheHandler respondsToSelector:@selector(updateCacheCapacityWithCost:)]) {
                                            [self.URLCacheHandler updateCacheCapacityWithCost:cachedResponse.data.length];
                                            }
                                        return;
                                    }
                                    if (self.URLCacheHandler &&
                                        [self.URLCacheHandler respondsToSelector:@selector(isOvercapacityWithCost:)] &&
                                        [self.URLCacheHandler isOvercapacityWithCost:self.data.length]) {
                                        self.successCallback();
                                        return;
                                    }
                                    [[JDURLCache defaultCache] cacheWithHTTPURLResponse:self.response data:self.data url:self.URLRequest.URL.absoluteString];
                                    if (self.URLCacheHandler &&
                                        [self.URLCacheHandler respondsToSelector:@selector(updateCacheCapacityWithCost:)]) {
                                        [self.URLCacheHandler updateCacheCapacityWithCost:self.data.length];
                                    }
                                    self.successCallback();
                                }
                             failCallback:^(NSError * _Nonnull error) {
                                    JDStrong(self)
                                    if (!self) {
                                        return;
                                    }
                                    self.failCallback(error);
                                }
                             redirectCallback:[self.redirectCallback copy]];
    [self done];
}

- (void)done {
    self.finished = YES;
    self.executing = NO;
}

- (void)setExecuting:(BOOL)executing{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isExecuting {
    return _executing;
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isFinished {
    return _finished;
}

- (BOOL)isAsynchronous{
    return YES;
}

- (void)cancel {
    [super cancel];
    if (!self.isCancelled) {
        [self done];
    } 
    if (self.currentRequestId < 0) {
        return;
    }
    [[JDNetworkManager shareManager] cancelWithRequestIdentifier:self.currentRequestId];
}

@end


@interface JDNetworkOperationQueue()
@property (nonatomic, strong) NSOperationQueue *requestOperationQueue;
@end

@implementation JDNetworkOperationQueue

+ (instancetype)defaultQueue {
    static JDNetworkOperationQueue *_defaultQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultQueue = [[JDNetworkOperationQueue alloc] init];
    });
    return _defaultQueue;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _requestOperationQueue = [NSOperationQueue new];
        _requestOperationQueue.maxConcurrentOperationCount = 6;
        _requestOperationQueue.name = @"com.jdcache.networkoperation";
    }
    return self;
}

- (void)addOperation:(JDNetworkAsyncOperation *)operation {
    [self.requestOperationQueue addOperation:operation];
}

@end

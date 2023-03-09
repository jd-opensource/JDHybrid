//
//  JDNetworkSession.m
//  JDBJDModule
//
//  Created by wangxiaorui19 on 2021/11/5.
//

#import "JDNetworkSession.h"
#import "JDNetworkOperationQueue.h"
#import "JDNetworkManager.h"
#import "JDSafeArray.h"
#import "JDUtils.h"
#import <os/lock.h>

NSTimeInterval const kJDPriorityNormalTimeoutInterval = 15;
NSTimeInterval const kJDPriorityVeryHighTimeoutInterval = 1;

#pragma mark - NetworkSession配置 (对相同的JDNetworkSession实例生效)
@implementation JDNetworkSessionConfiguration
- (instancetype)init
{
    self = [super init];
    if (self) {
        _cacheCountLimit = 0;
        _cacheCostLimit = 0;
        _retryLimit = 0;
        _networkTimeoutInterval = kJDPriorityNormalTimeoutInterval;
    }
    return self;
}
@end

#pragma mark - DataTask (建议一个请求对应一个该实例)

@interface JDNetworkDataTask ()<JDNetworkURLCacheHandle>
@property (nullable, readwrite, copy) NSURLRequest  *originalRequest;
@property (nonatomic, strong) JDNetworkAsyncOperation *operation;
@property (nonatomic, assign) BOOL isCancel;
@property (nonatomic, assign) BOOL canCache;
@property (nonatomic, assign) NSUInteger retryCount; // 已重试次数

@property (nonatomic, strong) JDNetworkSessionConfiguration *configuration;
@property (nonatomic, weak) JDNetworkSession *networkSession;

@property (nonatomic, copy) JDNetResponseCallback responseCallback;
@property (nonatomic, copy) JDNetDataCallback dataCallback;
@property (nonatomic, copy) JDNetSuccessCallback successCallback;
@property (nonatomic, copy) JDNetFailCallback failCallback;
@property (nonatomic, copy) JDNetRedirectCallback redirectCallback;
@property (nonatomic, copy) JDNetProgressCallBack progressCallBack;
@end

@implementation JDNetworkDataTask
- (instancetype)initWithRequest:(NSURLRequest *)request
                  configuration:(JDNetworkSessionConfiguration *)configuration {
    self = [super init];
    if (self) {
        _originalRequest = request;
        _configuration = configuration;
        _dataTaskPriority = JDNetworkDataTaskPriorityNormal;
        _retryLimit = configuration.retryLimit;
        _retryCount = 0;
        _isCancel = NO;
        _canCache = YES;
    }
    return self;
}

- (void)resume {
    NSMutableURLRequest *requestM = [self.originalRequest mutableCopy];
    requestM.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    if (self.retryCount > 0) {
        requestM.timeoutInterval = requestM.timeoutInterval * 2;
    } else {
        requestM.timeoutInterval = self.configuration.networkTimeoutInterval;
    }
    self.originalRequest = [requestM copy];
    
    JDNetworkAsyncOperation *operation = [[JDNetworkAsyncOperation alloc] initWithRequest:self.originalRequest canCache:self.canCache];
    operation.responseCallback = self.responseCallback;
    operation.dataCallback = self.dataCallback;
    operation.successCallback = self.successCallback;
    operation.progressCallback = self.progressCallBack;
    JDWeak(self)
    operation.failCallback = ^(NSError * _Nonnull error) {
        JDStrong(self)
        if (error.code != -999) {
        }
        if (!self) {
            return;
        }
        
        if (error &&
            error.code == -1001 &&
            [self.originalRequest.HTTPMethod isEqualToString:@"GET"] &&
            self.retryCount < self.retryLimit) {
            [self retry];
            return;
        }
        self.failCallback(error);
    };
    operation.redirectCallback = self.redirectCallback;
    operation.URLCacheHandler = self;
    switch (self.dataTaskPriority) {
        case JDNetworkDataTaskPriorityVeryHigh:
            operation.queuePriority = NSOperationQueuePriorityVeryHigh;
            break;
        case JDNetworkDataTaskPriorityHigh:
            operation.queuePriority = NSOperationQueuePriorityHigh;
            break;
        default:
            operation.queuePriority = NSOperationQueuePriorityNormal;
            break;
    }
    self.operation = operation;
    [[JDNetworkOperationQueue defaultQueue] addOperation:operation];
}

- (void)cancel {
    if (self.isCancel) {
        return;
    }
    [self.operation cancel];
    self.isCancel = YES;
    [self.networkSession cancelTask:self];
}

- (void)retry {
    self.retryCount ++;
    [self cancel];
    
    if (!self.networkSession) {
        return;
    }
    JDNetworkDataTask *retryDataTask = [self.networkSession
                                        dataTaskWithRequest:self.originalRequest
                                        responseCallback:self.responseCallback
                                        dataCallback:self.dataCallback
                                        successCallback:self.successCallback
                                        failCallback:self.failCallback
                                        redirectCallback:self.redirectCallback];
    if (!retryDataTask) {
        return;
    }
    retryDataTask.retryLimit = self.retryLimit;
    retryDataTask.retryCount = self.retryCount;
    retryDataTask.dataTaskPriority = JDNetworkDataTaskPriorityHigh;
    [retryDataTask resume];
}

#pragma mark - JDNetworkURLCacheHandle

- (BOOL)URLCacheEnable {
    return YES;
}

- (BOOL)isOvercapacityWithCost:(NSUInteger)cost {
    return [self.networkSession isOvercapacityWithCost:cost];
}

- (void)updateCacheCapacityWithCost:(NSUInteger)cost {
    [self.networkSession updateCacheCapacityWithCost:cost];
}

@end

#pragma mark - NetworkSession (建议一个webview实例对应一个该实例)
@interface JDNetworkSession ()
@property (nonatomic, strong) JDNetworkSessionConfiguration *configuration;
@property (nonatomic, strong) JDSafeArray<JDNetworkDataTask *> *tasksArrayM;

@property (nonatomic, assign) NSUInteger currentCacheCount; // 当前缓存数量
@property (nonatomic, assign) NSUInteger currentCacheCost; // 当前缓存容量

@end

@implementation JDNetworkSession{
    os_unfair_lock _tasksArraylock;
}

+ (instancetype)sessionWithConfiguation:(JDNetworkSessionConfiguration *)configuration  {
    return [[self alloc] initWithConfiguation:configuration];
}

- (instancetype)initWithConfiguation:(JDNetworkSessionConfiguration *)configuration{
    self = [super init];
    if (self) {
        _tasksArraylock = OS_UNFAIR_LOCK_INIT;
        _configuration = configuration;
        _tasksArrayM = [JDSafeArray strongObjects];
        _currentCacheCost = 0;
        _currentCacheCount = 0;
    }
    return self;
}

- (nullable JDNetworkDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                                   responseCallback:(JDNetResponseCallback)responseCallback
                                       dataCallback:(JDNetDataCallback)dataCallback
                                    successCallback:(JDNetSuccessCallback)successCallback
                                       failCallback:(JDNetFailCallback)failCallback
                                   redirectCallback:(JDNetRedirectCallback)redirectCallback {
    
    return [self dataTaskWithRequest:request responseCallback:responseCallback progressCallBack:nil dataCallback:dataCallback successCallback:successCallback failCallback:failCallback redirectCallback:redirectCallback];
    
}

- (JDNetworkDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                          responseCallback:(JDNetResponseCallback)responseCallback
                          progressCallBack:(JDNetProgressCallBack)progressCallBack
                              dataCallback:(JDNetDataCallback)dataCallback
                           successCallback:(JDNetSuccessCallback)successCallback
                              failCallback:(JDNetFailCallback)failCallback
                          redirectCallback:(JDNetRedirectCallback)redirectCallback
{
    JDNetworkDataTask *dataTask = [[JDNetworkDataTask alloc] initWithRequest:request
                                                               configuration:self.configuration];
    dataTask.responseCallback = responseCallback;
    dataTask.dataCallback = dataCallback;
    JDWeak(dataTask)
    JDWeak(self)
    dataTask.successCallback = ^{
        JDStrong(dataTask)
        JDStrong(self)
        if (!self || !dataTask) {
            return;
        }
        if (successCallback) {
            successCallback();
        }
        [self cancelTask:dataTask];
    };
    dataTask.failCallback = ^(NSError * _Nonnull error) {
        JDStrong(dataTask)
        JDStrong(self)
        if (!self || !dataTask) {
            return;
        }
        if (failCallback) {
            failCallback(error);
        }
        [self cancelTask:dataTask];
    };
    dataTask.redirectCallback = redirectCallback;
    dataTask.progressCallBack = progressCallBack;
    dataTask.networkSession = self;
    
    BOOL notGet = ![request.HTTPMethod.lowercaseString isEqualToString:@"get"];
    NSString *mainUrl = request.mainDocumentURL.absoluteString;
    NSString *requestUrl = request.URL.absoluteString;
    BOOL isMainUrl = [JDUtils isValidStr:mainUrl] && [JDUtils isEqualURLA:requestUrl withURLB:mainUrl];
    
    if (notGet || isMainUrl) { // 不是get请求或者是mainURL，明显不缓存
        dataTask.canCache = NO;
    } else {
        dataTask.canCache = YES;
    }
    
    os_unfair_lock_lock(&_tasksArraylock);
    [_tasksArrayM addObject:dataTask];
    os_unfair_lock_unlock(&_tasksArraylock);
    
    [_tasksArrayM addObject:dataTask];
    return dataTask;
}

- (BOOL)isOvercapacityWithCost:(NSUInteger)cost {
    if (self.configuration.cacheCountLimit != 0 &&
        self.currentCacheCount >= self.configuration.cacheCountLimit) {
        return YES;
    }
    if (self.configuration.cacheCostLimit != 0 &&
        self.currentCacheCost + cost > self.configuration.cacheCostLimit) {
        return YES;
    }
    return NO;
}

- (void)updateCacheCapacityWithCost:(NSUInteger)cost {
    if (self.configuration.cacheCountLimit != 0) {
        self.currentCacheCount ++;
    }
    if (self.configuration.cacheCostLimit != 0) {
        self.currentCacheCost += cost;
    }
}

- (void)cancelTask:(JDNetworkDataTask *)task {
    [task cancel];
    os_unfair_lock_lock(&_tasksArraylock);
    [self.tasksArrayM removeObject:task];
    os_unfair_lock_unlock(&_tasksArraylock);
    
}

- (void)cancelAllTasks {
    if (self.tasksArrayM.count == 0) {
        return;
    }
    NSArray<JDNetworkDataTask *> *dataTaskArr = [NSArray array];
    os_unfair_lock_lock(&_tasksArraylock);
    dataTaskArr = [self.tasksArrayM copy];
    os_unfair_lock_unlock(&_tasksArraylock);
    
    for (JDNetworkDataTask *task in dataTaskArr) {
        [task cancel];
        os_unfair_lock_lock(&_tasksArraylock);
        [self.tasksArrayM removeObject:task];
        os_unfair_lock_unlock(&_tasksArraylock);
    }
}


@end


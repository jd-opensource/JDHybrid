//
//  JDNetworkResourceMatcher.m
//  JDHybrid
//
//  Created by wangxiaorui19 on 2022/12/5.
//

#import "JDNetworkResourceMatcher.h"
#import "JDNetworkSession.h"
#import "JDUtils.h"

@interface JDNetworkResourceMatcher ()
@property (nonatomic, strong) JDNetworkSession *networkSession;
@end

@implementation JDNetworkResourceMatcher

- (BOOL)canHandleWithRequest:(nonnull NSURLRequest *)request {
    return YES;
}

- (void)startWithRequest:(nonnull NSURLRequest *)request
        responseCallback:(nonnull JDNetResponseCallback)responseCallback
            dataCallback:(nonnull JDNetDataCallback)dataCallback
            failCallback:(nonnull JDNetFailCallback)failCallback
         successCallback:(nonnull JDNetSuccessCallback)successCallback
        redirectCallback:(nonnull JDNetRedirectCallback)redirectCallback{
    JDNetworkDataTask *dataTask = [self.networkSession dataTaskWithRequest:request
                                                          responseCallback:responseCallback
                                                              dataCallback:dataCallback
                                                           successCallback:^{
        successCallback();
        JDCacheLog(@"从网络请求获取数据，url: %@", request.URL.absoluteString);
    }
                                                              failCallback:failCallback
                                                          redirectCallback:redirectCallback];
    [dataTask resume];
}


- (void)dealloc {
    [_networkSession cancelAllTasks];
}

#pragma mark - lazy

- (JDNetworkSession *)networkSession {
    if (!_networkSession) {
        _networkSession = [JDNetworkSession sessionWithConfiguation:[JDNetworkSessionConfiguration new]];
    }
    return _networkSession;
}

@end

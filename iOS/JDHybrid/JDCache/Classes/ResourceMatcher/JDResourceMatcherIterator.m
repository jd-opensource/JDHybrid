//
//  JDCacheIterator.m
//  JDHybrid
//
//  Created by wangxiaorui19 on 2022/12/5.
//

#import "JDResourceMatcherIterator.h"
#import "JDResourceMatcherManager.h"

@implementation JDResourceMatcherIterator

- (NSArray<id<JDResourceMatcherImplProtocol>> *)resMatchers {
    NSArray<id<JDResourceMatcherImplProtocol>> *resMatcherArr = @[];
    if ([self.iteratorDataSource respondsToSelector:@selector(liveResMatchers)]) {
        resMatcherArr = [self.iteratorDataSource liveResMatchers];
     }
   return resMatcherArr;
    
}

- (nullable id<JDResourceMatcherImplProtocol>)targetMatcherWithUrlSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    __block id<JDResourceMatcherImplProtocol> targetMatcher = nil;
    NSURLRequest *request = urlSchemeTask.request;
    [[self resMatchers] enumerateObjectsUsingBlock:^(id<JDResourceMatcherImplProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!obj || ![obj respondsToSelector:@selector(canHandleWithRequest:)]) {
            return;
        }
        if ([obj canHandleWithRequest:request]) {
            targetMatcher = obj;
            *stop = YES;
            return;
        }
    }];
    return targetMatcher;
}

- (void)startWithUrlSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    id<JDResourceMatcherImplProtocol> matcher = [self targetMatcherWithUrlSchemeTask:urlSchemeTask];
    if (!matcher || ![matcher respondsToSelector:@selector(startWithRequest: responseCallback: dataCallback: failCallback: successCallback: redirectCallback:)]) {
        [self.iteratorDelagate didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil] urlSchemeTask:urlSchemeTask];
        [self.iteratorDelagate didFinishWithUrlSchemeTask:urlSchemeTask];
        return;
    }
    [matcher startWithRequest:urlSchemeTask.request responseCallback:^(NSURLResponse * _Nonnull response) {
        [self.iteratorDelagate didReceiveResponse:response urlSchemeTask:urlSchemeTask];
    } dataCallback:^(NSData * _Nonnull data) {
        [self.iteratorDelagate didReceiveData:data urlSchemeTask:urlSchemeTask];
    } failCallback:^(NSError * _Nonnull error) {
        switch (error.code) {
            case JDCacheErrorCodePreloadUnstart:
            case JDCacheErrorCodeTimeout:
            case JDCacheErrorCodeNotFind:
            case JDCacheErrorCodePreloadError:
            {
                // 网络请求
                NSString *reason = @"";
                switch (error.code) {
                    case JDCacheErrorCodePreloadUnstart:
                        reason = @"预加载未开始";
                        break;
                    case JDCacheErrorCodeTimeout:
                        reason = @"预加载超时";
                        break;
                    case JDCacheErrorCodeNotFind:
                        reason = @"未找到资源";
                        break;
                    case JDCacheErrorCodePreloadError:
                        reason = @"html预加载失败";
                        break;
                }
                JDCacheLog(@"（重试）从网络请求获取数据，重试原因：%@, url: %@", reason, urlSchemeTask.request.URL.absoluteString);
                [self networkRequestWithUrlSchemeTask:urlSchemeTask];
            }
                break;
            default:
            {
                [self.iteratorDelagate didFailWithError:error urlSchemeTask:urlSchemeTask];
            }
                break;
        }
    } successCallback:^{
        [self.iteratorDelagate didFinishWithUrlSchemeTask:urlSchemeTask];
    } redirectCallback:^(NSURLResponse * _Nonnull response,
                         NSURLRequest * _Nonnull redirectRequest,
                         JDNetRedirectDecisionCallback  _Nonnull redirectDecisionCallback) {
        [self.iteratorDelagate didRedirectWithResponse:response
                                            newRequest:redirectRequest
                                      redirectDecision:redirectDecisionCallback
                                         urlSchemeTask:urlSchemeTask];
    }];
}

- (void)networkRequestWithUrlSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    id<JDResourceMatcherImplProtocol> networkMatcher = [[self resMatchers] lastObject];
    if (!networkMatcher || ![networkMatcher respondsToSelector:@selector(startWithRequest: responseCallback: dataCallback: failCallback: successCallback: redirectCallback:)]) {
        [self.iteratorDelagate didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil] urlSchemeTask:urlSchemeTask];
        [self.iteratorDelagate didFinishWithUrlSchemeTask:urlSchemeTask];
    }
    [networkMatcher startWithRequest:urlSchemeTask.request responseCallback:^(NSURLResponse * _Nonnull response) {
        [self.iteratorDelagate didReceiveResponse:response urlSchemeTask:urlSchemeTask];
    } dataCallback:^(NSData * _Nonnull data) {
        [self.iteratorDelagate didReceiveData:data urlSchemeTask:urlSchemeTask];
    } failCallback:^(NSError * _Nonnull error) {
        [self.iteratorDelagate didFailWithError:error urlSchemeTask:urlSchemeTask];
    } successCallback:^{
        [self.iteratorDelagate didFinishWithUrlSchemeTask:urlSchemeTask];
    } redirectCallback:^(NSURLResponse * _Nonnull response,
                         NSURLRequest * _Nonnull redirectRequest,
                         JDNetRedirectDecisionCallback  _Nonnull redirectDecisionCallback) {
        [self.iteratorDelagate didRedirectWithResponse:response
                                            newRequest:redirectRequest
                                      redirectDecision:redirectDecisionCallback
                                         urlSchemeTask:urlSchemeTask];
    }];
}

@end

//
//  JDCacheIterator.h
//  JDHybrid
//
//  Created by wangxiaorui19 on 2022/12/5.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "JDResourceMatcherManager.h"
#import "JDUtils.h"

NS_ASSUME_NONNULL_BEGIN
API_AVAILABLE(ios(LimitVersion))

@protocol JDResourceMatcherIteratorProtocol <NSObject>

- (void)didReceiveResponse:(NSURLResponse *)response urlSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask;

- (void)didReceiveData:(NSData *)data urlSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask;

- (void)didFinishWithUrlSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask;

- (void)didFailWithError:(NSError *)error urlSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask;

- (void)didRedirectWithResponse:(NSURLResponse *)response
                     newRequest:(NSURLRequest *)redirectRequest
               redirectDecision:(JDNetRedirectDecisionCallback)redirectDecisionCallback
                  urlSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask;

@end

@protocol JDResourceMatcherIteratorDataSource <NSObject>

- (NSArray<id<JDResourceMatcherImplProtocol>> *)liveResMatchers;

@end

API_AVAILABLE(ios(LimitVersion))
@interface JDResourceMatcherIterator : NSObject

@property (nonatomic, weak) id<JDResourceMatcherIteratorProtocol> iteratorDelagate;

@property (nonatomic, weak) id<JDResourceMatcherIteratorDataSource> iteratorDataSource;

- (void)startWithUrlSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask;

@end

NS_ASSUME_NONNULL_END

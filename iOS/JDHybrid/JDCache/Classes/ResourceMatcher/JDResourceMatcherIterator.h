//
//  JDCacheIterator.h
//  JDHybrid
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

//
//  JDNetworkResourceMatcher.m
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

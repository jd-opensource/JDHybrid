//
//  JDNetworkManager.h
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
#import "JDCacheProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class JDNetworkAsyncOperation;

@interface JDNetworkCallBackWorker : NSObject

@end

typedef NSInteger RequestTaskIdentifier;


@interface JDNetworkManager : NSObject

+ (void)start; // 网络框架预热

+ (instancetype)shareManager;

- (RequestTaskIdentifier)startWithRequest:(NSURLRequest *)request
                         responseCallback:(JDNetResponseCallback)responseCallback
                             dataCallback:(JDNetDataCallback)dataCallback
                          successCallback:(JDNetSuccessCallback)successCallback
                             failCallback:(JDNetFailCallback)failCallback
                         redirectCallback:(JDNetRedirectCallback)redirectCallback ;

- (RequestTaskIdentifier)startWithRequest:(NSURLRequest *)request
                         responseCallback:(JDNetResponseCallback)responseCallback
                         progressCallBack:(nullable JDNetProgressCallBack)progressCallBack
                             dataCallback:(JDNetDataCallback)dataCallback
                          successCallback:(JDNetSuccessCallback)successCallback
                             failCallback:(JDNetFailCallback)failCallback
                         redirectCallback:(JDNetRedirectCallback)redirectCallback ;

- (void)cancelWithRequestIdentifier:(RequestTaskIdentifier)requestTaskIdentifier ;

@end

NS_ASSUME_NONNULL_END

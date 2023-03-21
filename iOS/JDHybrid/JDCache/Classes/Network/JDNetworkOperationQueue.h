//
//  JDNetworkOperationQueue.h
//  JDBJDModule
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
#import "JDNetworkSession.h"

NS_ASSUME_NONNULL_BEGIN

@protocol JDNetworkURLCacheHandle <NSObject>

/// 是否启用缓存
- (BOOL)URLCacheEnable;

/// 是否超过缓存限制
/// @param cost 本地待缓存大小
- (BOOL)isOvercapacityWithCost:(NSUInteger)cost ;

/// 更新当前缓存使用情况
/// @param cost 本次缓存大小
- (void)updateCacheCapacityWithCost:(NSUInteger)cost ;

@end


@interface JDNetworkAsyncOperation : NSOperation

@property (nonatomic, copy) JDNetResponseCallback responseCallback;
@property (nonatomic, copy) JDNetDataCallback dataCallback;
@property (nonatomic, copy) JDNetSuccessCallback successCallback;
@property (nonatomic, copy) JDNetFailCallback failCallback;
@property (nonatomic, copy) JDNetRedirectCallback redirectCallback;
@property (nonatomic, copy) JDNetProgressCallBack progressCallback;
@property (nonatomic, weak) id<JDNetworkURLCacheHandle> URLCacheHandler;

- (instancetype)initWithRequest:(NSURLRequest *)request canCache:(BOOL)canCache;

@end


@interface JDNetworkOperationQueue : NSObject

+ (instancetype)defaultQueue ;

- (void)addOperation:(JDNetworkAsyncOperation *)operation ;

@end

NS_ASSUME_NONNULL_END

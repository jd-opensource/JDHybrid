//
//  JDNetworkSession.h
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

NS_ASSUME_NONNULL_BEGIN

@interface JDNetworkSessionConfiguration: NSObject

@property (nonatomic, assign) NSUInteger cacheCountLimit; // 缓存数量限制

@property (nonatomic, assign) NSUInteger cacheCostLimit; // 缓存容量限制

@property (nonatomic, assign) NSUInteger retryLimit; // 最大重试次数

@property (nonatomic, assign) NSTimeInterval networkTimeoutInterval; // 超时时间

@end

typedef NS_ENUM(NSInteger, JDNetworkDataTaskPriority) {
    JDNetworkDataTaskPriorityNormal = 1,
    JDNetworkDataTaskPriorityHigh,
    JDNetworkDataTaskPriorityVeryHigh,
};

@interface JDNetworkDataTask : NSObject

@property (nullable, readonly, copy) NSURLRequest  *originalRequest;

@property (nonatomic) JDNetworkDataTaskPriority dataTaskPriority; // 任务优先级

@property (nonatomic, assign) NSUInteger retryLimit; // 最大重试次数

- (void)resume ;

- (void)cancel ;

@end

NS_CLASS_AVAILABLE_IOS(10_0)
@interface JDNetworkSession : NSObject

@property (nonatomic, copy, nullable) NSString *mainUrl; // 页面主URL

+ (instancetype)sessionWithConfiguation:(JDNetworkSessionConfiguration *)configuration ;

- (nullable JDNetworkDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                                   responseCallback:(JDNetResponseCallback)responseCallback
                                       dataCallback:(JDNetDataCallback)dataCallback
                                    successCallback:(JDNetSuccessCallback)successCallback
                                       failCallback:(JDNetFailCallback)failCallback
                                   redirectCallback:(JDNetRedirectCallback)redirectCallback ;
- (nullable JDNetworkDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                                   responseCallback:(nullable JDNetResponseCallback)responseCallback
                                   progressCallBack:(nullable JDNetProgressCallBack)progressCallBack
                                       dataCallback:(JDNetDataCallback)dataCallback
                                    successCallback:(JDNetSuccessCallback)successCallback
                                       failCallback:(JDNetFailCallback)failCallback
                                   redirectCallback:(JDNetRedirectCallback)redirectCallback ;

/// 是否超过缓存限制
/// @param cost 本地待缓存大小
- (BOOL)isOvercapacityWithCost:(NSUInteger)cost ;

/// 更新当前缓存使用情况
/// @param cost 本次缓存大小
- (void)updateCacheCapacityWithCost:(NSUInteger)cost ;

/// 取消任务
- (void)cancelTask:(JDNetworkDataTask *)task;

/// 取消所有任务
- (void)cancelAllTasks ;

@end

NS_ASSUME_NONNULL_END


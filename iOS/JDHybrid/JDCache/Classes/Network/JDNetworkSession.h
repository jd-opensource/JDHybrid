//
//  JDNetworkSession.h
//  JDBJDModule
//
//  Created by wangxiaorui19 on 2021/11/5.
//

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


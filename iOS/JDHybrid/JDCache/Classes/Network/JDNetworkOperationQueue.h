//
//  JDNetworkOperationQueue.h
//  JDBJDModule
//
//  Created by wangxiaorui19 on 2021/12/2.
//

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

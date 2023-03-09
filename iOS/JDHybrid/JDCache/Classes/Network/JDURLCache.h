//
//  JDHybridURLCache.h
//  JDBHybridModule
//
//  Created by wangxiaorui19 on 2021/11/16.
//

#import <Foundation/Foundation.h>
#import "JDCachedURLResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface JDURLCache : NSObject

+ (instancetype)defaultCache;

- (instancetype)initWithCacheName:(NSString *)cacheName;

- (void)cacheWithHTTPURLResponse:(NSHTTPURLResponse *)response
                            data:(NSData *)data
                             url:(NSString *)url ;

- (nullable JDCachedURLResponse *)getCachedResponseWithURL:(NSString *)url ;

- (nullable JDCachedURLResponse *)updateCachedResponseWithURLResponse:(NSHTTPURLResponse *)newResponse
                                                           requestUrl:(NSString *)url;

- (void)clear;

@end

NS_ASSUME_NONNULL_END

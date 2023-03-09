//
//  JDHybridURLCache.m
//  JDBHybridModule
//
//  Created by wangxiaorui19 on 2021/11/16.
//

#import "JDURLCache.h"
#import <objc/message.h>
#import "JDCache.h"

@interface JDURLCache ()
@property (nonatomic, weak) id<JDURLCacheDelegate> URLCache;
@end

@implementation JDURLCache

+ (instancetype)defaultCache {
    static JDURLCache *_defaultCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultCache = [[JDURLCache alloc] initWithCacheName:@"hybridURLCache"];
    });
    return _defaultCache;
}

- (instancetype)initWithCacheName:(NSString *)cacheName
{
    self = [super init];
    if (self) {
        _URLCache = [JDCache shareInstance].netCache;
    }
    return self;
}

- (void)cacheWithHTTPURLResponse:(NSHTTPURLResponse *)response
                            data:(NSData *)data
                             url:(NSString *)url {
    JDCachedURLResponse *cacheResponse = [[JDCachedURLResponse alloc] initWithResponse:response data:data];
    if (!cacheResponse.canCache) {
        return;
    }
    [self.URLCache setObject:cacheResponse forKey:url];
}

- (nullable JDCachedURLResponse *)getCachedResponseWithURL:(NSString *)url {
    JDCachedURLResponse *cacheResponse = (JDCachedURLResponse*)[self.URLCache objectForKey:url];
    if (!cacheResponse || ![cacheResponse isKindOfClass:[JDCachedURLResponse class]]) {
        return nil;
    }
    if ([cacheResponse isExpired]) {
        if (!cacheResponse.etag && !cacheResponse.lastModified) {
            [self.URLCache removeObjectForKey:url];
            return nil;
        }
    }
    return cacheResponse;
}

- (nullable JDCachedURLResponse *)updateCachedResponseWithURLResponse:(NSHTTPURLResponse *)newResponse
                                                           requestUrl:(NSString *)url{
    JDCachedURLResponse *cacheResponse = (JDCachedURLResponse*)[self.URLCache objectForKey:url];
    if (![cacheResponse isKindOfClass:[JDCachedURLResponse class]]) {
        return nil;
    }
    if (!cacheResponse || ![cacheResponse isKindOfClass:[JDCachedURLResponse class]]) {
        return nil;
    }
    if (![cacheResponse isExpired]) {
        return cacheResponse;
    }
    JDCachedURLResponse *toSaveCacheResponse = [cacheResponse copy];
    [toSaveCacheResponse updateWithResponse:newResponse.allHeaderFields];
    if (toSaveCacheResponse.canCache) {
        [self.URLCache setObject:toSaveCacheResponse forKey:url];
    } else {
        [self.URLCache removeObjectForKey:url];
    }
    return toSaveCacheResponse;
}

- (void)clear {
    [self.URLCache removeAllObjects];
}


@end

//
//  JDCachedURLResponse.h
//  JDBHybridModule
//
//  Created by wangxiaorui19 on 2021/11/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JDCachedURLResponse : NSObject<NSCopying, NSCoding>

@property (readonly, copy) NSHTTPURLResponse *response;

@property (readonly, copy) NSData *data;

@property (readonly, assign) unsigned long long timestamp;

@property (readonly, assign) unsigned long long maxAge;

@property (readonly, copy) NSString *etag;

@property (readonly, copy) NSString *lastModified;


- (instancetype)initWithResponse:(NSHTTPURLResponse *)response
                            data:(NSData *)data;

- (void)updateWithResponse:(NSDictionary *)newHeaderFields ;

- (BOOL)canCache ;

- (BOOL)isExpired ;

@end

NS_ASSUME_NONNULL_END

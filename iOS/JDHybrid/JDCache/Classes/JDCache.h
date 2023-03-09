//
//  JDCache.h
//  JDHybrid
//
//  Created by wangxiaorui19 on 2022/12/12.
//

#import <Foundation/Foundation.h>
#import "JDCacheProtocol.h"


NS_ASSUME_NONNULL_BEGIN

@interface JDCache : NSObject

+ (JDCache *)shareInstance;

@property (nonatomic, strong) id <JDURLCacheDelegate> netCache;

@property (nonatomic, assign) BOOL LogEnabled;

@end

NS_ASSUME_NONNULL_END

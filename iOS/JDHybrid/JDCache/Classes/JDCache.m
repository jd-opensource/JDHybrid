//
//  JDCache.m
//  JDHybrid
//
//  Created by wangxiaorui19 on 2022/12/12.
//

#import "JDCache.h"
#import "JDUtils.h"

@implementation JDCache

+ (JDCache *)shareInstance{
    static JDCache *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [JDCache new];
    });
    return cache;
}

- (void)setLogEnabled:(BOOL)logEnabled {
    [JDUtils setLogEnable:logEnabled];
}

@end

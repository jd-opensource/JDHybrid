//
//  XHCache.m
//  JDHybrid_Example
//
//  Created by maxiaoliang8 on 2022/6/6.
//  Copyright © 2022 maxiaoliang8. All rights reserved.
//

#import "XHCache.h"
#import <YYCache/YYCache.h>

@interface XHCache ()

@property (nonatomic, strong) YYCache * cache;

@end

@implementation XHCache

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        _cache = [YYCache cacheWithName:name];
    }
    return self;
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key{
    [_cache setObject:object forKey:key];
}

- (id <NSCoding>)objectForKey:(NSString *)key{
    return [_cache objectForKey:key];
}

- (void)removeObjectForKey:(NSString *)key{
    [_cache removeObjectForKey:key];
}

- (void)removeAllObjects{
    [_cache removeAllObjects];
}
@end

//
//  JDSafeDictionary.m
//  JDache
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

#import "JDSafeDictionary.h"
#import <pthread.h>

#define JDSafeDictionaryLock(v,...)\
pthread_mutex_lock(&_lock);\
__VA_ARGS__;\
pthread_mutex_unlock(&_lock);\
return v;


@implementation JDSafeDictionary{
    pthread_mutex_t _lock;
    pthread_mutexattr_t _attr;
    NSMapTable * _dicM;
}

+ (instancetype)weakObjects{
    return [[self alloc] initWithWeak:YES];
}

+ (instancetype)strongObjects{
    return [[self alloc] initWithWeak:NO];
}

- (instancetype)initWithWeak:(BOOL)isWeak{
    if (self = [super init]) {
        if (isWeak) {
            _dicM = [NSMapTable strongToWeakObjectsMapTable];
        }else{
            _dicM = [NSMapTable strongToStrongObjectsMapTable];
        }
        pthread_mutexattr_init(&_attr);
        pthread_mutexattr_settype(&_attr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&_lock, &_attr);
    }
    return self;
}

- (instancetype)init
{
    return [JDSafeDictionary strongObjects];
}

- (void)removeObjectForKey:(id)aKey{
    if (aKey!=nil) {
        JDSafeDictionaryLock(, [_dicM removeObjectForKey:aKey])
    }
}
- (void)setObject:(id)anObject forKey:(id)aKey{
    if (anObject == nil) return;
    JDSafeDictionaryLock(,[_dicM setObject:anObject forKey:aKey])
}
- (void)removeAllObjects{
    JDSafeDictionaryLock(,[_dicM removeAllObjects])
}
- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary{
    if (![otherDictionary isKindOfClass:[NSDictionary class]]) return;
    JDSafeDictionaryLock(,[otherDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [_dicM setObject:obj forKey:key];
    }])
}
- (NSDictionary *)dictionary{
    id obj;
    JDSafeDictionaryLock(obj,obj = _dicM.dictionaryRepresentation);
}

- (NSArray *)allKeys{
    id obj;
    JDSafeDictionaryLock(obj,obj = [_dicM.dictionaryRepresentation allKeys]);
}

- (NSArray *)allValues{
    id obj;
    JDSafeDictionaryLock(obj,obj = [_dicM.dictionaryRepresentation allValues]);
}

- (NSInteger)count{
    NSInteger count;
    JDSafeDictionaryLock(count,count = [_dicM.dictionaryRepresentation count]);
}

- (NSArray *)allKeysForObject:(id)anObject{
    id obj;
    JDSafeDictionaryLock(obj,obj = [_dicM.dictionaryRepresentation allKeysForObject:anObject])
}

- (id)objectForKey:(id)aKey{
    id obj;
    JDSafeDictionaryLock(obj,obj = [_dicM objectForKey:aKey])
}

- (nullable id)objectForKeyedSubscript:(id)key{
    return [self objectForKey:key];
}
- (void)setObject:(nullable id)obj forKeyedSubscript:(id)key{
    [self setObject:obj forKey:key];
}
- (void)enumerateKeysAndObjectsUsingBlock:(void (NS_NOESCAPE ^)(id key, id obj, BOOL *stop))block{
    [self enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:block];
}
- (void)enumerateKeysAndObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (NS_NOESCAPE ^)(id key, id obj, BOOL *stop))block{
    JDSafeDictionaryLock(, [_dicM.dictionaryRepresentation enumerateKeysAndObjectsWithOptions:opts usingBlock:block])
}
- (id)copyWithZone:(NSZone *)zone{
    return self.dictionary;
}
- (void)dealloc
{
    pthread_mutexattr_destroy(&_attr);
    pthread_mutex_destroy(&_lock);
}
@end
#undef JDSafeDictionaryLock

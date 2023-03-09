//
//  JDSafeDictionary.h
//  JDache
//
//  Created by maxiaoliang8 on 2022/5/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JDSafeDictionary <KeyType,ObjectType> : NSObject<NSCopying>

+ (instancetype)weakObjects;

+ (instancetype)strongObjects;

@property (nonatomic, assign, readonly) NSInteger count;

@property (nonatomic, copy, readonly) NSDictionary <KeyType,ObjectType> *dictionary;
- (void)removeObjectForKey:(KeyType)aKey;
- (void)setObject:(ObjectType)anObject forKey:(KeyType <NSCopying>)aKey;
- (void)removeAllObjects;
- (void)addEntriesFromDictionary:(NSDictionary<KeyType, ObjectType> *)otherDictionary;
@property (readonly, copy, readonly) NSArray<KeyType> *allKeys;
- (NSArray<KeyType> *)allKeysForObject:(ObjectType)anObject;
@property (readonly, copy, readonly) NSArray<ObjectType> *allValues;
- (nullable ObjectType)objectForKey:(KeyType)aKey;
- (nullable ObjectType)objectForKeyedSubscript:(KeyType)key;
- (void)setObject:(nullable ObjectType)obj forKeyedSubscript:(KeyType <NSCopying>)key;
- (void)enumerateKeysAndObjectsUsingBlock:(void (NS_NOESCAPE ^)(KeyType key, ObjectType obj, BOOL *stop))block;
- (void)enumerateKeysAndObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (NS_NOESCAPE ^)(KeyType key, ObjectType obj, BOOL *stop))block;
@end

NS_ASSUME_NONNULL_END

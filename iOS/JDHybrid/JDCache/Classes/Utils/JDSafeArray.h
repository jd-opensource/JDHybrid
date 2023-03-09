//
//  JDSafeArray.h
//  JDache
//
//  Created by maxiaoliang8 on 2022/5/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JDSafeArray <ObjectType>: NSObject<NSCopying>

+ (instancetype)weakObjects;

+ (instancetype)strongObjects;

@property (nonatomic, copy, readonly) NSArray <ObjectType> *values;

- (instancetype)init;

@property (nonatomic, readonly, assign) NSUInteger count;

- (BOOL)containsObject:(ObjectType)anObject;

- (NSUInteger)indexOfObject:(ObjectType)anObject;

- (ObjectType)objectAtIndexedSubscript:(NSUInteger)idx;

- (nullable ObjectType)objectAtIndex:(NSUInteger)index;

- (void)addObjectsFromArray:(NSArray<ObjectType> *)otherArray;

- (void)removeAllObjects;

- (void)addObject:(ObjectType)anObject;

- (void)insertObject:(ObjectType)anObject atIndex:(NSUInteger)index;

- (void)removeLastObject;

- (void)removeObjectAtIndex:(NSUInteger)index;

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(ObjectType)anObject;

- (void)removeObject:(ObjectType)anObject;

- (void)enumerateObjectsUsingBlock:(void (NS_NOESCAPE ^)(ObjectType obj, NSUInteger idx, BOOL *stop))block;

- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (NS_NOESCAPE ^)(ObjectType obj, NSUInteger idx, BOOL *stop))block;
@end

NS_ASSUME_NONNULL_END

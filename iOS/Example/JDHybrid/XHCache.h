//
//  XHCache.h
//  JDHybrid_Example
//
//  Created by maxiaoliang8 on 2022/6/6.
//  Copyright © 2022 maxiaoliang8. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JDHybrid/JDCacheProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface XHCache : NSObject<JDURLCacheDelegate>

- (instancetype)initWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END

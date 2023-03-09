//
//  JDOfflineResSchemeHandler.h
//  JDHybrid_Example
//
//  Created by wangxiaorui19 on 2022/12/8.
//  Copyright © 2022 maxiaoliang8. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JDHybrid/JDHybrid-umbrella.h>

NS_ASSUME_NONNULL_BEGIN

@interface JDMapResourceMatcher : NSObject <JDResourceMatcherImplProtocol>

- (instancetype)initWithRootPath:(NSString *)rootPath;

@end

NS_ASSUME_NONNULL_END

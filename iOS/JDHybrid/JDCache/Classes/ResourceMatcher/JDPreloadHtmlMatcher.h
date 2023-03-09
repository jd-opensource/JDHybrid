//
//  JDPreloadHtmlMatcher.h
//  JDHybrid
//
//  Created by wangxiaorui19 on 2022/12/5.
//

#import <Foundation/Foundation.h>
#import "JDResourceMatcherManager.h"
#import "JDCacheProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol JDPreloadHtmlMatcherDataSource <NSObject>

- (BOOL)htmlPreloadEnable;

- (BOOL)htmlPreloadResume;

@end

@interface JDPreloadHtmlMatcher : NSObject<JDResourceMatcherImplProtocol>

@end

NS_ASSUME_NONNULL_END

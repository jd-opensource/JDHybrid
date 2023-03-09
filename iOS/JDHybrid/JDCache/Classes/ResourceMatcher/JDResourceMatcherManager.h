//
//  JDSchemeHandleManager.h
//  JDHybrid
//
//  Created by wangxiaorui19 on 2022/12/5.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "JDCacheProtocol.h"
#import "JDUtils.h"

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(LimitVersion))
@protocol JDResourceMatcherManagerDelegate <NSObject>

- (NSArray<id<JDResourceMatcherImplProtocol>> *)liveMatchers;

- (void)redirectWithRequest:(NSURLRequest *)redirectRequest;

@end

API_AVAILABLE(ios(LimitVersion))
@interface JDResourceMatcherManager : NSObject

@property (nonatomic, weak) id<JDResourceMatcherManagerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

//
//  WKWebViewConfiguration+Loader.h
//  JDHybrid
//
//  Created by wangxiaorui19 on 2022/12/12.
//

#import <WebKit/WebKit.h>
#import "JDCacheLoader.h"


NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(LimitVersion))
@interface WKWebViewConfiguration (Loader)

@property (nonatomic, strong, readonly, nullable) JDCacheLoader *loader;

@end

NS_ASSUME_NONNULL_END

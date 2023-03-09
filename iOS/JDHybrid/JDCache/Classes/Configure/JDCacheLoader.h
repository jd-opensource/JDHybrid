//
//  JDCacheLoader.h
//  JDHybrid
//
//  Created by wangxiaorui19 on 2022/12/12.
//

#import <Foundation/Foundation.h>
#import "JDCacheProtocol.h"
#import "JDCachePreload.h"
#import "JDUtils.h"


NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(LimitVersion))
@interface JDCacheLoader : NSObject

@property (nonatomic, assign) BOOL enable; // 开启Hybrid功能(默认为NO)

@property (nonatomic, assign) BOOL degrade; // 降级（降级后不会匹配离线资源）

@property (nonatomic, strong) JDCachePreload * preload; // HTML预加载器

/// 匹配器数组
/// 设置后JDCache会在拦截到请求后，依次在匹配器中查找资源，直到匹配为止；
/// 若全部没有匹配，则走原生网络请求
@property (nonatomic, copy) NSArray<id<JDResourceMatcherImplProtocol>> *matchers;

@end

NS_ASSUME_NONNULL_END

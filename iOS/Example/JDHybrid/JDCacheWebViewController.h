//
//  JDCacheWebViewController.h
//  JDHybrid_Example
//
//  Created by wangxiaorui19 on 2023/3/9.
//  Copyright © 2023 maxiaoliang8. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, JDCacheH5LoadType) {
    JDCacheH5LoadTypePure = 1, // 纯H5加载
    JDCacheH5LoadTypeNativeNetwork, // 拦截走原生网络（不匹配离线资源）
    JDCacheH5LoadTypeLocalResource, // 使用离线资源
    JDCacheH5LoadTypeLocalResourceAndPreload, // 使用离线资源和HTML预加载
    JDCacheH5LoadTypeLocalDegrade, // 降级加载
};

@interface JDCacheWebViewController : UIViewController
@property (nonatomic, assign) JDCacheH5LoadType H5LoadType;
@end

NS_ASSUME_NONNULL_END

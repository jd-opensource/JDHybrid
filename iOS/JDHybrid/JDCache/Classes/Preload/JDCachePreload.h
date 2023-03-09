//
//  JDCachePreload.h
//  JDHybrid
//
//  Created by wangxiaorui19 on 2022/12/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JDCachePreload : NSObject

@property (nonatomic, strong) NSURLRequest *request; // 需要预加载的HTML请求

@property (nonatomic, assign) BOOL enable; // 预加载是否可用（默认为NO）

- (void)startPreload; // 开始预加载

@end

NS_ASSUME_NONNULL_END

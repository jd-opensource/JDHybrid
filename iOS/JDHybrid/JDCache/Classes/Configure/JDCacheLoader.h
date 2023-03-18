//
//  JDCacheLoader.h
//  JDHybrid
/*
 MIT License

Copyright (c) 2022 JD.com, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

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

//
//  JDCacheProtocol.h
//  Pods
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

#import <WebKit/WebKit.h>


NS_ASSUME_NONNULL_BEGIN

typedef void(^JDNetRedirectDecisionCallback)(BOOL);
typedef void(^JDNetResponseCallback)(NSURLResponse * _Nonnull response);
typedef void(^JDNetDataCallback)(NSData * _Nonnull data);
typedef void(^JDNetSuccessCallback)(void);
typedef void(^JDNetFailCallback)(NSError * _Nonnull error);
typedef void(^JDNetRedirectCallback)(NSURLResponse * _Nonnull response,
                                     NSURLRequest * _Nonnull redirectRequest,
                                     JDNetRedirectDecisionCallback redirectDecisionCallback);
typedef void(^JDNetProgressCallBack)(int64_t nowBytes,int64_t total);


typedef NS_ENUM(NSUInteger, JDCacheErrorCode) {
    JDCacheErrorCodePreloadUnstart = 90001, // 预加载未开始
    JDCacheErrorCodeTimeout, // 超时
    JDCacheErrorCodeNotFind, // 资源未找到
    JDCacheErrorCodePreloadError, // 预加载失败
    JDCacheErrorCodeOther // 其他
};

/// 匹配器须遵守此协议并实现方法
@protocol JDResourceMatcherImplProtocol <NSObject>

/// 返回布尔类型，表示是否处理请求
/// @param request JDCache拦截到的请求
/// 如果此方法返回YES，则需要在下一个方法中回调对应的数据；
/// 如果此方法返回NO，则JDCache会检查下一个匹配器
- (BOOL)canHandleWithRequest:(NSURLRequest *)request;


/// 在此方法中匹配器回调给JDCache数据
/// @param request JDCache拦截到的请求
/// @param responseCallback 回调NSURLResponse对象
/// @param dataCallback 回调NSData对象
/// @param failCallback 回调error对象
/// @param successCallback 匹配成功回调
/// @param redirectCallback 重定向回调
- (void)startWithRequest:(NSURLRequest *)request
        responseCallback:(JDNetResponseCallback)responseCallback
            dataCallback:(JDNetDataCallback)dataCallback
            failCallback:(JDNetFailCallback)failCallback
         successCallback:(JDNetSuccessCallback)successCallback
        redirectCallback:(JDNetRedirectCallback)redirectCallback;

@end


/// JDCache对网络数据进行缓存的代理（推荐使用YYCache）
@protocol JDURLCacheDelegate <NSObject>

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key;

- (id<NSCoding>)objectForKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;

- (void)removeAllObjects;

@end

NS_ASSUME_NONNULL_END

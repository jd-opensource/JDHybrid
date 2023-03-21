//
//  JDCache.h
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
#import "JDCacheLoader.h"
#import "WKWebViewConfiguration+Loader.h"
#import "JDCachePreload.h"
#import "JDUtils.h"
#import "JDSafeArray.h"
#import "JDSafeDictionary.h"


NS_ASSUME_NONNULL_BEGIN

@interface JDCache : NSObject

+ (JDCache *)shareInstance;

@property (nonatomic, strong) id <JDURLCacheDelegate> netCache; // 网络数据缓存

@property (nonatomic, assign) BOOL LogEnabled; // log开关

@end

NS_ASSUME_NONNULL_END

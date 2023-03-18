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


NS_ASSUME_NONNULL_BEGIN

#define LimitVersion 13.0

#define xURLSchemeHandlerKey "xURLSchemeHandlerKey"

#define JDValidStr(str) [JDUtils isValidStr:str]
#define JDValidDic(dic) [JDUtils isValidDic:dic]
#define JDValidArr(arr) [JDUtils isValidArr:arr]
#define JDWeak(v) __weak typeof(v)weak##v = v;
#define JDStrong(v) __strong typeof(weak##v)v = weak##v;

//// log
FOUNDATION_EXPORT void JDCacheLog(NSString * _Nonnull format, ...) ;

@interface JDUtils : NSObject

+ (void)setLogEnable:(BOOL)enable ;

+ (BOOL)isValidStr:(NSString *)str;

+ (BOOL)isValidDic:(NSDictionary *)dic;

+ (BOOL)isValidArr:(NSArray *)arr;

+ (id)obj:(id)obj withPerformSel:(SEL)sel defaultValue:(nullable id)defaultValue;

+ (id)obj:(id)obj withPerformSel:(SEL)sel obj1:(nullable id)obj1 defaultValue:(nullable id)defaultValue;

+ (id)obj:(id)obj withPerformSel:(SEL)sel obj1:(nullable id)obj1 obj2:(nullable id)obj2 defaultValue:(nullable id)defaultValue;

+ (BOOL)isEqualURLA:(NSString *)urlStrA withURLB:(NSString *)urlStrB;

+ (long long)getAvailableMemorySize;

+ (long long)getTotalMemorySize;

+ (void)safeMainQueueBlock:(void (^)(void))block;

+ (NSDictionary *)dicWithJson:(id)json;

+ (NSArray *)arrayWithJson:(id)json;

+ (nullable id)objWithJson:(id)json;

+ (NSString *)objToJson:(id)obj;

+ (NSData *)dataWithBase64Decode:(NSString *)data;

+ (NSHTTPCookie *)cookieWithStr:(NSString *)str url:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END

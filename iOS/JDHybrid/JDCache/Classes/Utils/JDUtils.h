//
//  JDUtils.h
//  JDache
//
//  Created by maxiaoliang8 on 2022/5/17.
//

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

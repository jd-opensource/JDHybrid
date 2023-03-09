//
//  JDUtils.m
//  JDache
//
//  Created by maxiaoliang8 on 2022/5/17.
//

#import "JDUtils.h"
#import <mach/mach.h>
#import <mach/mach_host.h>
#import <sys/utsname.h>

static BOOL gJDCacheLogEnable = NO;

//// log
void JDCacheLog(NSString *format, ...) {
    if (!gJDCacheLogEnable) {
        return;
    }
    va_list args;
    va_start(args, format);
    NSString *logFormat = [@"『 Hybrid日志: 』" stringByAppendingString:format];
    NSString *result = [[NSString alloc] initWithFormat:logFormat arguments:args];
    NSLog(@"%@", result);
    va_end(args);
}

@implementation JDUtils

+ (void)setLogEnable:(BOOL)enable {
    gJDCacheLogEnable = enable;
}

+ (BOOL)isValidStr:(NSString *)str{
    if (str == nil || ![str isKindOfClass:[NSString class]] || str.length == 0) {
        return NO;
    }
    return YES;
}

+ (BOOL)isValidDic:(NSDictionary *)dic{
    if (dic == nil || ![dic isKindOfClass:[NSDictionary class]] || dic.count == 0) {
        return NO;
    }
    return YES;
}

+ (BOOL)isValidArr:(NSArray *)arr{
    if (arr == nil || ![arr isKindOfClass:[NSArray class]] || arr.count == 0) {
        return NO;
    }
    return YES;
}

+ (id)obj:(id)obj withPerformSel:(SEL)sel defaultValue:(id)defaultValue{
    return [self obj:obj withPerformSel:sel obj1:nil obj2:nil defaultValue:defaultValue];
}

+ (id)obj:(id)obj withPerformSel:(SEL)sel obj1:(id)obj1 defaultValue:(id)defaultValue{
    return [self obj:obj withPerformSel:sel obj1:obj1 obj2:nil defaultValue:defaultValue];
}


+ (id)obj:(id)obj withPerformSel:(SEL)sel obj1:(id)obj1 obj2:(id)obj2 defaultValue:(id)defaultValue{
    if ([obj respondsToSelector:sel]) {
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if (*[obj methodSignatureForSelector:sel].methodReturnType == 'v') {
            [obj performSelector:sel withObject:obj1 withObject:(id)obj2];
            return defaultValue;
        }
        return [obj performSelector:sel withObject:obj1 withObject:(id)obj2]?:defaultValue;
#pragma clang diagnostic pop
    }
    return defaultValue;
}

+ (BOOL)isEqualURLA:(NSString *)urlStrA withURLB:(NSString *)urlStrB{
    if (!urlStrA ||
        !urlStrB ||
        !JDValidStr(urlStrA) ||
        !JDValidStr(urlStrB)) {
        return NO;
    }
    
    if ([urlStrA isEqualToString:urlStrB]) {
        return YES;
    }
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"/ "];
    NSURL *urlA = [NSURL URLWithString:urlStrA];
    NSURL *urlB = [NSURL URLWithString:urlStrB];
    
    if (![urlA.scheme isEqualToString:urlB.scheme]) {
        return NO;
    }
    
    if (![urlA.host isEqualToString:urlB.host]) {
        return NO;
    }
    
    if (![[urlA.path stringByTrimmingCharactersInSet:set] isEqualToString:[urlB.path stringByTrimmingCharactersInSet:set]]) {
        return NO;
    }
    return YES;
}

+ (long long)getAvailableMemorySize{
    unsigned long long totalMemorySize = [NSProcessInfo processInfo].physicalMemory;
    return totalMemorySize;
}

+ (long long)getTotalMemorySize{
    vm_statistics_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
    if (kernReturn != KERN_SUCCESS) {
        return -1;
    }
    long long availableMemorySize = ((vm_page_size * vmStats.free_count + vm_page_size * vmStats.inactive_count));
    return availableMemorySize;
}

+ (void)safeMainQueueBlock:(void (^)(void))block{
    if (!block) return;
    if ([NSThread isMainThread]) {
        block();
    }else{
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

+ (NSDictionary *)dicWithJson:(id)json{
    id obj = [self objWithJson:json];
    if ([obj isKindOfClass:[NSDictionary class]]) {
        return obj;
    }
    return @{};
}

+ (NSArray *)arrayWithJson:(id)json{
    id obj = [self objWithJson:json];
    if ([obj isKindOfClass:[NSArray class]]) {
        return obj;
    }
    return @[];
}

+ (nullable NSDictionary *)objWithJson:(id)json{
    NSData *data = nil;
    if ([json isKindOfClass:[NSData class]]) {
        data = json;
    }else if([json isKindOfClass:[NSString class]]){
        data = [(NSString *)json dataUsingEncoding:NSUTF8StringEncoding];
    }
    if (data.length > 0) {
        return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    }else{
        return nil;
    }
}

+ (NSString *)objToJson:(id)obj{
    if ([NSJSONSerialization isValidJSONObject:obj]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
        if ([data isKindOfClass:[NSData class]]) {
            return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    return @"";
}

+ (NSData *)dataWithBase64Decode:(NSString *)data{
    if (!data) {
        return nil;
    }
    NSData *sData = [[NSData alloc]initWithBase64EncodedString:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return sData;
}


+ (NSHTTPCookie *)cookieWithStr:(NSString *)str url:(nonnull NSURL *)url{
    NSMutableDictionary *cookieMap = [NSMutableDictionary dictionary];
    NSArray *cookieKeyValueStrings = [str componentsSeparatedByString:@";"];
    for (NSString *cookieKeyValueString in cookieKeyValueStrings) {
        NSRange separatorRange = [cookieKeyValueString rangeOfString:@"="];
        if (separatorRange.location != NSNotFound &&
            separatorRange.location > 0) {
            NSRange keyRange = NSMakeRange(0, separatorRange.location);
            NSString *key = [cookieKeyValueString substringWithRange:keyRange];
            NSString *value = [cookieKeyValueString substringFromIndex:separatorRange.location + separatorRange.length];
            if (value == nil) {
                value = @"";
            }
            key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (key && value) {
                [cookieMap setObject:value forKey:key];
            }
        }
    }
    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
    for (NSString *key in [cookieMap allKeys]) {
        
        NSString *value = [cookieMap objectForKey:key];
        NSString *uppercaseKey = [key uppercaseString];//主要是排除命名不规范的问题
        if (!value || !key) {
            continue;
        }
        if ([uppercaseKey isEqualToString:@"DOMAIN"]) {
            if (![value hasPrefix:@"."] && ![value hasPrefix:@"www"]) {
                value = [NSString stringWithFormat:@".%@",value];
            }
            [cookieProperties setObject:value forKey:NSHTTPCookieDomain];
        }else if ([uppercaseKey isEqualToString:@"VERSION"]) {
            [cookieProperties setObject:value forKey:NSHTTPCookieVersion];
        }else if ([uppercaseKey isEqualToString:@"MAX-AGE"]||[uppercaseKey isEqualToString:@"MAXAGE"]) {
            [cookieProperties setObject:value forKey:NSHTTPCookieMaximumAge];
        }else if ([uppercaseKey isEqualToString:@"PATH"]) {
            [cookieProperties setObject:value forKey:NSHTTPCookiePath];
        }else if([uppercaseKey isEqualToString:@"ORIGINURL"]){
            [cookieProperties setObject:value forKey:NSHTTPCookieOriginURL];
        }else if([uppercaseKey isEqualToString:@"PORT"]){
            [cookieProperties setObject:value forKey:NSHTTPCookiePort];
        }else if([uppercaseKey isEqualToString:@"SECURE"]||[uppercaseKey isEqualToString:@"ISSECURE"]){
            [cookieProperties setObject:value forKey:NSHTTPCookieSecure];
        }else if([uppercaseKey isEqualToString:@"COMMENT"]){
            [cookieProperties setObject:value forKey:NSHTTPCookieComment];
        }else if([uppercaseKey isEqualToString:@"COMMENTURL"]){
            [cookieProperties setObject:value forKey:NSHTTPCookieCommentURL];
        }else if([uppercaseKey isEqualToString:@"EXPIRES"]){
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
            dateFormatter.dateFormat = @"EEE, dd-MMM-yyyy HH:mm:ss zzz";
            NSDate *date = [dateFormatter dateFromString:value];
            if (!date) {
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];//发现了这种赋值方法
                date = [dateFormatter dateFromString:value];
            }
            if (!date) {
                date = [NSDate dateWithTimeIntervalSinceNow:48*60*60];//用两天有效期兜底
            }
            [cookieProperties setObject:date forKey:NSHTTPCookieExpires];
        }else if([uppercaseKey isEqualToString:@"DISCART"]){
            [cookieProperties setObject:value forKey:NSHTTPCookieDiscard];
        }else if([uppercaseKey isEqualToString:@"NAME"]){
            [cookieProperties setObject:value forKey:NSHTTPCookieName];
        }else if([uppercaseKey isEqualToString:@"VALUE"]){
            [cookieProperties setObject:value forKey:NSHTTPCookieValue];
        }else{
            [cookieProperties setObject:key forKey:NSHTTPCookieName];
            [cookieProperties setObject:value forKey:NSHTTPCookieValue];
        }
    }
    if (![cookieProperties objectForKey:NSHTTPCookiePath]) {
        [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
    }
    if (JDValidStr(url.host) && ![cookieProperties objectForKey:NSHTTPCookieDomain]) {
        [cookieProperties setObject:url.host forKey:NSHTTPCookieDomain];
    }
    return [NSHTTPCookie cookieWithProperties:cookieProperties];
}

@end

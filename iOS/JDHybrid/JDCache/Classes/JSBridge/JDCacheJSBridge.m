//
//  JDCacheJSBridge.m
//  JDHybrid
//
//  Created by wangxiaorui19 on 2023/1/3.
//

#import "JDCacheJSBridge.h"
#import "JDUtils.h"
#import "JDBridge.h"

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)

@interface NSString (JDHybridCookie)

- (NSHTTPCookie *)hybrid_cookieWithUrl:(NSURL *)url;

@end

@implementation NSString(Cookie)

- (NSDictionary *)hybrid_cookieMap{
    NSMutableDictionary *cookieMap = [NSMutableDictionary dictionary];
    NSArray *cookieKeyValueStrings = [self componentsSeparatedByString:@";"];
    for (NSString *cookieKeyValueString in cookieKeyValueStrings) {
        //找出第一个"="号的位置
        NSRange separatorRange = [cookieKeyValueString rangeOfString:@"="];
        
        if (separatorRange.location != NSNotFound &&
            separatorRange.location > 0) {
            //以上条件确保"="前后都有内容，不至于key或者value为空
            
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
    return cookieMap;
}

- (NSDictionary *)hybrid_cookiePropertiesWithUrl:(NSURL *)url{
    NSDictionary *cookieMap = [self hybrid_cookieMap];
    
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
    
    if (JDValidStr(url.host) && ![cookieProperties objectForKey:NSHTTPCookieDomain]) {
        [cookieProperties setObject:url.host forKey:NSHTTPCookieDomain];
    }
    //由于cookieWithProperties:方法properties中不能没有NSHTTPCookiePath，所以这边需要确认下，如果没有则默认为@"/"
    if (![cookieProperties objectForKey:NSHTTPCookiePath]) {
        [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
    }
    return cookieProperties;
}

- (NSHTTPCookie *)hybrid_cookieWithUrl:(NSURL *)url{
    NSDictionary *cookieProperties = [self hybrid_cookiePropertiesWithUrl:url];
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    return cookie;
}

@end

@interface JDCacheJSBridge ()

@property(nonatomic, weak)WKWebView *webView;

@property(nonatomic, copy)NSDictionary *paramsConfigDictionary;

@property(nonatomic, copy)NSString *boundary;

@end

@implementation JDCacheJSBridge

- (void)userContentController:(nonnull WKUserContentController *)userContentController
      didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    if ([message.name isEqualToString:@"JDCache"]) {
        self.webView = message.webView;
        NSDictionary *body = message.body;
        if (!JDValidDic(body)) {
            return;
        }
        if ([NSThread isMainThread]) {
            [self invokeJsMethodWithBody:body];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self invokeJsMethodWithBody:body];
            });
        }
    }
}

- (void)invokeJsMethodWithBody:(NSDictionary *)body{
    NSString *method = body[@"method"];
    if (!JDValidStr(method)) {
        return;
    }
    method = self.paramsConfigDictionary[method];
    NSDictionary *params = body[@"params"];
    if ([self respondsToSelector:NSSelectorFromString(method)]) {
        NSString *callBackName = body[@"callBackName"];
        if (!JDValidStr(callBackName)) {//目前只能处理只有callBackName的情况
            SuppressPerformSelectorLeakWarning([self performSelector:NSSelectorFromString(method) withObject:params]);
            
        }
        else{
            SuppressPerformSelectorLeakWarning([self performSelector:NSSelectorFromString(method) withObject:params withObject:callBackName]);
        }
    }
}

- (void)syncCookie:(NSDictionary *)params{
    NSString *url = params[@"url"];
    if (!JDValidStr(url)) {
        return;
    }
    JDCacheLog(@"同步cookie，url: %@", url);
    NSURL *URL = [NSURL URLWithString:url];
    if (!URL || !JDValidStr(URL.absoluteString)) {
        URL = nil;
    }
    NSHTTPCookie *cookie =  [params[@"cookie"] hybrid_cookieWithUrl:URL];
    if (!cookie) return;
    if (!URL) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        return;
    }
    NSString *sel1 = @"_";
    NSString *sel2 = @"setCookies:forURL:mainDocumentURL:";
    NSString *sel3 = @"policyProperties:";
    SEL selector = NSSelectorFromString([[sel1 stringByAppendingString:sel2] stringByAppendingString:sel3]);
    if ([NSHTTPCookieStorage instancesRespondToSelector:selector]) {
        NSMethodSignature *methodSignature = [[NSHTTPCookieStorage class] instanceMethodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        invocation.target = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        invocation.selector = selector;
        
        NSArray *arg1 = @[cookie];
        NSURL *arg2 = URL;
        NSURL *arg3 = URL;
        NSString *prefix = @"_kCF";
        NSDictionary *arg4 = @{
            [prefix stringByAppendingString:@"HTTPCookiePolicyPropertySiteForCookies"]: URL,
            [prefix stringByAppendingString:@"HTTPCookiePolicyPropertyIsTopLevelNavigation"]: [NSNumber numberWithBool:YES],
        };
        [invocation setArgument:&arg1 atIndex:2];
        [invocation setArgument:&arg2 atIndex:3];
        [invocation setArgument:&arg3 atIndex:4];
        [invocation setArgument:&arg4 atIndex:5];
        [invocation invoke];
    } else {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:@[cookie] forURL:URL mainDocumentURL:URL];
    }
    
}

- (NSDictionary *)getAllHeadersWithHeaders:(NSDictionary *)headers URL:(NSURL *)URL {
    NSMutableDictionary *headersM = [headers mutableCopy];
    
    NSString *referer = self.webView.URL.absoluteString;
    headersM[@"Referer"] = referer;
    NSURL *locationUrl = [NSURL URLWithString:referer];
    headersM[@"Origin"] = [locationUrl.scheme stringByAppendingFormat:@"://%@",locationUrl.host];
        
    NSArray<NSHTTPCookie *> *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
    if (cookies.count > 0) {
        NSMutableString *obj = [NSMutableString string];
        for (NSHTTPCookie *cookie in cookies) {
            if (cookie.domain && [URL.host hasSuffix:cookie.domain] && cookie.name.length > 0) {
                [obj appendFormat:@"%@=%@; ",cookie.name,cookie.value];
            }
        }
        headersM[@"Cookie"] = [obj copy];
    }
        
    NSString *ua = self.webView.customUserAgent;
    if (JDValidStr(ua)) {
        headersM[@"User-Agent"] = ua?:@"";
    }
    return [headersM copy];
}


- (void)fetchPostReuqestWithParams:(NSDictionary *)params {
    NSString *url = params[@"url"];
    if (!JDValidStr(url)) return;
    
    JDCacheLog(@"桥接formData，params: %@", params);
    
    if (![url hasPrefix:@"https:"]&&![url hasPrefix:@"http:"]) {
        if ([url hasPrefix:@"//"]) {
            url = [@"https:" stringByAppendingString:url];
        }else if ([url hasPrefix:@"/"]){
            NSString *referer = self.webView.URL.absoluteString;;
            NSString * prefixUrl = [referer componentsSeparatedByString:@"?"].firstObject;
            if (JDValidStr(prefixUrl)) {
                url = [prefixUrl stringByAppendingString:url];
            }
        }
    }
    
    NSString *body = params[@"body"];
    if (!JDValidStr(body)) return;
    
    NSString *type = params[@"type"];
    NSDictionary *headers = params[@"headers"];
    headers = [self getAllHeadersWithHeaders:headers URL:[NSURL URLWithString:url]];
        
    void(^jsCallBack)(NSInteger, id, NSDictionary *, NSError *) = ^(NSInteger status, id responseObject, NSDictionary *responseHeaders,NSError * error) {
        NSString *xhrId = params[@"id"];
        if (!JDValidStr(xhrId)) return;
        NSMutableDictionary *callBackDic = [NSMutableDictionary dictionary];
        callBackDic[@"status"] = @(status);
        if (error) {
            callBackDic[@"data"] = error.description;
        }else{
            if ([responseObject isKindOfClass:[NSData class]]) {
                callBackDic[@"data"] = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            }else{
                callBackDic[@"data"] = responseObject;
            }
        }
        callBackDic[@"headers"] = responseHeaders;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.webView evaluateJavaScript:[NSString stringWithFormat:@"window.jd_realxhr_callback('%@',%@)",xhrId,[JDUtils objToJson:callBackDic]] completionHandler:^(id  _Nullable obj, NSError * _Nullable error) {
                
            }];
        });
    };
    
    if (JDValidStr(type) && [type isEqualToString:@"formData"]) {
        // 处理formData
        NSDictionary *bodyParams = [JDUtils dicWithJson:body];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        [requestM setAllHTTPHeaderFields:headers];
        [requestM setHTTPMethod:@"POST"];
        NSURLRequest *request = [self formDataRequestWithRequest:requestM intercepteBodyArray:bodyParams];
        NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)(response);
            if (error) {
                jsCallBack([urlResponse statusCode],nil, urlResponse.allHeaderFields,error);
                return;
            }
            jsCallBack([urlResponse statusCode],data, urlResponse.allHeaderFields,nil);
        }];
        [dataTask resume];
        return;
    }
    if (JDValidStr(type) && [type isEqualToString:@"blob"]) {
        // 处理blob
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        [requestM setAllHTTPHeaderFields:headers];
        [requestM setHTTPMethod:@"POST"];
        [requestM setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
        NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:[requestM copy] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)(response);
            if (error) {
                jsCallBack([urlResponse statusCode],nil, urlResponse.allHeaderFields,error);
                return;
            }
            jsCallBack([urlResponse statusCode],data, urlResponse.allHeaderFields,nil);
        }];
        [dataTask resume];
        return;
    }
}

- (NSURLRequest *)formDataRequestWithRequest:(NSMutableURLRequest *)requestM intercepteBodyArray:(NSDictionary*)formData {
    if (!JDValidDic(formData)) {
        return [requestM copy];
    }
    
    [requestM setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",self.boundary] forHTTPHeaderField:@"Content-Type"];
    NSMutableData *postData = [[NSMutableData alloc]init];//请求体数据
    
    [formData enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSString *filePair = [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type=%@\r\n\r\n",self.boundary,key,obj[@"name"],obj[@"type"]];
            [postData appendData:[filePair dataUsingEncoding:NSUTF8StringEncoding]];
            
            NSString *dataString = obj[@"data"];
            if ([dataString isKindOfClass:[NSString class]]) {
                NSData *data ;
                NSString *prefix = @"base64,";
                NSRange range = [dataString rangeOfString:prefix];
                if (range.location != NSNotFound) {
                    dataString = [dataString substringFromIndex:prefix.length + range.location];
                    data = [JDUtils dataWithBase64Decode:dataString];
                }else{
                    data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
                }
                [postData appendData:data];
            }else if ([dataString isKindOfClass:[NSData class]]){
                [postData appendData:(NSData *)dataString];
            }
        }else if([obj isKindOfClass:[NSString class]]){
            NSString *filePair = [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n",self.boundary,key];
            [postData appendData:[filePair dataUsingEncoding:NSUTF8StringEncoding]];
            [postData appendData:[obj dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [postData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    //设置结尾
    [postData appendData:[[NSString stringWithFormat:@"--%@--\r\n",self.boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [requestM setHTTPBody:[postData copy]];
    
    return [requestM copy];
}


#pragma mark - lazy
- (NSDictionary *)paramsConfigDictionary{
    if (!_paramsConfigDictionary) {
        _paramsConfigDictionary = @{
            @"fetchPostReuqestWithParams"                   : @"fetchPostReuqestWithParams:",
            @"syncCookie"                                   : @"syncCookie:"
        };
    }
    return _paramsConfigDictionary;
}

- (NSString *)boundary {
    if (!_boundary) {
        _boundary = [NSString stringWithFormat:@"JDHybrid+%08X%08X", arc4random(), arc4random()];
    }
    return _boundary;
}

@end

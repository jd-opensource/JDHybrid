//
//  JDCachedURLResponse.m
//  JDBHybridModule
//
//  Created by wangxiaorui19 on 2021/11/16.
//

#import "JDCachedURLResponse.h"
#import "JDUtils.h"
@interface JDCachedURLResponse ()
@property (readwrite, copy) NSHTTPURLResponse *response;

@property (readwrite, copy) NSData *data;

@property (readwrite, assign) unsigned long long timestamp;

@property (readwrite, assign) unsigned long long maxAge;

@property (readwrite, copy) NSString *etag;

@property (readwrite, copy) NSString *lastModified;

@end

@implementation JDCachedURLResponse{
    BOOL _canSave;
}

- (instancetype)initWithResponse:(NSHTTPURLResponse *)response
                            data:(NSData *)data{
    self = [super init];
    if (self) {
        _response = response;
        _data = data;
        _timestamp = (unsigned long long)[NSDate new].timeIntervalSince1970;
        [self parseResponseHeader];
    }
    return self;
}

- (BOOL)canCache {
    return _canSave;
}

- (BOOL)isExpired {
    unsigned long long now = (unsigned long long)[[NSDate new] timeIntervalSince1970];
    if (now - self.timestamp < self.maxAge) { // 没有过期
        return NO;
    }
    return YES;
}


- (void)updateWithResponse:(NSDictionary *)newHeaderFields {
    NSMutableDictionary *headerFieldsM = [self.response.allHeaderFields mutableCopy];
    [newHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        if (!JDValidStr(key) || !JDValidStr(value)) {
            return;
        }
        NSString *oldValue = self.response.allHeaderFields[key];
        if (!JDValidStr(oldValue)) {
            return;
        }
        headerFieldsM[key] = value;
    }];
    NSHTTPURLResponse *updateResponse = [[NSHTTPURLResponse alloc] initWithURL:self.response.URL
                                                                    statusCode:self.response.statusCode
                                                                   HTTPVersion:@"HTTP/2.0"
                                                                  headerFields:[headerFieldsM copy]];
    self.response = updateResponse;
    self.timestamp = (unsigned long long)[NSDate new].timeIntervalSince1970;
    [self parseCacheControl];
    if (!_canSave) {
        return;
    }
    
    [self parseEtag];
    if (JDValidStr(self.etag)) {
        return;
    }
    
    [self parseLastModified];
}

- (void)parseResponseHeader {
    if (_response.statusCode != 200) {
        _canSave = NO;
        return;
    }
    NSString *contentType = _response.allHeaderFields[@"Content-Type"];
    if (!JDValidStr(contentType)) {
        _canSave = NO;
        return;
    }
    if ([contentType containsString:@"text/html"]) {
        _canSave = NO;
        return;
    }
    if ([contentType containsString:@"video"]) {
        _canSave = NO;
        return;
    }
    // Cache-Control
    [self parseCacheControl];
    if (!_canSave) {
        return;
    }
    // Etag
    [self parseEtag];
    if (JDValidStr(self.etag)) {
        return;
    }
    // Last-Modified
    [self parseLastModified];
}

- (void)parseCacheControl {
    NSString *cacheControl = _response.allHeaderFields[@"Cache-Control"];
    if (!JDValidStr(cacheControl)) {
        _canSave = NO;
        return;
    }

    NSArray<NSString *> *controlItems = [cacheControl componentsSeparatedByString:@","];
    __block BOOL toCache = NO;
    __block unsigned long long cacheTimestamp = 0;
    [controlItems enumerateObjectsUsingBlock:^(NSString * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *trimItem = [item stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([trimItem isEqualToString:@"no-cache"] || [trimItem isEqualToString:@"no-store"]) {
            toCache = NO;
            *stop = YES;
            return;
        }
        if ([trimItem hasPrefix:@"max-age"] && trimItem.length > 8) {
            long long cacheTime = [[trimItem substringFromIndex:8]  longLongValue];
            if (cacheTime <= 0) {
                *stop = YES;
                return;
            }
            cacheTimestamp = cacheTime;
            toCache = YES;
            
        } else {
        }
        
    }];
    _canSave = toCache;
    self.maxAge = cacheTimestamp;

    if (_canSave) {
    }
}

- (void)parseEtag {
    NSString *etag = _response.allHeaderFields[@"Etag"];
    if (!JDValidStr(etag)) {

        return;
    }
    self.etag = etag;

}

- (void)parseLastModified {
    NSString *lastModified = _response.allHeaderFields[@"Last-Modified"];
    if (!JDValidStr(lastModified)) {

        return;
    }
    self.lastModified = lastModified;

}


#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
    JDCachedURLResponse *cacheResponse = [[[self class] allocWithZone:zone] initWithResponse:_response
                                                                                        data:_data];
    cacheResponse.timestamp = self.timestamp;
    cacheResponse.maxAge = self.maxAge;
    cacheResponse.etag = self.etag;
    cacheResponse.lastModified = self.lastModified;
    
    return cacheResponse;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeObject:_response forKey:@"response"];
    [coder encodeObject:_data forKey:@"data"];
    [coder encodeDouble:_timestamp forKey:@"timestamp"];
    [coder encodeInt64:_maxAge forKey:@"maxAge"];
    [coder encodeObject:_etag forKey:@"etag"];
    [coder encodeObject:_lastModified forKey:@"lastModified"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    self = [super init];
    if (self) {
        self.response = [coder decodeObjectForKey:@"response"];
        self.data = [coder decodeObjectForKey:@"data"];
        self.timestamp = [coder decodeDoubleForKey:@"timestamp"];
        self.maxAge = [coder decodeInt64ForKey:@"maxAge"];
        self.etag = [coder decodeObjectForKey:@"etag"];
        self.lastModified = [coder decodeObjectForKey:@"lastModified"];
    }
    return self;
}

@end

//
//  JDOfflineResSchemeHandler.m
//  JDHybrid_Example
//
//  Created by wangxiaorui19 on 2022/12/8.
//  Copyright © 2022 maxiaoliang8. All rights reserved.
//

#import "JDMapResourceMatcher.h"
#import <JDHybrid/JDSafeDictionary.h>

@interface JDMapResourceMatcher ()
@property (nonatomic, copy) NSString *rootPath;
@property (nonatomic, copy) NSDictionary *resMap;
@property (nonatomic, copy) JDSafeDictionary *resultMap;
@end

@implementation JDMapResourceMatcher


- (instancetype)initWithRootPath:(NSString *)rootPath {
    self = [super init];
    if (self) {
        _rootPath = rootPath;
        [self handleDir];
    }
    return self;
}

- (void)handleDir {
    if (!JDValidStr(self.rootPath)) {
        return;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.rootPath]){
        return ;
    }
    NSString *resourceJson = [self.rootPath stringByAppendingPathComponent:@"resource.json"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:resourceJson]) {
        return ;
    }
    NSError *err = nil;
    NSString *jsonStr = [NSString stringWithContentsOfFile:resourceJson encoding:NSUTF8StringEncoding error:&err];
    if (!JDValidStr(jsonStr) || err) {
        return ;
    }
    NSArray *array = [JDUtils arrayWithJson:jsonStr];
    NSMutableDictionary *bigMapM = [NSMutableDictionary dictionaryWithCapacity:0];
    [array enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:[NSDictionary class]]) {
            return;
        }
        NSString *url = obj[@"url"];
        if (!JDValidStr(url)) {
            return;
        }
        NSURL *URL = [NSURL URLWithString:url];
        url = [URL.host stringByAppendingPathComponent:URL.path];
        if (!JDValidStr(url)) {
            return;
        }
        bigMapM[url] = obj; // host + path
    }];
    self.resMap = [bigMapM copy];
}

- (BOOL)findOfflineResWithURL:(NSURL *)URL {
    NSString *url = [URL.host stringByAppendingPathComponent:URL.path];
    if (!JDValidStr(url)) {
        return NO;
    }
    NSDictionary *resDict = self.resMap[url];
    if (!JDValidDic(resDict)) {
        return NO;
    }
    NSString *fileName = resDict[@"filename"];
    NSDictionary *header = resDict[@"header"];
    NSString *type = resDict[@"type"];
    
    if (!JDValidStr(fileName) || !JDValidDic(header)) {
        return NO;
    }
    NSString *resPath = [self.rootPath stringByAppendingPathComponent:fileName];
    // 读取文件数据
    NSData *data = [NSData dataWithContentsOfFile:resPath];
    if (!data) {
        return NO;
    }
    NSDictionary *result = @{
        @"header": header,
        @"data": data
    };
    [self.resultMap setObject:result forKey:URL.absoluteString];
    return YES;
}

#pragma mark - JDSchemeHandlerImplProtocol

- (BOOL)canHandleWithRequest:(nonnull NSURLRequest *)request {
    return [self findOfflineResWithURL:request.URL];
}

- (void)startWithRequest:(nonnull NSURLRequest *)request responseCallback:(nonnull JDNetResponseCallback)responseCallback dataCallback:(nonnull JDNetDataCallback)dataCallback failCallback:(nonnull JDNetFailCallback)failCallback successCallback:(nonnull JDNetSuccessCallback)successCallback redirectCallback:(nonnull JDNetRedirectCallback)redirectCallback {
    NSString *url = request.URL.absoluteString;
    if (!JDValidStr(url)) {
        failCallback([NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil]);
        return;
    }
    NSDictionary *responseMap = [self.resultMap objectForKey:url];
    if (!JDValidDic(responseMap)) {
        failCallback([NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil]);
        return;
    }
    NSDictionary *header = responseMap[@"header"];
    NSData *data = responseMap[@"data"];
    if (!data || !JDValidDic(header)) {
        failCallback([NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil]);
        return;
    }
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                              statusCode:200
                                                             HTTPVersion:@"HTTP/2.0"
                                                            headerFields:header];
    responseCallback(response);
    dataCallback(data);
    successCallback();
    JDCacheLog(@"从离线包获取数据，url: %@", request.URL.absoluteString);
}

#pragma mark - lazy

- (NSDictionary *)resMap {
    if (!_resMap) {
        _resMap = [NSDictionary dictionary];
    }
    return _resMap;
}

- (JDSafeDictionary *)resultMap {
    if (!_resultMap) {
        _resultMap = [JDSafeDictionary new];
    }
    return _resultMap;
}

@end

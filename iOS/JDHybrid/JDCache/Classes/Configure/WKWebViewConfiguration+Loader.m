//
//  WKWebViewConfiguration+Loader.m
//  JDHybrid
//
//  Created by wangxiaorui19 on 2022/12/12.
//

#import "WKWebViewConfiguration+Loader.h"
#import <objc/runtime.h>
#import "JDUtils.h"

@interface JDCacheLoader (Private)

@property (nonatomic, weak) WKWebViewConfiguration * configuration;

@end

static void *JDCacheLoaderKey = &JDCacheLoaderKey;

@implementation WKWebViewConfiguration (Loader)

- (nullable JDCacheLoader *)loader API_AVAILABLE(ios(LimitVersion)){
    if (@available(iOS LimitVersion, *)) {
        JDCacheLoader* loader = objc_getAssociatedObject(self, JDCacheLoaderKey);
        if (!loader) {
            loader = [JDCacheLoader new];
            loader.configuration = self;
            objc_setAssociatedObject(self, JDCacheLoaderKey, loader, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            return loader;
        }
        return loader;
    } else {
        return nil;
    }
}

@end

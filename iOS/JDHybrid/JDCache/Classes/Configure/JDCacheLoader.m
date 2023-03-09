//
//  JDCacheLoader.m
//  JDHybrid
//
//  Created by wangxiaorui19 on 2022/12/12.
//

#import "JDCacheLoader.h"
#import <WebKit/WebKit.h>
#import <objc/message.h>
#import "JDWeakProxy.h"
#import "JDResourceMatcherManager.h"

#import "WKWebViewConfiguration+Loader.h"
#import "JDPreloadHtmlMatcher.h"
#import "JDCacheJSBridge.h"

API_AVAILABLE(ios(LimitVersion))

@interface JDCachePreload (JDCache)

@property (nonatomic, assign, readonly) BOOL havePreload;

- (JDPreloadHtmlMatcher *)defaultPreloadMatcher;

@end

static void *JDCacheConfigurationKey = &JDCacheConfigurationKey;

@implementation WKProcessPool (JDCache)

+ (instancetype)sharePool {
    static WKProcessPool *pool = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        pool = [[WKProcessPool alloc] init];
    });
    return pool;
}

@end

@interface JDCacheLoader ()<JDResourceMatcherManagerDelegate>

@property (nonatomic, copy) NSArray *schemes;

@property (nonatomic, weak) WKWebView *webView;

@property (nonatomic, weak) WKWebViewConfiguration * configuration;

@property (nonatomic, strong) JDWeakProxy * proxy;

@property (nonatomic, strong) JDCacheJSBridge<WKScriptMessageHandler> * jsbridge;

@property (nonatomic, strong) JDResourceMatcherManager *resMatcherManager;

@end

@implementation JDCacheLoader{
    BOOL _addHookJs;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _schemes = @[@"https", @"http"];
        _resMatcherManager = [JDResourceMatcherManager new];
        _resMatcherManager.delegate = self;
    }
    return self;
}

- (void)setEnable:(BOOL)enable {
    if (@available(iOS LimitVersion, *)) {
        if (enable && !_enable) {
            [JDCacheLoader hook];
            [JDCacheLoader handleBlobData];
            
            [self sharePool];
            [self addHookJs];
            [self registerJSBridge];
            [self registerSchemes];
        }
        _enable = enable;
    }
}

- (void)setPreload:(JDCachePreload *)preload {
    _preload = preload;
}

- (void)setWebView:(WKWebView *)webView{
    _webView = webView;
    objc_setAssociatedObject(_webView, JDCacheConfigurationKey, self.configuration, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)sharePool {
    self.configuration.processPool = [WKProcessPool sharePool];
}

- (void)addHookJs{
    if (_addHookJs) {
        return;
    }
    _addHookJs = YES;
    {
        NSString *path = [[NSBundle bundleForClass:NSClassFromString(@"JDCache")] pathForResource:@"JDCache" ofType:@"bundle"];
        NSString *js = [NSString stringWithContentsOfFile:[path stringByAppendingPathComponent:@"hook.js"] encoding:NSUTF8StringEncoding error:nil];
        if (JDValidStr(js)) {
            [self.configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO]];
        }
    }
    {
        NSString *path = [[NSBundle bundleForClass:NSClassFromString(@"JDCache")] pathForResource:@"JDCache" ofType:@"bundle"];
        NSString *js = [NSString stringWithContentsOfFile:[path stringByAppendingPathComponent:@"cookie.js"] encoding:NSUTF8StringEncoding error:nil];
        if (JDValidStr(js)) {
            [self.configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO]];
        }
    }
    
}

- (void)registerJSBridge {
    if (@available(iOS LimitVersion, *)) {
        [self.configuration.userContentController removeScriptMessageHandlerForName:@"JDCache"];
        [self.configuration.userContentController addScriptMessageHandler:self.jsbridge name:@"JDCache"];
    }
}

- (void)registerSchemes {
    if (@available(iOS LimitVersion, *)) {
        [self.schemes enumerateObjectsUsingBlock:^(NSString * _Nonnull scheme, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!JDValidStr(scheme)) {
                return;
            }
            if (![WKWebView handlesURLScheme:scheme] && ![self.configuration urlSchemeHandlerForURLScheme:scheme]){
                [self.configuration setURLSchemeHandler:self.proxy forURLScheme:scheme];
            }
        }];
    }
}

#pragma mark - hook
+ (void)hook{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = [WKWebView class];
        {
            __block BOOL (*oldImp)(id,SEL,id)  = NULL;
            SEL sel = @selector(handlesURLScheme:);
            IMP newImp = imp_implementationWithBlock(^(id obj, NSString* scheme){
                return NO;
            });
            Method method = class_getInstanceMethod(object_getClass(cls), sel);
            oldImp = (BOOL (*)(id,SEL,id))method_getImplementation(method);
            if (!class_addMethod(object_getClass(cls), sel, newImp, method_getTypeEncoding(method))) {
                oldImp = (BOOL (*)(id,SEL,id))method_setImplementation(method, newImp);
            }
        }
        {
            __block WKWebView* (*oldImp)(id,SEL,CGRect,id)  = NULL;
            SEL sel = @selector(initWithFrame:configuration:);
            IMP newImp = imp_implementationWithBlock(^(id obj, CGRect frame, WKWebViewConfiguration*configuration){
                WKWebView *webview = oldImp(obj,sel,frame,configuration);
                if (configuration.loader.enable) {
                    configuration.loader.webView = webview;
                    [configuration.loader.preload startPreload];
                }
                return webview;
            });
            Method method = class_getInstanceMethod(cls, sel);
            oldImp = (WKWebView* (*)(id,SEL,CGRect,id))method_getImplementation(method);
            if (!class_addMethod(cls, sel, newImp, method_getTypeEncoding(method))) {
                oldImp = (WKWebView* (*)(id,SEL,CGRect,id))method_setImplementation(method, newImp);
            }
        }
    });
}
                  
+ (void)handleBlobData {
  BOOL canHandleBlob = NO;
  if(@available(iOS LimitVersion, *)){
      canHandleBlob = YES;
  }
  if (!canHandleBlob) {
      return;
  }
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      int JDSchemeHandlerMethod[] = {88,116,98,115,75,104,102,99,85,98,116,104,114,117,100,98,116,84,98,117,110,102,107,107,126,61,0};
      int JDSchemeHandlerClass[] = {95,109,106,94,97,109,127,0};
      NSString *(^ paraseIntArray)(int [], int) = ^(int array[],int i) {
          NSMutableString *cls = [NSMutableString string];
          int * clsInt = array;
          do {
              char c = *clsInt^i;
              [cls appendFormat:@"%c",c];
          } while (*++clsInt != 0);
          return cls;
      };
      NSString * method = paraseIntArray(JDSchemeHandlerMethod,7);
      NSString * className = paraseIntArray(JDSchemeHandlerClass,8);
      Class clsType;
      if ((clsType = NSClassFromString(className))) {
          SEL sel = NSSelectorFromString(method);
          if ([clsType respondsToSelector:sel]) {
              ((void (*) (id,SEL,BOOL))objc_msgSend)(clsType,sel,NO);
           }
      }
  });

}


#pragma mark - lazy
                  
- (JDWeakProxy *)proxy{
    if (!_proxy) {
        _proxy = [[JDWeakProxy alloc] initWithTarget:self.resMatcherManager];
    }
    return _proxy;
}

- (JDCacheJSBridge *)jsbridge {
    if (!_jsbridge) {
        _jsbridge = [[JDCacheJSBridge alloc] init];
    }
    return _jsbridge;
}

#pragma mark - JDResourceMatcherManagerDelegate

- (nonnull NSArray<id<JDResourceMatcherImplProtocol>> *)liveMatchers {
    if (self.degrade) {
        return @[];
    }
    NSMutableArray<id<JDResourceMatcherImplProtocol>> *matchersM = [NSMutableArray arrayWithArray:self.matchers];
    if (self.preload) {
        JDPreloadHtmlMatcher *preloadMatcher = [self.preload defaultPreloadMatcher];
        [matchersM insertObject:preloadMatcher atIndex:0];
    }
    return [matchersM copy];
}

- (void)redirectWithRequest:(NSURLRequest *)redirectRequest {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webView loadRequest:redirectRequest];
    });
}

@end


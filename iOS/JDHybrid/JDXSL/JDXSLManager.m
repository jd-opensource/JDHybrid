//
//  JDXSLManager.m
//  JDBHybridModule
//
//  Created by zhoubaoyang on 2022/8/24.
//

#import "JDXSLManager.h"
#import <objc/message.h>
#import "hybrid_hook_xsl_js.h"
#import "JDHybridXSLRegister.h"
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <mach-o/ldsyms.h>

static void *hybridXSLElementKey = &hybridXSLElementKey;

static void *hybridXSLElementMapKey = &hybridXSLElementMapKey;

static void *hybridXSLDidFinishHandleWKContentGestureKey = &hybridXSLDidFinishHandleWKContentGestureKey;

static void *hybridXSLIdMapKey = &hybridXSLIdMapKey;

@interface JDXSLManager ()

@end

@interface WKWebView (XSL)

@end

@implementation WKWebView(XSL)

static void *xslWebViewKey = &xslWebViewKey;

- (NSMutableDictionary *)xslIdMap {
    return objc_getAssociatedObject(self, &hybridXSLIdMapKey);
}

- (void)setXslIdMap:(NSMutableDictionary*)xslIdMap {
    objc_setAssociatedObject(self, &hybridXSLIdMapKey, xslIdMap, OBJC_ASSOCIATION_COPY);
}

- (NSString*)isFinishHandleWKContentGesture {
    return objc_getAssociatedObject(self, &hybridXSLDidFinishHandleWKContentGestureKey);
}

- (void)setIsFinishHandleWKContentGesture:(NSString*)isFinishHandle {
    objc_setAssociatedObject(self, &hybridXSLDidFinishHandleWKContentGestureKey, isFinishHandle, OBJC_ASSOCIATION_COPY);
}

- (NSMutableDictionary *)xslElementMap {
    return objc_getAssociatedObject(self, &hybridXSLElementMapKey);
}

- (void)setXslElementMap:(NSMutableDictionary*)xslElementMap {
    objc_setAssociatedObject(self, &hybridXSLElementMapKey, xslElementMap, OBJC_ASSOCIATION_COPY);
}

- (void)xslHandleWKContentGestrues {
    UIScrollView *webViewScrollView = self.scrollView;
    if ([webViewScrollView isKindOfClass:NSClassFromString(@"WKScrollView")]) {
        UIView *_WKContentView = webViewScrollView.subviews.firstObject;
        if (![_WKContentView isKindOfClass:NSClassFromString(@"WKContentView")]) return;
        NSArray *gestrues = _WKContentView.gestureRecognizers;
        Class clz = NSClassFromString(@"UITextTapRecognizer");
        for (UIGestureRecognizer *gesture in gestrues) {
            if ([gesture isKindOfClass:clz]) {
                gesture.enabled = NO;
                continue;
            }
            gesture.cancelsTouchesInView = NO;
            gesture.delaysTouchesBegan = NO;
            gesture.delaysTouchesEnded = NO;
        }
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *wkHitView = [super hitTest:point withEvent:event];
    if (![self.isFinishHandleWKContentGesture isEqualToString:@"1"]) {
        [self xslHandleWKContentGestrues];
        self.isFinishHandleWKContentGesture = @"1";
    }
    return wkHitView;
}

- (void)addUserScript{
    [[JDXSLManager shareManager].elementsClassMap.copy enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, JDXSLBaseElement*  _Nonnull obj, BOOL * _Nonnull stop) {
        WKUserScript *script = [[WKUserScript alloc] initWithSource:((id(*)(id,SEL))objc_msgSend)(obj,@selector(jsClass))
                                                      injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                   forMainFrameOnly:NO];
        [self.configuration.userContentController addUserScript:script];
    }];
}

- (void)addElementAvailableUserScript{
    NSMutableString* keyString = [NSMutableString string];
    for (NSString* key in [JDXSLManager HybridXslAvailableElement]) {
        [keyString appendString:[NSMutableString stringWithFormat:@"'%@',",key]];
    }
    if (keyString.length > 0) {
        keyString = [NSMutableString stringWithFormat:@"%@",[keyString substringToIndex:keyString.length - 1]];
    }
    NSMutableString* keyArrString = [NSMutableString stringWithString:@"["];
    [keyString appendString:[NSMutableString stringWithString:@"]"]];
    [keyArrString appendString:keyString];
    
    WKUserScript *script = [[WKUserScript alloc] initWithSource:[NSString stringWithFormat:@";(function(){if(window.XWidget === undefined){window.XWidget = {};window.XWidget.canIUse = function canUseXSL(name) { var registerElements = %@;if (registerElements.indexOf(name) == -1) { return false; } else { return true;}};}})();", keyArrString]
                                                      injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                     forMainFrameOnly:NO];
    [self.configuration.userContentController addUserScript:script];
}

@end

@implementation JDXSLManager

static JDXSLManager *manager = nil;

+ (JDXSLManager *)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [JDXSLManager new];
        [manager readXslRegisteredElement];
    });
    return manager;
}

- (void)initXslManagerWithWebView:(WKWebView*)wKWebView{
    wKWebView.xslElementMap = [NSMutableDictionary dictionary];
    wKWebView.xslIdMap = [NSMutableDictionary dictionary];
    if ([[JDXSLManager shareManager] isHybridXslValid]) {
        [wKWebView addElementAvailableUserScript];
        [[JDXSLManager shareManager] hookWebview];
        [wKWebView addUserScript];
    }
}

- (void)hookWebview{
    static dispatch_once_t hookOnceToken;
    dispatch_once(&hookOnceToken, ^{
        [manager hook];
    });
}

- (void)readXslRegisteredElement{
    uint32_t macho_imageCount = _dyld_image_count();
    for (int image_index = 0; image_index < macho_imageCount; image_index++) {
        const struct mach_header* machHeader = _dyld_get_image_header(image_index);
        NSArray *classList = [self readConfigurationInMacho:JDHybridXSLClassSectName machoHeader:machHeader];
        for (NSString *className in classList) {
            Class cls;
            if (className) {
                cls = NSClassFromString(className);
                if (cls) {
                    [manager registerElementClass:cls];
                }
            }
        }
    }
}

- (NSArray<NSString *>*)readConfigurationInMacho:(char *)sectionName machoHeader:(const struct mach_header *)mhp
{
    NSMutableArray *configs = [NSMutableArray array];
    unsigned long size = 0;
#ifndef __LP64__
    uintptr_t *memory = (uintptr_t*)getsectiondata(mhp, SEG_DATA, sectionName, &size);
#else
    const struct mach_header_64 *mhp64 = (const struct mach_header_64 *)mhp;
    uintptr_t *memory = (uintptr_t*)getsectiondata(mhp64, SEG_DATA, sectionName, &size);
#endif
    unsigned long counter = size/sizeof(void*);
    for(int idx = 0; idx < counter; ++idx){
        char *string = (char*)memory[idx];
        NSString *str = [NSString stringWithUTF8String:string];
        if(!str)continue;
        
        if(str) [configs addObject:str];
    }
    return configs;
}
+ (NSArray*)HybridXslAvailableElement
{
    return [[JDXSLManager shareManager] HybridXslAvailableElement];
}

- (NSArray*)HybridXslAvailableElement
{
    NSMutableArray* availableElementArrs = [NSMutableArray array];
    for (NSString* key in manager.elementsClassMap.allKeys) {
        if ([manager.elementsClassMap[key] isElementValid]) {
            [availableElementArrs addObject:key];
        }
    }
    return availableElementArrs;
}

- (BOOL)isHybridXslValid
{
    BOOL isHybridXslValid = YES;
    if ([JDXSLManager HybridXslAvailableElement].count == 0 || NSClassFromString(@"WKChildScrollView") == nil || NSClassFromString(@"WKCompositingView") == nil) {
        isHybridXslValid = NO;
    }
    return isHybridXslValid;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _elementsClassMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)imp:(id)imp old:(IMP*)old cls:(nonnull Class)cls sel:(nonnull SEL)sel{
    IMP newImp = imp_implementationWithBlock(imp);
    Method method = class_getInstanceMethod(cls, sel);
    * old = (IMP)method_getImplementation(method);
    if (!class_addMethod(cls, sel, newImp, method_getTypeEncoding(method))) {
        *old = (IMP)method_setImplementation(method, newImp);
    }
}

- (void)hook{
    {
        Class cls = NSClassFromString(@"CALayer");
        if (@available(iOS 15.0, *)) {
            cls = NSClassFromString(@"WKCompositingLayer");
        }
        typedef void (* type)(id,SEL,CGRect);
        __block type oldImp  = NULL;
        SEL sel = @selector(setBounds:);
        [self imp:^(CALayer* obj,CGRect frame){
            oldImp(obj,sel,frame);
            if ([obj.delegate isKindOfClass:NSClassFromString(@"WKCompositingView")]) {
                JDXSLBaseElement *element = objc_getAssociatedObject(obj.delegate, hybridXSLElementKey);
                if (element) {
                    element.size = frame.size;
                }
            }
        } old:(IMP*)&oldImp cls:cls sel:sel];
    }
    {
        Class cls = NSClassFromString(@"WKChildScrollView");
        typedef void (* type)(id,SEL,BOOL);
        __block type oldImp  = NULL;
        SEL sel = @selector(setScrollEnabled:);
        [self imp:^(UIScrollView* obj,BOOL isEnable){
            JDXSLBaseElement *element = [self getBindElement:obj.superview name:obj.superview.layer.name];
            if (element) {
                oldImp(obj,sel,NO);
            }else{
                oldImp(obj,sel,isEnable);
            }
        } old:(IMP*)&oldImp cls:cls sel:sel];
    }
    {
        Class cls = NSClassFromString(@"WKChildScrollView");
        typedef void (* type)(id,SEL,CGSize);
        __block type oldImp  = NULL;
        SEL sel = @selector(setContentSize:);
        [self imp:^(UIScrollView* obj,CGSize contentSize){
            oldImp(obj,sel,contentSize);
            JDXSLBaseElement *element = [self getBindElement:obj.superview name:obj.superview.layer.name];
        } old:(IMP*)&oldImp cls:cls sel:sel];
    }
    {
        Class cls = NSClassFromString(@"WKChildScrollView");
        typedef void (* type)(id,SEL);
        __block type oldImp  = NULL;
        SEL sel = @selector(removeFromSuperview);
        [self imp:^(UIView* obj){
            JDXSLBaseElement *element = objc_getAssociatedObject([obj superview], hybridXSLElementKey);
            if (element) {
                element.isAddToSuper = NO;
                [element removeFromSuperView];
            }
            oldImp(obj,sel);
        } old:(IMP*)&oldImp cls:cls sel:sel];
    }
}

- (JDXSLBaseElement *)getBindElement:(UIView *)view name:(NSString *)name{
    if ([view isKindOfClass:NSClassFromString(@"WKCompositingView")] &&  [name containsString:@"class"]) {
        __block JDXSLBaseElement *element = objc_getAssociatedObject(view, hybridXSLElementKey);
        if (element) {
            return element;
        }
        NSArray *divClass = [[[[[name componentsSeparatedByString:@"class="] lastObject] componentsSeparatedByString:@"'"][1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'"]] componentsSeparatedByString:@" "];
        WKWebView *webView = (WKWebView *)view;
        while (webView && ![webView isKindOfClass:[WKWebView class]]) {
            webView = (WKWebView *)webView.superview;
        }
        if (webView == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self getBindElement:view name:name];
            });
            return nil;
        }
        if (!webView.xslElementMap) return nil;
        [divClass enumerateObjectsUsingBlock:^(id  _Nonnull clsName, NSUInteger idx, BOOL * _Nonnull stop) {
            element = webView.xslElementMap[clsName];
            if (element) {
                [element setWebView:webView];
                element.size = view.frame.size;
                objc_setAssociatedObject(view, hybridXSLElementKey, element, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                *stop = YES;
            }
        }];
        [self addElement:element toSuperView:[[view subviews] lastObject]];
        return element;
    }
    return nil;
}

- (void)addElement:(JDXSLBaseElement*)element toSuperView:(UIView *)view{
    if (!element.isAddToSuper && [view isKindOfClass:NSClassFromString(@"WKChildScrollView")]) {
        element.isAddToSuper = YES;
        element.weakWKChildScrollView = view;
        [element addToWKChildScrollView];
    }
}

- (void)registerElementClass:(Class)elementClass {
    if (![elementClass isSubclassOfClass:JDXSLBaseElement.class]) {
        return;
    }
    NSString *elementName = ((id(*)(id,SEL))objc_msgSend)(elementClass,@selector(elementName));
    if (elementName && elementName.length > 1) {
        if (!_elementsClassMap[elementName]) {
            NSString *js = ((id(*)(id,SEL))objc_msgSend)(elementClass,@selector(jsClass));
            if (js.length > 0) {
                _elementsClassMap[elementName] = elementClass;
            }
        }
    }
}

@end



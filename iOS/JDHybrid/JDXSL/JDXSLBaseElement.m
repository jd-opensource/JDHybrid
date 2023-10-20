//
//  JDXSLBaseElement.m
//  JDBHybridModule
//
//  Created by zhoubaoyang on 2022/8/24.
//

#import "JDXSLBaseElement.h"
#import "hybrid_hook_xsl_js.h"
#import <WebKit/WebKit.h>
#import "JDHybridXSLContainerView.h"
#import "JDBridgePluginUtils.h"

@interface JDXSLBaseElement ()

@property (nonatomic, copy) NSDictionary * style;
@property (nonatomic, copy) NSDictionary * xslStyle;

@property (nonatomic, assign) BOOL  rendering;
+ (NSString *)jsClass;

@end

@implementation JDXSLBaseElement

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

+ (NSString *)elementName{
    return nil;
}

+ (BOOL)isElementValid{
    return YES;
}


+ (NSString *)element{
    return nil;
}

- (void)elementConnected {
    
}

- (void)elementRendered{
    
}

- (void)setSize:(CGSize)size{
    _size = size;
    self.containerView.frame = CGRectMake(0, 0, size.width, size.height);
    if (size.height > 0 && !self.rendering) {
        self.rendering = YES;
        [self elementRendered];
    }
}

- (void)setStyleString:(NSString *)style{
    NSArray *styles = [style componentsSeparatedByString:@";"];
    NSMutableDictionary *stylesMap = [NSMutableDictionary dictionary];
    [styles enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *keyValues = [obj componentsSeparatedByString:@":"];
        if (keyValues.count > 1) {
            NSString *key = [keyValues[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (key.length > 0) {
                NSString *value = [keyValues[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if (value.length > 0) {
                    stylesMap[key] = value;
                }
            }
        }
    }];
    
    _style = [NSDictionary dictionaryWithDictionary:stylesMap.copy];
}

- (void)setXSLStyleString:(NSString *)style{
    NSArray *styles = [style componentsSeparatedByString:@";"];
    NSMutableDictionary *stylesMap = [NSMutableDictionary dictionary];
    [styles enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *keyValues = [obj componentsSeparatedByString:@":"];
        if (keyValues.count > 1) {
            NSString *key = [keyValues[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (key.length > 0) {
                NSString *value = [keyValues[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if (value.length > 0) {
                    stylesMap[key] = value;
                }
            }
        }
    }];
    _xslStyle =  [NSDictionary dictionaryWithDictionary:stylesMap.copy];
}

- (void)addToWKChildScrollView{
    [self.weakWKChildScrollView addSubview:self.containerView];
}
- (void)removeFromSuperView{
    [self.containerView removeFromSuperview];
}

- (JDHybridXSLContainerView *)containerView{
    if (!_containerView) {
        _containerView = [[JDHybridXSLContainerView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        if ([self respondsToSelector:@selector(nativeElementInteraction)]) {
            ((JDHybridXSLContainerView*)_containerView).nativeElementInteractionEnabled = [self nativeElementInteraction];
        }
        _containerView.userInteractionEnabled = YES;
    }
    return _containerView;
}

- (void)destroy{
}

static void *JDXSLBaseElementJsKey = &JDXSLBaseElementJsKey;
+ (NSString *)jsClass{
    NSString *js = objc_getAssociatedObject(self, JDXSLBaseElementJsKey);
    if (!js) {
        js = [self createJSClass];
        objc_setAssociatedObject(self, JDXSLBaseElementJsKey, js, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return js;
}
- (void)setWebView:(WKWebView *)webView{
    _webView = webView;
}

+ (NSString *)createJSClass{
    static NSMutableDictionary *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = [NSMutableDictionary dictionary];
    });
    NSString *copyJs;
    if ((copyJs = map[[self elementName]])) {
        return copyJs;
    }
    NSMutableString *js = [NSMutableString stringWithFormat:@"%@", hybrid_hook_xsl_js()];
    NSMutableString *elementClassName = [NSMutableString string];
    [[[self elementName] componentsSeparatedByString:@"-"] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            [elementClassName appendString:[obj capitalizedString]];
        } else {
            [elementClassName appendString:[obj capitalizedString]];
        }
    }];
    [js replaceOccurrencesOfString:@"$ElementName" withString:elementClassName options:0 range:NSMakeRange(0, js.length)];
    [js replaceOccurrencesOfString:@"$Element-Name" withString:[self elementName] options:0 range:NSMakeRange(0, js.length)];
    unsigned int count = 0;
    NSMutableArray *functions = [NSMutableArray array];
    NSMutableArray *observers = [NSMutableArray arrayWithArray:@[@"style", @"xsl_style", @"class",@"hidden",@"hybrid_xsl_id"]];
    Method *methods = class_copyMethodList([self class], &count);
    while (count > 0) {
        count--;
        Method method = methods[count];
        NSString *methodStr = NSStringFromSelector(method_getName(method));
        if ([methodStr hasPrefix:@"xsl__"]) {
            NSString *observerVal = [methodStr substringWithRange:NSMakeRange(5, methodStr.length - 6)];
            NSArray *observerValArr = [observerVal componentsSeparatedByString:@"_"];
            if (observerValArr.count > 1) {
                NSString * newObserver =  [observerValArr componentsJoinedByString:@"-"];
                [observers addObject:newObserver];
            } else {
                if ([self isExistUppercaseString:methodStr].length != 0) {
                    observerVal = [self getSnakeCaseFromCamelCase:observerVal];
                }
            }
            observerVal = [observerVal stringByReplacingOccurrencesOfString:@":callback" withString:@""];
            [observers addObject:observerVal];
        }else if ([methodStr hasPrefix:@"xsl_"]){
            NSString *rm_xsl_str = [methodStr substringWithRange:NSMakeRange(4, methodStr.length - 5)];
            rm_xsl_str = [rm_xsl_str stringByReplacingOccurrencesOfString:@":" withString:@"__"];
            [functions addObject:rm_xsl_str];
        }
    }
        
    [js replaceOccurrencesOfString:@"$obsevers" withString:[observers componentsJoinedByString:@"','"] options:0 range:NSMakeRange(0, js.length)];
    [js replaceOccurrencesOfString:@"$customfunction" withString:[self function:functions] options:0 range:NSMakeRange(0, js.length)];
    copyJs = js.copy;
    free(methods);
    map[[self elementName]] = copyJs;
    return copyJs;
}

+ (NSString *)function:(NSArray *)functions{
    NSMutableString *functionStr = [NSMutableString string];
    [functions enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [functionStr appendFormat:@"\
         %@(params,callbackName,callbackId){\
         this.messageToNative({\
                     methodType:'invokeXslNativeMethod',\
                     methodName:'%@',\
                     args:(params),\
                     callbackName:(callbackName),\
                     callbackId:(callbackId)\
                 })\
            };",obj,obj];
    }];
    return functionStr;
}

+ (NSString *)getSnakeCaseFromCamelCase:(NSString *)oriStr {
    NSMutableString *str = [NSMutableString stringWithString:oriStr];
    
    while ([self isExistUppercaseString:str].length != 0) {
        NSString *upperString = [self isExistUppercaseString:str];
        NSRange range = [str rangeOfString:upperString];
        char c = [str characterAtIndex:range.location];
        [str replaceCharactersInRange:NSMakeRange(range.location, range.length) withString:[[NSString stringWithFormat:@"_%c",c] lowercaseString]];
    }
    return str;
}

/**
 判断是否还存在大写字母
 */
+ (NSString *)isExistUppercaseString:(NSString *)str {
    const char *ch = [str cStringUsingEncoding:NSASCIIStringEncoding];
    NSString *result = @"";
    for (int i = 0; i < str.length; i++) {
        int asciiCode = [str characterAtIndex:i];
        if (asciiCode >= 65 && asciiCode <= 90) {
            result = [NSString stringWithFormat:@"%c", ch[i]];
            return result;
        }
    }
    return result;
}

@end


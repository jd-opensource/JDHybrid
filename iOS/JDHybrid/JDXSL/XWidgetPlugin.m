//
//  XWidgetPlugin.m
//  JDBHybridModule_Example
//
//  Created by zhoubaoyang on 2022/8/17.
//

#import "XWidgetPlugin.h"
#import <objc/message.h>
#import "JDXSLManager.h"
#import "JDBridgePluginUtils.h"

@implementation XWidgetPlugin

- (BOOL)excute:(NSString *)action params:(NSDictionary *)params callback:(JDBridgeCallBack *)jsBridgeCallback {

    [self setXslIdMapDic:params jsBridgeCallback:jsBridgeCallback];
    
    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"%@WithElementId:params:message:",action]);
    if ([self respondsToSelector:sel]) {
        ((void (*)(id,SEL,id,id,id))objc_msgSend)(self,sel,params[@"xsl_id"],params,jsBridgeCallback);
    } else {
        [self invokeXslNativeMethodWithElementId:params[@"xsl_id"] params:params message:jsBridgeCallback];
    }
    return YES;
}

- (void)addXslWithElementId:(NSString *)theId params:(NSDictionary *)params message:(JDBridgeCallBack *)jsBridgeCallback{
    JDXSLBaseElement *element = jsBridgeCallback.message.webView.xslElementMap[theId];
    if (!element) {
        [self createXslWithElementId:theId params:params message:jsBridgeCallback];
        element = jsBridgeCallback.message.webView.xslElementMap[theId];
    }
    [element elementConnected];
}

- (void)createXslWithElementId:(NSString *)theId params:(NSDictionary *)params message:(JDBridgeCallBack *)jsBridgeCallback{
    JDXSLBaseElement *element = [[JDXSLManager shareManager].elementsClassMap[[theId stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]]] new];
    element.class_name = theId;
    NSMutableDictionary* tempDic = [NSMutableDictionary dictionaryWithDictionary:jsBridgeCallback.message.webView.xslElementMap];
    tempDic[theId] = element;
    jsBridgeCallback.message.webView.xslElementMap = tempDic;
}

- (void)invokeXslNativeMethodWithElementId:(NSString *)theId params:(NSDictionary *)params message:(JDBridgeCallBack *)jsBridgeCallback{
    NSString* methodName = params[@"methodName"];
    id argsParams = params[@"args"];
    if (![self validateString:theId] && [self validateString:params[@"hybrid_xsl_id"]]) {
        NSDictionary* xslIdMap = jsBridgeCallback.message.webView.xslIdMap;
        theId = xslIdMap[params[@"hybrid_xsl_id"]];
        methodName = params[@"functionName"];
        argsParams = params;
    }
    
    JDXSLBaseElement *element = jsBridgeCallback.message.webView.xslElementMap[theId];
    SEL sel_callback = NSSelectorFromString([NSString stringWithFormat:@"xsl_callback_%@:",methodName]);
    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"xsl_%@:",methodName]);
    SEL sel_callback_args = NSSelectorFromString([NSString stringWithFormat:@"xsl_callback_%@:callback:",methodName]);
    if ([element respondsToSelector:sel_callback]) {
       [element performSelector:sel_callback withObject:argsParams withObject:jsBridgeCallback];
    } else if ([element respondsToSelector:sel_callback_args]) {
        [element performSelector:sel_callback_args withObject:argsParams withObject:jsBridgeCallback];
    } else if ([element respondsToSelector:sel]){
       ((void (*)(id,SEL,id))objc_msgSend)(element,sel,argsParams);
        if (jsBridgeCallback.onSuccess) {
            jsBridgeCallback.onSuccess([argsParams copy]);
        }
    }
}

- (void)changeXslWithElementId:(NSString *)theId params:(NSDictionary *)params message:(JDBridgeCallBack *)jsBridgeCallback{
    
    NSString *name = params[@"methodName"];
    JDXSLBaseElement *element = jsBridgeCallback.message.webView.xslElementMap[theId];
    if ([name isEqualToString:@"style"]) {
        [element setStyleString:params[@"newValue"]];
    } else if ([name isEqualToString:@"xsl_style"]){
        [element setXSLStyleString:params[@"newValue"]];
    } else {
        SEL sel = NSSelectorFromString([NSString stringWithFormat:@"xsl__%@:",name]);
        
        if (![element respondsToSelector:sel]){
            NSString *newName = @"";
            NSArray *nameArr = [name componentsSeparatedByString:@"-"];
            if (nameArr.count > 1) {
                newName =  [nameArr componentsJoinedByString:@"_"];
                sel = NSSelectorFromString([NSString stringWithFormat:@"xsl__%@:",newName]);
            }
        }
        if (![element respondsToSelector:sel]){
            NSString *newName = @"";
            NSArray *nameArr = [name componentsSeparatedByString:@"_"];
            if (nameArr.count > 1) {
                newName =  [self getCamelCaseFromSnakeCase:name];
                sel = NSSelectorFromString([NSString stringWithFormat:@"xsl__%@:",newName]);
            }
        }
        if ([element respondsToSelector:sel]){
            ((void (*)(id,SEL,id))objc_msgSend)(element,sel,params);
        }
        element.propertValues[name] = params;
        if ([self validateString:params[@"callbackName"]]) {
            // 属性 函数事件
            SEL sel_callback = NSSelectorFromString([NSString stringWithFormat:@"xsl__%@:callback:",name]);
            if ([element respondsToSelector:sel_callback]) {
                [element performSelector:sel_callback withObject:params[@"args"] withObject:jsBridgeCallback];
            }
        }
    }
}
    
- (NSString *)getCamelCaseFromSnakeCase:(NSString *)oriStr {
    NSMutableString *str = [NSMutableString stringWithString:oriStr];
    while ([str containsString:@"_"]) {
        NSRange range = [str rangeOfString:@"_"];
        if (range.location + 1 < [str length]) {
            char c = [str characterAtIndex:range.location+1];
            [str replaceCharactersInRange:NSMakeRange(range.location, range.length+1) withString:[[NSString stringWithFormat:@"%c",c] uppercaseString]];
        }
    }
    return str;
}

- (void)removeXslWithElementId:(NSString *)theId params:(NSDictionary *)params message:(JDBridgeCallBack *)jsBridgeCallback{
    NSMutableDictionary* tempDic = [NSMutableDictionary dictionaryWithDictionary:jsBridgeCallback.message.webView.xslElementMap];
    [tempDic removeObjectForKey:theId];
    jsBridgeCallback.message.webView.xslElementMap = tempDic;
}

- (void)setXslIdMapDic:(NSDictionary *)dic jsBridgeCallback:(JDBridgeCallBack *)jsBridgeCallback {
    NSDictionary* xslIdMap = jsBridgeCallback.message.webView.xslIdMap;
    NSString* hybrid_xsl_id = dic[@"hybrid_xsl_id"];
    NSString* xsl_id = dic[@"xsl_id"];
    if ([self validateString:hybrid_xsl_id] && [self validateString:xsl_id] && ![self validateString:xslIdMap[hybrid_xsl_id]] ) {
        NSMutableDictionary* tempDic = [NSMutableDictionary dictionaryWithDictionary:jsBridgeCallback.message.webView.xslIdMap];
        tempDic[hybrid_xsl_id] = xsl_id;
        jsBridgeCallback.message.webView.xslIdMap = tempDic;
    }
}

- (BOOL)validateString:(NSString *)str {
    return [JDBridgePluginUtils validateString:str];
}

@end



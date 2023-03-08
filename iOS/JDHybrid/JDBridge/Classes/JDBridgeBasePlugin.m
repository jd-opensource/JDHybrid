//
//  JDBridgeBasePlugin.m
/*
 MIT License

Copyright (c) 2022 JD.com, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

#import "JDBridgeBasePlugin.h"
#import "JDBridgePluginUtils.h"
#import "JDBridgeBasePluginPrivate.h"
#import <WebKit/WebKit.h>



@interface JDBridgeCallBack()

@property(nonatomic, weak)WKWebView                     *webview;
/// success block
@property(nonatomic, copy)SuccessCallback               onSuccess;

/// success block with progress
@property(nonatomic, copy)SuccessProgressCallback       onSuccessProgress;

/// fail block, return an error
@property(nonatomic, copy)ErrorCallBack                 onFail;

@end

@implementation JDBridgeCallBack

+ (JDBridgeCallBack *)callback{
    return [JDBridgeCallBack new];
}

- (void)setMessage:(WKScriptMessage *)message{
    _message = message;
    _webview = message.webView;
    __weak JDBridgeCallBack *weakSelf = self;
    self.onSuccess = ^(id arg) {
        __strong __typeof(weakSelf) self = weakSelf;
        [self flushMessageClassMethodWithParams:arg progress:-1.0];
    };
    self.onFail = ^(NSError *error) {
        __strong __typeof(weakSelf) self = weakSelf;
        [self flushMessageClassMethodWithParams:error progress:-1.0];
    };
    
    self.onSuccessProgress = ^(id  _Nonnull arg, float progress) {
        __strong __typeof(weakSelf) self = weakSelf;
        [self flushMessageClassMethodWithParams:arg progress:progress];
    };

}

- (void)flushMessageClassMethodWithParams:(id)data progress:(float)progress{
    NSDictionary *body = self.message.body;
    if (![JDBridgePluginUtils validateDictionary:body]) {
        body = [JDBridgePluginUtils jsonStrToDictionary:(NSString *)body];
    }
    if (![JDBridgePluginUtils validateDictionary:body]) {
        return;
    }
    
    NSString *callbackName = body[KJDBridgeCallbackName]?:@"window.JDBridge && window.JDBridge._handleResponseFromNative && window.JDBridge._handleResponseFromNative";
    NSString *callbackId = body[KJDBridgeCallbackId];
    
    NSString *status = @"0";
    NSString *msg = @"";
    
    NSMutableDictionary *callbackParams = [NSMutableDictionary dictionary];
    if ([data isKindOfClass:[NSError class]]) {
        status = [NSString stringWithFormat:@"%@",@(((NSError*)data).code)];
        msg = ((NSError*)data).description;
    } else {
        if ([data isKindOfClass:[NSNumber class]]) {
            callbackParams[KJDBridgeData] = [NSString stringWithFormat:@"%@",data];
        }  else {
            callbackParams[KJDBridgeData] = data; //we will check the callbackParams valid later.
        }
    }
    callbackParams[KJDBridgeStatus] = status?:@"";
    callbackParams[KJDBridgeMsg] = msg?:@"";
    callbackParams[KJDBridgeCallbackId] = callbackId?:@"";
    if (progress>=0.0) {
        if (progress > 0.999999 && progress < 1.000001) {
            callbackParams[KJDBridgeComplete] = @(YES);
        }
        else{
            callbackParams[KJDBridgeComplete] = @(NO);
        }
        callbackParams[KJDBridgeProgress] = @(progress);
    }
    [self flushData:callbackParams callBackName:callbackName];
}


- (void)flushData:(NSDictionary *)callBackParams callBackName:(NSString *)callBackName{
    if (![NSJSONSerialization isValidJSONObject:callBackParams]) {
        callBackParams = @{KJDBridgeStatus : @(-1), KJDBridgeData : @"", KJDBridgeMsg : @"invalid json object"};
    }
    NSString *callBackString = [NSString stringWithFormat:@"%@(\'%@\')", callBackName, [JDBridgePluginUtils serializeMessage:callBackParams]];
    [self flushMessage:callBackString];
}

- (void)flushMessage:(NSString *)message{
    if (self.webview) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.webview evaluateJavaScript:message completionHandler:^(id  _Nullable obj, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"%@",error.description);
                }
            }];
        });
    }
}

#pragma mark --- return webview controller

- (UIViewController *)webViewController{
    id vc = self.webview;
    while (vc && ![vc isKindOfClass:[UIViewController class]]) {
        vc = [vc nextResponder];
    }
    return [vc isKindOfClass:[UIViewController class]]? vc : nil;
}

@end

@interface JDBridgeBasePlugin()

@end

@implementation JDBridgeBasePlugin

- (BOOL)excute:(NSString *)action
        params:(NSDictionary *)params
      callback:(JDBridgeCallBack *)jsBridgeCallback{
    NSLog(@"subclass should impl");
    return NO;
}

- (BOOL)inValidBridgeCallBack:(JDBridgeCallBack *)jsBridgeCallback message:(NSString *)description{
    if (jsBridgeCallback.onFail) {
        jsBridgeCallback.onFail([NSError errorWithDomain:NSCocoaErrorDomain
                                                    code:-2
                                                userInfo:@{
                                       NSLocalizedDescriptionKey:description?:@""
                               }]);
    }
    return NO;
}


@end

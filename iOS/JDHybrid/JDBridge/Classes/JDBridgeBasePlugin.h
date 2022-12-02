//
//  JDBridgeBasePlugin.h
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

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
NS_ASSUME_NONNULL_BEGIN
typedef void(^SuccessCallback)(id arg);
typedef void(^SuccessProgressCallback)(id arg, float progress);
typedef void(^ErrorCallBack)(NSError *error);

@class JDBridgeCallBack;
@class JDBridgeManager;


/// This is the basic Plugin class , you should inherit it , and implement a sub class
/// eg.
/// if js call an plugin like this:
/// window.XWebView.callNative('TestPlugin','testAction', {"a":12,"c":"d"}, 'callbackName', 'xxxyyyzzz');
/// you should implement an class TestPlugin that inherit JDBridgeBasePlugin
/// and implement method
/// - (BOOL)excute:(NSString *)action params:(NSDictionary *)params callback:(JDBridgeCallBack *)jsBridgeCallback;
/// then you can get params like this：
/// action：“testAction”
/// params： {"a":12,"c":"d"}
/// finally do your job
/// 
@interface JDBridgeBasePlugin : NSObject

/// basic method,
/// @param action action --> method
/// @param params params --> params
/// @param jsBridgeCallback callback context
- (BOOL)excute:(NSString *)action
        params:(NSDictionary *)params
      callback:(JDBridgeCallBack *)jsBridgeCallback;

@end

/// callBack
/// if sucess,  return results else return an error
@interface JDBridgeCallBack : NSObject

@property(nonatomic, strong)WKScriptMessage                                 *message;

/// success block
@property(nonatomic, copy, readonly)SuccessCallback                         onSuccess;

/// success block with progress
@property(nonatomic, copy, readonly)SuccessProgressCallback                 onSuccessProgress;

/// fail block, return an error
@property(nonatomic, copy, readonly)ErrorCallBack                           onFail;

/// return the webviewcontroller
@property(nonatomic, strong, readonly)UIViewController                      *webViewController;

@end


NS_ASSUME_NONNULL_END

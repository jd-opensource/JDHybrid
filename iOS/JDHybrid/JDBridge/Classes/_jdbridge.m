//
//  _JDBridgeplugin.m
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

#import "_jdbridge.h"
#import "JDBridgeManager.h"
#import "JDBridgeManagerPrivate.h"
#import "JDBridgePluginUtils.h"

@interface _jdbridge()

@property(nonatomic, weak)id<JDBridgeInnerProtocol> delegate;

@end

@implementation _jdbridge

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)setJDBridgeDelegate:(id<JDBridgeInnerProtocol>)delegate{
    _delegate = delegate;
}

- (BOOL)excute:(NSString *)action
        params:(NSDictionary *)params
      callback:(JDBridgeCallBack *)jsBridgeCallback{
    if ([action isEqualToString:@"_jsInit"]) {
        if ([self.delegate respondsToSelector:@selector(jsbridgeInit)]) {
            [self.delegate jsbridgeInit];
        }
        return YES;
    }
    if([action isEqualToString:@"_respondFromJs"]){
        if (![JDBridgePluginUtils validateDictionary:params]) {
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Data type not supported"}];
            if ([self.delegate respondsToSelector:@selector(jsbridgeResponseWithCallbackId:params:error:)]) {
                [self.delegate jsbridgeResponseWithCallbackId:nil params:nil error:error];
            }
        }
        NSString *status = params[KJDBridgeStatus];
        NSString *callbackId = params[KJDBridgeCallbackId];

        if ([status isEqualToString:@"0"]) {
            if ([self.delegate respondsToSelector:@selector(jsbridgeResponseWithCallbackId:params:error:)]) {
                [self.delegate jsbridgeResponseWithCallbackId:callbackId params:params error:nil];
            }
        }
        return YES;
    }
    return NO;
}

@end


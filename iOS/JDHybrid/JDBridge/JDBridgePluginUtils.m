//
//  JDBridgePluginUtils.m
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


#import "JDBridgePluginUtils.h"

NSString *KJDBridgeCallbackName      = @"callbackName";
NSString *KJDBridgeCallbackId        = @"callbackId";
NSString *KJDBridgeMethod            = @"method";
NSString *KJDBridgeAction            = @"action";
NSString *KJDBridgeParams            = @"params";
NSString *KJDBridgeMsg               = @"msg";
NSString *KJDBridgeData              = @"data";
NSString *KJDBridgeStatus            = @"status";
NSString *KJDBridgeComplete          = @"complete";
NSString *KJDBridgeProgress          = @"progress";
NSString *KJDBridgePlugin            = @"plugin";


@implementation JDBridgePluginUtils


+ (BOOL)validateString:(NSString *)str{
    if (str && [str isKindOfClass:[NSString class]]) {
        return YES;
    }
    return NO;
}

+ (BOOL)validateDictionary:(NSDictionary *)dict {
    if (dict && [dict isKindOfClass:[NSDictionary class]]){
        return YES;
    }
    return NO;
}

+ (BOOL)validateArray:(NSArray *)array {
    if (array && [array isKindOfClass:[NSArray class]]){
        return YES;
    }
    return NO;
}


+ (nullable NSDictionary *)jsonStrToDictionary:(NSString *)jsonString {
    if ([JDBridgePluginUtils validateString:jsonString]) {
        NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSDictionary *modelInfoDict = [NSJSONSerialization JSONObjectWithData:data
                                                                      options:NSJSONReadingMutableContainers
                                                                        error:&error];
        if (!error) {
            return modelInfoDict;
        }
    }
    return nil;
}

+ (nullable NSString *)serializeMessage:(id)message {
    if (!message || ![NSJSONSerialization isValidJSONObject:message]) {
        return nil;
    }
    NSString *messageJSON = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:0 error:nil] encoding:NSUTF8StringEncoding];

    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    
    return messageJSON;
}

@end

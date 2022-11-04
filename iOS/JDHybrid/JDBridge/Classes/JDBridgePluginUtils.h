//
//  JDBridgePluginUtils.h
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

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *KJDBridgeCallbackName;
FOUNDATION_EXPORT NSString *KJDBridgeCallbackId;
FOUNDATION_EXPORT NSString *KJDBridgeMethod;
FOUNDATION_EXPORT NSString *KJDBridgeAction;
FOUNDATION_EXPORT NSString *KJDBridgeParams;
FOUNDATION_EXPORT NSString *KJDBridgeMsg;
FOUNDATION_EXPORT NSString *KJDBridgeStatus;
FOUNDATION_EXPORT NSString *KJDBridgeComplete;
FOUNDATION_EXPORT NSString *KJDBridgeProgress;
FOUNDATION_EXPORT NSString *KJDBridgeData;
FOUNDATION_EXPORT NSString *KJDBridgePlugin;



@interface JDBridgePluginUtils : NSObject
+ (BOOL)validateString:(NSString *)str;
+ (BOOL)validateDictionary:(NSDictionary *)dict;
+ (BOOL)validateArray:(NSArray *)array;
+ (nullable NSDictionary *)jsonStrToDictionary:(NSString *)jsonString;
+ (nullable NSString *)serializeMessage:(id)message;
@end

NS_ASSUME_NONNULL_END

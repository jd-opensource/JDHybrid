//
//  JDNetworkManager.h
//
//  Created by wangxiaorui19 on 2021/9/28.
//

#import <Foundation/Foundation.h>
#import "JDCacheProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class JDNetworkAsyncOperation;

@interface JDNetworkCallBackWorker : NSObject

@end

typedef NSInteger RequestTaskIdentifier;


@interface JDNetworkManager : NSObject

+ (void)start; // 网络框架预热

+ (instancetype)shareManager;

- (RequestTaskIdentifier)startWithRequest:(NSURLRequest *)request
                         responseCallback:(JDNetResponseCallback)responseCallback
                             dataCallback:(JDNetDataCallback)dataCallback
                          successCallback:(JDNetSuccessCallback)successCallback
                             failCallback:(JDNetFailCallback)failCallback
                         redirectCallback:(JDNetRedirectCallback)redirectCallback ;

- (RequestTaskIdentifier)startWithRequest:(NSURLRequest *)request
                         responseCallback:(JDNetResponseCallback)responseCallback
                         progressCallBack:(nullable JDNetProgressCallBack)progressCallBack
                             dataCallback:(JDNetDataCallback)dataCallback
                          successCallback:(JDNetSuccessCallback)successCallback
                             failCallback:(JDNetFailCallback)failCallback
                         redirectCallback:(JDNetRedirectCallback)redirectCallback ;

- (void)cancelWithRequestIdentifier:(RequestTaskIdentifier)requestTaskIdentifier ;

@end

NS_ASSUME_NONNULL_END

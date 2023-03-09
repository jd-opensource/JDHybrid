
#import <WebKit/WebKit.h>


@interface JDWeakProxy : NSProxy<WKURLSchemeHandler>

@property (nonatomic, weak, readonly, nullable) id target;

- (nonnull instancetype)initWithTarget:(nonnull id)target;
+ (nonnull instancetype)proxyWithTarget:(nonnull id)target;

@end

//
//  JDXSLManager.h
//  JDBHybridModule
//
//  Created by zhoubaoyang on 2022/8/24.
//

#import <WebKit/WebKit.h>
#import "JDXSLBaseElement.h"

NS_ASSUME_NONNULL_BEGIN
@interface JDXSLManager : NSObject

@property (nonatomic, strong) NSMutableDictionary <NSString *,Class>* elementsClassMap;

+ (JDXSLManager *)shareManager;

+ (NSArray*)HybridXslAvailableElement;

- (void)initXslManagerWithWebView:(WKWebView*)wKWebView;

@end

@interface WKWebView (XSL)

@property (nonatomic, strong) NSMutableDictionary* xslElementMap;

@property (nonatomic, strong) NSMutableDictionary* xslIdMap;

@end
NS_ASSUME_NONNULL_END

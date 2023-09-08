//
//  JDXSLBaseElement.h
//  JDBHybridModule
//
//  Created by zhoubaoyang on 2022/8/24.
//

#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

//添加事件
#define XSLFunction(m) -(void)xsl_##m:(id)args
//添加又返回值的事件
// 可变属性
#define XSLFunctionMutableArgsWithCallBack(m) -(void)xsl_callback_##m:(id)args,...
// 带两个参数的 arg  & callback
#define XSLFunctionWithCallBack(m) -(void)xsl_callback_##m:(id)args callback:(JDBridgeCallBack *)callback
//添加属性
#define XSLObserve(att) -(void)xsl__##att:(id)args
//添加带callback属性
#define XSLObserveWithCallBack(att) -(void)xsl__##att:(id)args callback:(JDBridgeCallBack *)callback

@interface JDXSLBaseElement : NSObject

//元素名称 <hybrid-video>
@property (nonatomic, copy, readonly, class) NSString *elementName;
//扩展 元素
@property (nonatomic, copy, readonly, class) NSString *element;

//大小
@property (nonatomic, assign) CGSize size;

//hybrid-video 0
@property (nonatomic, copy) NSString * class_name;

//样式
@property (nonatomic, copy, readonly) NSDictionary * style;
@property (nonatomic, copy, readonly) NSDictionary * xslStyle;

//透明度
@property (nonatomic, assign, readonly) CGFloat opacity;

@property (nonatomic, copy)NSString *border_radius;

//同层渲染对应的 WKChildScrollView
@property (nonatomic, weak) UIView * weakWKChildScrollView;

@property (nonatomic, weak) WKWebView *webView;

@property (nonatomic, strong) UIView *containerView; //在此添加用于同层渲染的view

@property (nonatomic, assign) BOOL isAddToSuper;

//属性列表
@property (nonatomic, strong) NSMutableDictionary * propertValues;

@property (nonatomic, strong) NSString* elementRenderStartTime;

@property (nonatomic, strong) NSString* elementCreateTime;

//同层渲染元素出现
- (void)addToWKChildScrollView;

//同层渲染元素从父view移除
- (void)removeFromSuperView;

- (void)setStyleString:(NSString *)style;
- (void)setXSLStyleString:(NSString *)style;

// element connectedCallback 的native回调，此时elememnt所有的属性已获取
- (void)elementConnected;
- (void)elementRendered;
//原生同层渲染组件是否响应事件，默认关闭
- (BOOL)nativeElementInteraction;

// 原生同层渲染组件是否可用
+ (BOOL)isElementValid;

//销毁
- (void)destroy;

- (NSString *)getCurrentTime;

@end

@interface JDXSLBaseElement (layer)

- (void)setStyle:(id)style value:(id)value target:(id)target;
- (void)setStyle:(id)style target:(id)target;

@end



@interface UIView (XSLUtil)

- (void)xsl_drawCornerRadius:(CGFloat)radius corners:(UIRectCorner)corners;

- (void)xsl_drawCornerRadius:(CGFloat)radius corners:(UIRectCorner)corners frame:(CGRect)frame;

- (void)xsl_setCornerWithTopLeftCorner:(CGFloat)topLeft
                    topRightCorner:(CGFloat)topRight
                  bottomLeftCorner:(CGFloat)bottemLeft
                 bottomRightCorner:(CGFloat)bottemRight;
@end

NS_ASSUME_NONNULL_END

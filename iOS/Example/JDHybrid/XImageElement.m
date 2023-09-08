//
//  XImageElement.m
//  JDBWebViewModule
//
//  Created by niupengfei on 2022/8/30.
//


#import "XImageElement.h"
#import "JDBridgeBasePlugin.h"
#import "JDUtils.h"
#import <SDWebImage/SDWebImage.h>

@interface XImageElement ()
@property (nonatomic, strong)UIImageView  *imageView;
@property (nonatomic, strong)NSDictionary  *modeMap;
@property (nonatomic, strong)NSString *cssMode;
@property (nonatomic, strong)JDBridgeCallBack *onload_callback;
@property (nonatomic, strong)JDBridgeCallBack *onerror_callback;
@property (nonatomic, strong)JDBridgeCallBack *complete_callback;
@property (nonatomic, strong)NSString *src;
@property (nonatomic, strong)NSString *requestSrcStartTime;

@end

@JDHybridXSLRegisterClass(XImageElement)

@implementation XImageElement

+ (NSString *)elementName{
    return @"hybrid-image";
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self.containerView addSubview:self.imageView];
    }
    return self;
}
+ (BOOL)isElementValid{
    BOOL isXSLImageElementInValid = NO;
    return !isXSLImageElementInValid;
}

- (void)setSize:(CGSize)size{
    [super setSize:size];
    self.imageView.frame = CGRectMake(0, 0, size.width, size.height);
    
}

- (void)setStyleString:(NSString *)style{
    [super setStyleString:style];
}

- (void)setXSLStyleString:(NSString *)style{
    [super setXSLStyleString:style];
    [self.xslStyle enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isEqualToString:@"border-radius"]) {
            self.border_radius = obj;
        }
    }];
}

- (void)elementConnected {
    [super elementConnected];
}

- (void)elementRendered{
    [super elementRendered];
    if (!self.src) {
        return;
    }
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:self.src]];
}

- (void)imageRequestSuccessResult:(UIImage *)image{
    NSString *requestSrcSuccessTime = [self getCurrentTime];
    if (self.complete_callback) {
        self.complete_callback.onSuccess(@{@"complete": @(true)});
    }
    if (self.onload_callback != nil && self.onload_callback.onSuccess) {
       NSDictionary *result = @{
           @"naturalWidth": @(image.size.width),
           @"naturalHeight": @(image.size.height),
           @"width": @(self.size.width),
           @"height": @(self.size.height),
           @"requestSrcSuccessTime": requestSrcSuccessTime,
           @"requestSrcStartTime": self.requestSrcStartTime,
       };
        self.onload_callback.onSuccess([result copy]);
    }
}

- (void)imageRequestFailResult:(NSError *)error{
    if (self.onerror_callback != nil && self.onerror_callback.onFail) {
        self.onerror_callback.onFail(error);
    }
    if (self.complete_callback) {
        self.complete_callback.onSuccess(@{@"complete": @(false)});
    }
}

XSLObserveWithCallBack(onload) {
    self.onload_callback = callback;
}

XSLObserveWithCallBack(onerror) {
    self.onerror_callback = callback;
}

XSLObserveWithCallBack(oncomplete) {
    self.complete_callback = callback;
}

// 支持 三种样式 border_radius 、border-radius 、borderRadius 写法
XSLObserve(border_radius){
    NSString* border_radius = args[@"newValue"];
    if (border_radius) {
        [self setStyle:@"border_radius" value:border_radius target:self.imageView];
    }
}

XSLObserve(src) {
    self.requestSrcStartTime = [self getCurrentTime];
    NSString* urlString = args[@"newValue"];
    if (urlString) {
        NSString *newUrlString = [urlString hasPrefix:@"data:"] ? urlString : [urlString hasPrefix:@"http"] ? urlString : [NSString stringWithFormat:@"https:%@",urlString];
        if(self.src && ![self.src isEqualToString:newUrlString]) {
            self.src = newUrlString;
            [self elementRendered];
        } else {
            self.src = newUrlString;
        }
    }
}

XSLObserve(mode){
    NSString* mode = args[@"newValue"];
    if (mode) {
        NSString *midMode = [self modeRegularFilter:mode];
        //不支持
        if([midMode isEqualToString:@"widthFix"] || [midMode isEqualToString:@"heightFix"]) {
            //widthFix 缩放模式，宽度不变，高度自动变化，保持原图宽高比不变
            //heightFix 缩放模式，高度不变，宽度自动变化，保持原图宽高比不变
            self.cssMode = midMode;
            return;
        }
        __block NSInteger currentMode = UIViewContentModeScaleToFill;
        [self.modeMap enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
            if ([key isEqualToString:midMode]) {
                currentMode = [obj integerValue];
                *stop = YES;
            }
        }];
        self.imageView.contentMode = currentMode;
    }
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _imageView.contentMode = UIViewContentModeScaleToFill;
    }
    return _imageView;
}


- (NSDictionary *)modeMap {
    if (!_modeMap) {
        _modeMap = @{
            @"scaleToFill" : @(UIViewContentModeScaleToFill),
            @"aspectFit" : @(UIViewContentModeScaleAspectFit),
            @"aspectFill" : @(UIViewContentModeScaleAspectFill),
            @"top" : @(UIViewContentModeTop),
            @"bottom" : @(UIViewContentModeBottom),
            @"center" : @(UIViewContentModeCenter),
            @"left" : @(UIViewContentModeLeft),
            @"right" : @(UIViewContentModeRight),
            @"topleft" : @(UIViewContentModeTopLeft),
            @"topright" : @(UIViewContentModeTopRight),
            @"bottomleft" : @(UIViewContentModeBottomLeft),
            @"bottomright" : @(UIViewContentModeBottomRight),
         };
    }
    return _modeMap;
}

- (NSString *)modeRegularFilter:(NSString *)mode {
    NSString *resultStr = @"";
    NSString *noBetweenSpaceMode = [mode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSArray *commponets = [noBetweenSpaceMode componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    commponets = [commponets filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self <> ''"]];
    resultStr = [commponets componentsJoinedByString:@""];
    return resultStr;
}


@end


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

@JDHybridXSLRegisterClass(XImageElement)

@interface XImageElement ()
@property (nonatomic, strong)UIImageView  *imageView;
@property (nonatomic, strong)NSString *src;

@end

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

XSLObserve(src) {
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

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _imageView.contentMode = UIViewContentModeScaleToFill;
    }
    return _imageView;
}

@end


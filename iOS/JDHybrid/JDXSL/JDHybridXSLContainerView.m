//
//  JDHybridXSLContainerView.m
//  JDBHybridModule
//
//  Created by zhoubaoyang on 2022/9/9.
//

#import "JDHybridXSLContainerView.h"

@implementation JDHybridXSLContainerView

// JDHybridXSLContainerView conforms protocol WKNativelyInteractible
- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    if (aProtocol == NSProtocolFromString(@"WKNativelyInteractible")) {
        if (self.nativeElementInteractionEnabled) {
            return YES;
        }
    }
    return [super conformsToProtocol:aProtocol];
}

@end

#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "JDHybrid.h"
#import "JDBridgeBasePlugin.h"
#import "JDBridgeManager.h"
#import "JDBridge.h"
#import "XWebViewContainer.h"
#import "XWebView.h"

FOUNDATION_EXPORT double JDHybridVersionNumber;
FOUNDATION_EXPORT const unsigned char JDHybridVersionString[];


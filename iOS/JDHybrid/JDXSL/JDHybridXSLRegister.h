//
//  JDHybridXSLRegister.h
//  JDBHybridModule
//
//  Created by zhoubaoyang on 2022/8/24.
//

#import <Foundation/Foundation.h>

#ifndef JDHybridXSLClassSectName

#define JDHybridXSLClassSectName "JDHybridXSLClass"

#endif

#define JDHybridXSLDATA(sectname) __attribute((used, section("__DATA,"#sectname" ")))

#define JDHybridXSLRegisterClass(name) \
class JDXSLManager; char * k##name##_xsl JDHybridXSLDATA(JDHybridXSLClass) = ""#name"";

@interface JDHybridXSLRegister : NSObject

@end

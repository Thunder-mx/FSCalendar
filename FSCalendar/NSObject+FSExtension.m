//
//  NSObject+FSExtension.m
//  FSCalendar
//
//  Created by dingwenchao on 9/13/16.
//  Copyright © 2016 wenchaoios. All rights reserved.
//

#import "NSObject+FSExtension.h"

@implementation NSObject (FSExtension)

- (id)fs_performSelector:(SEL)selector withObjects:(nullable id)firstObject, ...
{
    if (!selector) return nil;
    NSMethodSignature *signature = [self methodSignatureForSelector:selector];
    if (!signature) return nil;
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    if (!invocation) return nil;
    invocation.target = self;
    invocation.selector = selector;
    
    // Parameters
    if (firstObject) {
        int index = 2;
        va_list args;
        va_start(args, firstObject);
        if (firstObject) {
            id obj = firstObject;
            do {
                const char *argType = [signature getArgumentTypeAtIndex:index];
                if(!strcmp(argType, @encode(id))){
                    // object
                    [invocation setArgument:&obj atIndex:index++];
                } else {
                    NSString *argTypeString = [NSString stringWithUTF8String:argType];
                    if ([argTypeString hasPrefix:@"{"] && [argTypeString hasSuffix:@"}"]) {
                        // struct
#define PARAM_STRUCT_TYPES(_type,_getter,_default) \
if (!strcmp(argType, @encode(_type))) { \
    _type value = [obj respondsToSelector:@selector(_getter)]?[obj _getter]:_default; \
    [invocation setArgument:&value atIndex:index++]; \
}
    PARAM_STRUCT_TYPES(CGPoint, CGPointValue, CGPointZero)
    PARAM_STRUCT_TYPES(CGSize, CGSizeValue, CGSizeZero)
    PARAM_STRUCT_TYPES(CGRect, CGRectValue, CGRectZero)
    PARAM_STRUCT_TYPES(CGAffineTransform, CGAffineTransformValue, CGAffineTransformIdentity)
    PARAM_STRUCT_TYPES(CATransform3D, CATransform3DValue, CATransform3DIdentity)
    PARAM_STRUCT_TYPES(CGVector, CGVectorValue, CGVectorMake(0, 0))
    PARAM_STRUCT_TYPES(UIEdgeInsets, UIEdgeInsetsValue, UIEdgeInsetsZero)
    PARAM_STRUCT_TYPES(UIOffset, UIOffsetValue, UIOffsetZero)
    PARAM_STRUCT_TYPES(NSRange, rangeValue, NSMakeRange(NSNotFound, 0))
#undef PARAM_STRUCT_TYPES
                    } else {
                        // basic type
#define PARAM_BASIC_TYPES(_type,_getter) \
if (!strcmp(argType, @encode(_type))) { \
    _type value = [obj respondsToSelector:@selector(_getter)]?[obj _getter]:0; \
    [invocation setArgument:&value atIndex:index++]; \
}
    PARAM_BASIC_TYPES(BOOL, boolValue)
    PARAM_BASIC_TYPES(int, intValue)
    PARAM_BASIC_TYPES(unsigned int, unsignedIntValue)
    PARAM_BASIC_TYPES(char, charValue)
    PARAM_BASIC_TYPES(unsigned char, unsignedCharValue)
    PARAM_BASIC_TYPES(long, longValue)
    PARAM_BASIC_TYPES(unsigned long, unsignedLongValue)
    PARAM_BASIC_TYPES(long long, longLongValue)
    PARAM_BASIC_TYPES(unsigned long long, unsignedLongLongValue)
    PARAM_BASIC_TYPES(float, floatValue)
    PARAM_BASIC_TYPES(double, doubleValue)
#undef PARAM_BASIC_TYPES
                    }
                }
            } while((obj = va_arg(args, id)));
            
        }
        va_end(args);
        [invocation retainArguments];
    }
    
    // Execute
    [invocation invoke];
    
    // Return
    const char *returnType = signature.methodReturnType;
    NSUInteger length = [signature methodReturnLength];
    id returnValue;
    if (!strcmp(returnType, @encode(void))){
        // void
        returnValue = nil;
    } else if(!strcmp(returnType, @encode(id))){
        // id
        void *value;
        [invocation getReturnValue:&value];
        returnValue = (__bridge id)(value);
        return returnValue;
    } else {
        NSString *returnTypeString = [NSString stringWithUTF8String:returnType];
        if ([returnTypeString hasPrefix:@"{"] && [returnTypeString hasSuffix:@"}"]) {
            // struct
#define RETURN_STRUCT_TYPES(_type) \
            if (!strcmp(returnType, @encode(_type))) { \
                _type value; \
                [invocation getReturnValue:&value]; \
                returnValue = [NSValue value:&value withObjCType:@encode(_type)]; \
            }
            RETURN_STRUCT_TYPES(CGPoint)
            RETURN_STRUCT_TYPES(CGSize)
            RETURN_STRUCT_TYPES(CGRect)
            RETURN_STRUCT_TYPES(CGAffineTransform)
            RETURN_STRUCT_TYPES(CATransform3D)
            RETURN_STRUCT_TYPES(CGVector)
            RETURN_STRUCT_TYPES(UIEdgeInsets)
            RETURN_STRUCT_TYPES(UIOffset)
            RETURN_STRUCT_TYPES(NSRange)
#undef RETURN_STRUCT_TYPES
        } else {
            // basic
            void *buffer = (void *)malloc(length);
            [invocation getReturnValue:buffer];
#define RETURN_BASIC_TYPES(_type) \
if (!strcmp(returnType, @encode(_type))) { \
    returnValue = @(*((_type*)buffer)); \
}
            RETURN_BASIC_TYPES(BOOL)
            RETURN_BASIC_TYPES(int)
            RETURN_BASIC_TYPES(unsigned int)
            RETURN_BASIC_TYPES(char)
            RETURN_BASIC_TYPES(unsigned char)
            RETURN_BASIC_TYPES(long)
            RETURN_BASIC_TYPES(unsigned long)
            RETURN_BASIC_TYPES(long long)
            RETURN_BASIC_TYPES(unsigned long long)
            RETURN_BASIC_TYPES(float)
            RETURN_BASIC_TYPES(double)
#undef RETURN_BASIC_TYPES
        }
    }
    return returnValue;
}

@end

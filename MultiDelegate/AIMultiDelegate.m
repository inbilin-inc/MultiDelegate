//  Created by Alejandro Isaza on 13-03-18.
//  Copyright (c) 2013 Alejandro Isaza. All rights reserved.

#import "AIMultiDelegate.h"


@implementation AIMultiDelegate {
    NSPointerArray* _delegates;
}

- (id)init {
    return [self initWithDelegates:nil];
}

- (id)initWithDelegates:(NSArray*)delegates {
    self = [super init];
    if (!self)
        return nil;

    _delegates = [NSPointerArray weakObjectsPointerArray];
    for (id delegate in delegates)
        [_delegates addPointer:(__bridge void*)delegate];
    
    return self;
}

- (void)addDelegate:(id)delegate {
    if ([self indexOfDelegate:delegate] == NSNotFound) {
       [_delegates addPointer:(__bridge void*)delegate];
    }
}

- (NSUInteger)indexOfDelegate:(id)delegate {
    for (NSUInteger i = 0; i < _delegates.count; i += 1) {
        if ([_delegates pointerAtIndex:i] == (__bridge void*)delegate) {
            return i;
        }
    }
    return NSNotFound;
}

- (void)addDelegate:(id)delegate beforeDelegate:(id)otherDelegate {
    NSUInteger index = [self indexOfDelegate:otherDelegate];
    if (index == NSNotFound)
        index = _delegates.count;
    [_delegates insertPointer:(__bridge void*)delegate atIndex:index];
}

- (void)addDelegate:(id)delegate afterDelegate:(id)otherDelegate {
    NSUInteger index = [self indexOfDelegate:otherDelegate];
    if (index == NSNotFound)
        index = 0;
    else
        index += 1;
    [_delegates insertPointer:(__bridge void*)delegate atIndex:index];
}

- (void)removeDelegate:(id)delegate {
    NSUInteger index = [self indexOfDelegate:delegate];
    if (index != NSNotFound)
        [_delegates removePointerAtIndex:index];
}

- (void)removeAllDelegates {
    for (NSUInteger i = _delegates.count; i > 0; i -= 1)
        [_delegates removePointerAtIndex:i - 1];
}

- (BOOL)respondsToSelector:(SEL)selector {
    if ([super respondsToSelector:selector])
        return YES;
    
    NSPointerArray *tempDelegates = [_delegates copy];
    for (id delegate in tempDelegates) {
        if (delegate && [delegate respondsToSelector:selector])
            return YES;
    }
    
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    NSMethodSignature* signature = [super methodSignatureForSelector:selector];
    if (signature)
        return signature;
    
    if (self.silentWhenEmpty && _delegates.count == 0) {
        // return any method signature, it doesn't really matter
        return [self methodSignatureForSelector:@selector(description)];
    }
    
    NSPointerArray *tempDelegates = [_delegates copy];
    for (id delegate in tempDelegates) {
        if (!delegate)
            continue;

        signature = [delegate methodSignatureForSelector:selector];
        if (signature)
            break;
    }
    
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL selector = [invocation selector];
    BOOL responded = NO;
    
    NSPointerArray *tempDelegates = [_delegates copy];
    for (id delegate in tempDelegates) {
        if (delegate && [delegate respondsToSelector:selector]) {
            [invocation invokeWithTarget:delegate];
            responded = YES;
        }
    }
    
    if (!responded && !self.silentWhenEmpty)
        [self doesNotRecognizeSelector:selector];
}

@end



#import "CDBDelegateReference.h"

@implementation CDBDelegateReference

#pragma mark - Life cycle -

+ (instancetype)withDelegate:(id<NSObject>)delegate {
    CDBDelegateReference *result = [CDBDelegateReference new];
    result.delegate = delegate;
    
    return result;
}

#pragma mark - Private -

#pragma mark Description

- (NSString *)description {
    NSString *result = [NSString stringWithFormat:@"reference %@:\
                        \n => %@",
                        [super description], self.delegate];
    return result;
}

#pragma mark Equality

- (NSUInteger)hash {
    NSUInteger result = self.delegate.hash;
    return result;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]] == NO) {
        return NO;
    }
    
    BOOL result = [self isEqualToDelegateReference:(CDBDelegateReference *)object];
    
    return result;
}

- (BOOL)isEqualToDelegateReference:(CDBDelegateReference *)reference {
    if (reference.delegate == nil) {
        return NO;
    }
    
    if ([self.delegate isEqual:reference.delegate] == NO) {
        return NO;
    }
    
    return YES;
}

@end



#import "CDBDelegateCollection.h"
#import "CDBDelegateReference.h"


@interface CDBDelegateCollection ()

@property (strong, nonatomic, readwrite) Protocol *comformsToProtocol;
@property (strong, nonatomic) NSMutableSet *delegates;

@end


@implementation CDBDelegateCollection

#pragma mark - Life cycle -

- (instancetype)initWithProtocol:(Protocol *)protocol {
    self = [super init];
    if (self) {
        _comformsToProtocol = protocol;
    }
    return self;
}

#pragma mark - Public -

- (BOOL)addDelegate:(id)delegate {
    if (delegate == nil) {
        return  NO;
    }
    
    if (self.comformsToProtocol != nil &&
        [delegate conformsToProtocol:self.comformsToProtocol] == NO) {
        return NO;
    }
    
    CDBDelegateReference *reference = [CDBDelegateReference withDelegate:delegate];
    [self.delegates addObject:reference];

    return YES;
}

- (void)removeDelegate:(id)delegate {
    if (delegate == nil) {
        return;
    }

    CDBDelegateReference *reference = [CDBDelegateReference withDelegate:delegate];
    [self.delegates removeObject:reference];
}

- (void)enumerateDelegatesRespondToSelector:(SEL)selector
                                 usingBlock:(void (^)(id<NSObject>, BOOL *))block {
    if (block == nil) {
        return;
    }

    NSSet *enumeratedDelegates = [self.delegates copy];
    NSMutableSet *nilDelegateReferences = [NSMutableSet set];
    
    for (CDBDelegateReference *delegateReference in enumeratedDelegates) {
        id delegate = delegateReference.delegate;
        
        if (delegate == nil) {
            [nilDelegateReferences addObject:delegateReference];
            continue;
        }
        
        if ([delegate respondsToSelector:selector] == NO) {
            continue;
        }
        
        BOOL stop = NO;
        
        block(delegate, &stop);
        
        if (stop) {
            break;
        }
    }
    
    [self.delegates minusSet:nilDelegateReferences];
}


#pragma mark - Private -

- (NSString *)description {
    NSString *result = [NSString stringWithFormat:@"%@ \
                        \n protocol: %@\
                        \n delegates count %@: ",
                        [super description],
                        NSStringFromProtocol(self.comformsToProtocol),
                        @(self.delegates.count)];
    
    for (CDBDelegateReference *delegateReference in self.delegates) {
        result = [result stringByAppendingFormat:@"\n %@", delegateReference];
    }
    
    return result;
}

#pragma mark - Property -

#pragma mark Lazy loading

- (NSMutableSet *)delegates {
    if (_delegates == nil) {
        _delegates = [NSMutableSet set];
    }
    return _delegates;
}

@end

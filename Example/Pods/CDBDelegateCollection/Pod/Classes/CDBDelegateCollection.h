

#if __has_feature(objc_modules)
    @import Foundation;
#else
    #import <Foundation/Foundation.h>
#endif


@interface CDBDelegateCollection : NSObject

@property (strong, nonatomic, readonly) Protocol * comformsToProtocol;

- (instancetype)initWithProtocol:(Protocol *)protocol;

- (BOOL)addDelegate:(id<NSObject>)delegate;
- (void)removeDelegate:(id<NSObject>)delegate;

- (void)enumerateDelegatesRespondToSelector:(SEL)selector
                                 usingBlock:(void(^)(id<NSObject> delegate, BOOL * stop))block;

@end

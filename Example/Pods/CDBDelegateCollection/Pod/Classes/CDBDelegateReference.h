

#if __has_feature(objc_modules)
    @import Foundation;
#else
    #import <Foundation/Foundation.h>
#endif


@interface CDBDelegateReference : NSObject

@property (weak, nonatomic) id<NSObject> delegate;

+ (instancetype)withDelegate:(id<NSObject>)delegate;

@end

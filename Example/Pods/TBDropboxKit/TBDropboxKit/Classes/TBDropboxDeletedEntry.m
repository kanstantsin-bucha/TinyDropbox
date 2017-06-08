//
//  TBDropboxDeletedEntry.m
//  Pods
//
//  Created by Bucha Kanstantsin on 3/13/17.
//
//

#import "TBDropboxDeletedEntry+Private.h"

@implementation TBDropboxDeletedEntry

@synthesize fileName;

/// MARK: property

- (NSString *)readablePath {
    NSString * result = self.dropboxPath;
    return result;
}

/// MARK: life cycle

- (instancetype)initInstance {
    self = [super init];
    if (self) {
    }
    return self;
}

- (NSString *)description {
    NSString * result = [NSString stringWithFormat:@"%@ %@\r path: %@,\r%@",
                         NSStringFromClass([self class]),
                         StringFromDropboxEntrySource(self.source),
                         self.dropboxPath,
                         self.metadata.description];
    return result;
}

@end

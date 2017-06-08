//
//  TBDropboxEntry.m
//  Pods
//
//  Created by Bucha Kanstantsin on 12/31/16.
//
//

#import "TBDropboxFileEntry+Private.h"


@interface TBDropboxFileEntry ()

@end


@implementation TBDropboxFileEntry

/// MARK: property

- (NSString *)fileName {
    NSString * result = self.dropboxPath.lastPathComponent;
    return result;
}

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

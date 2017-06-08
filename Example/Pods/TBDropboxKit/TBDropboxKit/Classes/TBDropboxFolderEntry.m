//
//  TBDropboxFolderEntry.m
//  Pods
//
//  Created by Bucha Kanstantsin on 2/6/17.
//
//

#import "TBDropboxFolderEntry.h"
#import "TBDropboxFolderEntry+Private.h"
#import "TBDropboxEntryFactory.h"



@interface TBDropboxFolderEntry ()


@end


@implementation TBDropboxFolderEntry

/// MARK: property

- (NSString *)fileName {
    NSString * result = self.dropboxPath.lastPathComponent;
    return result;
}

- (NSString *)readablePath {
    BOOL isRoot =
        [self.dropboxPath isEqualToString: TBDropboxFolderEntry_Root_Folder_Path];
    NSString * result = isRoot ? @"ROOT"
                               : self.dropboxPath;
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
    NSString * result =
        [NSString stringWithFormat:@"%@ %@\
                                    \r Path: %@,\
                                    \r %@",
                         NSStringFromClass([self class]),
                         StringFromDropboxEntrySource(self.source),
                         self.readablePath,
                         self.metadata.description];
    return result;
}

@end

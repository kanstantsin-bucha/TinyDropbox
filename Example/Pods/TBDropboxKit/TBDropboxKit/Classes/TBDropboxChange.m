//
//  TBDropboxChange.m
//  Pods
//
//  Created by Bucha Kanstantsin on 3/15/17.
//
//

#import "TBDropboxChange.h"


@interface TBDropboxChange ()

@property (strong, nonatomic, readwrite, nonnull) NSString * dropboxPath;
@property (assign, nonatomic, readwrite) TBDropboxChangeAction action;
@property (strong, nonatomic, readwrite, nonnull) DBFILESMetadata * metadata;

@end


@implementation TBDropboxChange

/// MARK: - life cycle -

- (instancetype)initInstance {
    self = [super init];
    if (self) {
    }
    return self;
}

+ (instancetype)changeUsingMetadata:(DBFILESMetadata *)metadata {
    if (metadata == nil) {
        return nil;
    }
    
    TBDropboxChange * result = [[[self class] alloc] initInstance];
    result.dropboxPath = metadata.pathDisplay;
    result.metadata = metadata;
    
    Class metadataClass = [metadata class];
    if ([DBFILESFileMetadata class] == metadataClass) {
        result.action = TBDropboxChangeActionUpdateFile;
    }
    if ([DBFILESFolderMetadata class] == metadataClass) {
        result.action = TBDropboxChangeActionUpdateFolder;
    }
    if ([DBFILESDeletedMetadata class] == metadataClass) {
        result.action = TBDropboxChangeActionDelete;
    }
    
    if (result.action == TBDropboxChangeActionUndefined) {
        NSLog(@"Dropbox FAILED TBDropboxChange acquire unexpected metadata class");
        return nil;
    }
    
    return result;
}

/// MARK: - public -

- (NSURL *)localURLUsingBaseURL:(NSURL *)baseURL {
    NSString * path = self.dropboxPath.length > 0 ? [self.dropboxPath substringFromIndex:1]
                                                  : self.dropboxPath;
    NSURL * result = [baseURL URLByAppendingPathComponent: path];
    return result;
}

/// MARK: - private -

- (NSString *)description {
    NSString * result = [NSString stringWithFormat:@"%@ <%@> \
                                                    \r %@ %@",
                         NSStringFromClass([self class]), @(self.hash),
                         self.dropboxPath,
                         StringFromDropboxChangeAction(self.action)];
    return result;
}

@end

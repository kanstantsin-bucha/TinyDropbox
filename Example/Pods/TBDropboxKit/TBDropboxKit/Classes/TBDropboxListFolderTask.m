//
//  TBDropboxListTask.m
//  Pods
//
//  Created by Bucha Kanstantsin on 2/6/17.
//
//

#import "TBDropboxListFolderTask.h"
#import "TBDropboxTask+Private.h"
#import "TBDropboxFolderEntry+Private.h"
#import "TBDropboxEntryFactory.h"


@interface TBDropboxListFolderTask ()

@property (strong, nonatomic, readwrite, nonnull) TBDropboxFolderEntry * entry;

@property (strong, nonatomic, readwrite, nullable) TBDropboxCursor * cursor;
@property (strong, nonatomic, readwrite, nullable) NSArray<id<TBDropboxEntry>> * folderEntries;
@property (strong, nonatomic, readwrite, nullable) NSMutableArray<DBFILESMetadata *> * incomingMetadata;

@end


@implementation TBDropboxListFolderTask

@synthesize entry;

/// MAKR: property

- (NSArray<id<TBDropboxEntry>> *)folderEntries {
    if (_folderEntries != nil) {
        return _folderEntries;
    }
    
    _folderEntries = [TBDropboxEntryFactory entriesUsingMetadata: self.folderMetadata];
    return _folderEntries;
}

- (NSArray<DBFILESMetadata *> *)folderMetadata {
    NSArray * result = [self.incomingMetadata copy];
    return result;
}

- (NSMutableArray<DBFILESMetadata *> *)incomingMetadata {
    if (_incomingMetadata != nil) {
        return _incomingMetadata;
    }
    
    _incomingMetadata = [NSMutableArray array];
    return _incomingMetadata;
}

/// MARK: life cycle

+ (instancetype)taskUsingEntry:(TBDropboxFolderEntry *)entry
                    completion:(TBDropboxTaskCompletion)completion {
    if (entry == nil
        || completion == nil) {
        return nil;
    }
    
    TBDropboxListFolderTask * result = [[[self class] alloc] initInstance];
    result.completion = completion;
    result.state = TBDropboxTaskStateReady;
    result.type = TBDropboxTaskTypeRequestInfo;
    result.entry = entry;
    return result;
}

+ (instancetype)taskUsingCursor:(NSString *)cursor
                    completion:(TBDropboxTaskCompletion)completion {
    if (cursor == nil
        || completion == nil) {
        return nil;
    }
    
    TBDropboxListFolderTask * result = [[[self class] alloc] initInstance];
    result.completion = completion;
    result.state = TBDropboxTaskStateReady;
    result.type = TBDropboxTaskTypeRequestInfo;
    result.cursor = cursor;
    return result;
}

/// MARK: override

- (void)performMainUsingRoutes:(DBFILESUserAuthRoutes *)routes
                withCompletion:(CDBErrorCompletion)completion {
    if (self.entry != nil) {
        self.dropboxTask = [routes listFolder: self.entry.dropboxPath
                                    recursive: @(self.recursive)
                             includeMediaInfo: @(self.includeMediaInfo)
                               includeDeleted: @(self.includeDeleted)
              includeHasExplicitSharedMembers: @(self.includeHasExplicitSharedMembers)];
    } else {
        self.dropboxTask = [routes listFolderContinue: self.cursor];
    }

    weakCDB(wself);
    [(DBRpcTask *)self.dropboxTask setResponseBlock: ^(DBFILESListFolderResult * _Nullable response,
                                                       DBFILESListFolderError * _Nullable folderError,
                                                       DBRequestError * _Nullable requestError) {
        NSError * error = [wself composeErrorUsingRequestError: requestError
                                              taskRelatedError: folderError];

        if (error != nil) {
            completion(error);
            return;
        }
            
        wself.cursor = response.cursor;
        if (response.entries != nil) {
            [wself.incomingMetadata addObjectsFromArray: response.entries];
        }
        
        if (response.hasMore.boolValue) {
            [wself performMainUsingRoutes: routes
                           withCompletion: completion];
        }
        
        completion(error);
    }];
    
    [self.dropboxTask start];
}

- (NSString *)description {
    NSString * properties = @"";
    if (self.entry != nil) {
        properties = [properties stringByAppendingFormat:@"Path: %@", self.entry.readablePath];
    }
    if (self.cursor != nil) {
        properties = [properties stringByAppendingFormat:@"Cursor: %@", self.cursor];
    }
    NSString * result =
        [NSString stringWithFormat:@"%@ <%@>\r %@\r %@",
                                   NSStringFromClass([self class]),@(self.hash),
                                   StringFromDropboxTaskState(self.state), properties];
    return result;
}


@end

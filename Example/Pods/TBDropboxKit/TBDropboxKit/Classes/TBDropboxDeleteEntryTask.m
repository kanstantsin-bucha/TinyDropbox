//
//  TBDropboxDeleteEntryTask.m
//  Pods
//
//  Created by Bucha Kanstantsin on 3/9/17.
//
//

#import "TBDropboxDeleteEntryTask.h"
#import "TBDropboxTask+Private.h"
#import "TBDropboxEntryFactory.h"


@interface TBDropboxDeleteEntryTask ()


@end


@implementation TBDropboxDeleteEntryTask


+ (instancetype)taskUsingEntry:(id<TBDropboxEntry>)entry
                    completion:(TBDropboxTaskCompletion)completion {
    if (entry == nil
        || completion == nil) {
        return nil;
    }
    
    TBDropboxDeleteEntryTask * result = [[[self class] alloc] initInstance];
    result.completion = completion;
    result.entry = entry;
    result.state = TBDropboxTaskStateReady;
    result.type = TBDropboxTaskTypeUploadChanges;
    return result;
}

/// MARK: override

- (void)performMainUsingRoutes:(DBFILESUserAuthRoutes *)routes
                withCompletion:(CDBErrorCompletion)completion {
    
    self.dropboxTask = [routes delete_V2: self.entry.dropboxPath];
    weakCDB(wself);
    [(DBRpcTask *)self.dropboxTask setResponseBlock: ^(DBFILESDeleteResult * result,
                                                       id  _Nullable routeError,
                                                       DBRequestError * _Nullable requestError) {
        NSError * error = [wself composeErrorUsingRequestError: requestError
                                              taskRelatedError: routeError];
        if (error != nil) {
            completion(error);
            return;
        }
        
        DBFILESMetadata *resultMetadata = result.metadata;
        // we create this because it help to proceed with group of different tasks in queue
        // we determine a change (delete/create) based on a type of a metadata object
        DBFILESDeletedMetadata * metadata =
            [[DBFILESDeletedMetadata alloc] initWithName:resultMetadata.name
                                               pathLower:resultMetadata.pathLower
                                             pathDisplay:resultMetadata.pathDisplay
                                    parentSharedFolderId:resultMetadata.parentSharedFolderId];
        id<TBDropboxEntry> metadataEntry =
            [TBDropboxEntryFactory entryUsingMetadata: metadata];
        if (metadataEntry != nil) {
            wself.entry = metadataEntry;
        }
            
        completion(error);
    }];
    
    [self.dropboxTask start];
}

@end

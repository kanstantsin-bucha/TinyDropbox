//
//  TBDropboxDownloadFileTask.m
//  Pods
//
//  Created by Bucha Kanstantsin on 3/6/17.
//
//

#import "TBDropboxDownloadFileTask.h"
#import "TBDropboxTask+Private.h"


@interface TBDropboxDownloadFileTask ()

@property (strong, nonatomic, readwrite, nonnull) NSURL * fileURL;

@end


@implementation TBDropboxDownloadFileTask

+ (instancetype)taskUsingEntry:(TBDropboxFileEntry *)entry
                       fileURL:(NSURL *)fileURL
                    completion:(TBDropboxTaskCompletion)completion {
    if (entry == nil
        || fileURL == nil
        || completion == nil) {
        return nil;
    }
    
    TBDropboxDownloadFileTask * result = [[[self class] alloc] initInstance];
    result.completion = completion;
    result.entry = entry;
    result.fileURL = fileURL;
    result.state = TBDropboxTaskStateReady;
    result.type = TBDropboxTaskTypeRequestInfo;
    return result;
}

/// MARK: override

- (void)performMainUsingRoutes:(DBFILESUserAuthRoutes *)routes
                withCompletion:(CDBErrorCompletion)completion {
    self.dropboxTask = [routes downloadUrl: self.entry.dropboxPath
                                 overwrite: YES
                               destination: self.fileURL];
    weakCDB(wself);
    [(DBUploadTask *)self.dropboxTask setResponseBlock:^(id  _Nullable response,
                                                         id  _Nullable routeError,
                                                         DBRequestError * _Nullable requestError) {
        NSError * error = [wself composeErrorUsingRequestError: requestError
                                              taskRelatedError: routeError];
        completion(error);
    }];
    
    [self.dropboxTask start];
}


@end

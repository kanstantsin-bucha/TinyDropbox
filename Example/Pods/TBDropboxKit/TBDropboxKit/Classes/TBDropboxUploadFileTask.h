//
//  TBDropboxFileUploadTask.h
//  Pods
//
//  Created by Bucha Kanstantsin on 3/6/17.
//
//

#import <Foundation/Foundation.h>
#import "TBDropboxTask.h"
#import "TBDropboxFileEntry.h"


@interface TBDropboxUploadFileTask : TBDropboxTask

@property (strong, nonatomic, readonly, nonnull) NSURL * fileURL;

+ (instancetype _Nullable)taskUsingEntry:(TBDropboxFileEntry * _Nonnull)entry
                                 fileURL:(NSURL * _Nonnull)fileURL
                              completion:(TBDropboxTaskCompletion _Nonnull)completion;

+ (instancetype _Nonnull)new __unavailable;
- (id _Nonnull) init __unavailable;

@end

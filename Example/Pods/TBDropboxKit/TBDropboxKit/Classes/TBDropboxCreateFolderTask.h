//
//  TBDropboxCreateFolderTask.h
//  Pods
//
//  Created by Bucha Kanstantsin on 3/6/17.
//
//

#import <Foundation/Foundation.h>
#import "TBDropboxTask.h"
#import "TBDropboxFolderEntry.h"


@interface TBDropboxCreateFolderTask : TBDropboxTask

@property (strong, nonatomic, readonly, nonnull) TBDropboxFolderEntry * entry;

+ (instancetype _Nullable)taskUsingEntry:(TBDropboxFolderEntry * _Nonnull)entry
                              completion:(TBDropboxTaskCompletion _Nonnull)completion;

+ (instancetype _Nonnull)new __unavailable;
- (id _Nonnull) init __unavailable;

@end

//
//  TBDropboxMoveEntryTask.h
//  Pods
//
//  Created by Bucha Kanstantsin on 3/11/17.
//
//

#import <TBDropboxKit/TBDropboxKit.h>
#import "TBDropboxEntry.h"

@interface TBDropboxMoveEntryTask : TBDropboxTask

@property (strong, nonatomic, readonly, nonnull) id<TBDropboxEntry> destinationEntry;

+ (instancetype _Nullable)taskUsingEntry:(id<TBDropboxEntry> _Nonnull)entry
                        destinationEntry:(id<TBDropboxEntry> _Nonnull)destinationEntry
                              completion:(TBDropboxTaskCompletion _Nonnull)completion;

+ (instancetype _Nonnull)new __unavailable;
- (id _Nonnull) init __unavailable;

@end

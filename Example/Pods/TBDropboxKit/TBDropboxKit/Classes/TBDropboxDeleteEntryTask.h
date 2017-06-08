//
//  TBDropboxDeleteEntryTask.h
//  Pods
//
//  Created by Bucha Kanstantsin on 3/9/17.
//
//

#import "TBDropboxEntry.h"
#import "TBDropboxTask.h"
#import "TBDropbox.h"

@interface TBDropboxDeleteEntryTask : TBDropboxTask

+ (instancetype _Nullable)taskUsingEntry:(id<TBDropboxEntry> _Nonnull)entry
                              completion:(TBDropboxTaskCompletion _Nonnull)completion;

+ (instancetype _Nonnull)new __unavailable;
- (id _Nonnull) init __unavailable;

@end

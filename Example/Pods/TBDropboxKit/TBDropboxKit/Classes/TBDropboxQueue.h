//
//  TBDropboxQueue.h
//  Pods
//
//  Created by Bucha Kanstantsin on 2/6/17.
//
//

#import <Foundation/Foundation.h>
#import "TBDropbox.h"
#import "TBDropboxTask.h"
#import "TBDropboxEntry.h"


@interface TBDropboxQueue : NSObject

@property (strong, nonatomic, readonly, nonnull) NSArray<TBDropboxTask *> * scheduledTasks;
@property (strong, nonatomic, readonly, nullable) TBDropboxTask * currentTask;
@property (assign, nonatomic) BOOL hasPendingTasks;

@property (assign, nonatomic, readonly) TBDropboxQueueState state;
@property (assign, nonatomic) NSUInteger batchSize;

@property (weak, nonatomic, nullable) id<TBDropboxQueueDelegate> delegate;
@property (strong, nonatomic, readonly, nullable) NSString * sessionID;

@property (assign, nonatomic) BOOL verboseLogging;

+ (instancetype _Nullable)queueUsingSource:(id<TBDropboxClientSource> _Nonnull)source;

+ (instancetype _Nonnull)new __unavailable;
- (id _Nonnull) init __unavailable;

- (TBDropboxTask * _Nullable)taskByID:(TBDropboxTaskID * _Nonnull)ID;
- (NSArray<TBDropboxTask *> * _Nullable)tasksByEntry:(id<TBDropboxEntry> _Nonnull)entry;

- (NSNumber * _Nullable)addTask:(TBDropboxTask * _Nonnull)task;
- (BOOL)removeTask:(TBDropboxTask * _Nonnull)task;

- (void)resume;
- (void)pause;

@end

//
//  TBDropboxTask.h
//  Pods
//
//  Created by Bucha Kanstantsin on 2/3/17.
//
//

#import <Foundation/Foundation.h>
#import "TBDropbox.h"
#import "TBDropboxEntry.h"

#define TBDropboxUnderlyingErrorKey @"TBDropboxUnderlyingErrorKey"


@interface TBDropboxTask : NSObject

@property (assign, nonatomic, readonly) TBDropboxTaskState state;
@property (assign, nonatomic, readonly) TBDropboxTaskType type;
@property (strong, nonatomic, readonly, nonnull) id<TBDropboxEntry> entry;

@property (copy, nonatomic, readonly, nullable) TBDropboxTaskID * ID;
@property (weak, nonatomic, readonly, nullable) TBDropboxQueue * scheduledInQueue;

@property (strong, nonatomic, readonly, nullable) NSError * runningError;

+ (instancetype _Nonnull)new __unavailable;
- (id _Nonnull) init __unavailable;

@end


typedef void (^TBDropboxTaskCompletion) (TBDropboxTask * _Nonnull task, NSError * _Nullable error);


//
//  TBDropboxDocuments.h
//  Pods
//
//  Created by Bucha Kanstantsin on 12/29/16.
//
//

#import <Foundation/Foundation.h>
#import <TBLogger/TBLogger.h>
#import "TBDropbox.h"
#import "TBDropboxQueue.h"
#import "TBDropboxConnection.h"
#import "TBDropboxWatchdog.h"


@interface TBDropboxClient : NSObject

@property (strong, nonatomic, readonly, nullable) TBDropboxConnection * connection;
@property (strong, nonatomic, readonly, nonnull) TBDropboxQueue * tasksQueue;
@property (strong, nonatomic, readonly, nonnull) TBDropboxWatchdog * watchdog;

/**
 @brief: as I could figure out the sessionID is same for pair App - User
         but I could be wrong with it
**/

@property (strong, nonatomic, readonly, nullable) NSString * sessionID;

@property (assign, nonatomic) BOOL connectionDesired;

/**
 @brief: Use this option to enable synchronization
 when task queue finished processing a batch of tasks
 client will run watchdog to poll changes if any presents
 than return to processing tasks from the queue;
 if queue go to noLoad state client make watchdog create long poll task
 to be notified when changes occured on server
 **/

@property (assign, nonatomic) BOOL watchdogEnabled;

/**
 @brief: Change logger.logLevel option to enable verdbose logging
         Default setup is TBLogLevelWarning
 **/

@property (strong, nonatomic, readonly, nullable) TBLogger * logger;

+ (instancetype _Nonnull)sharedInstance;

+ (instancetype _Nonnull)alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));
- (instancetype _Nonnull)init __attribute__((unavailable("init not available, call sharedInstance instead")));
+ (instancetype _Nonnull)new __attribute__((unavailable("new not available, call sharedInstance instead")));
- (instancetype _Nonnull)copy __attribute__((unavailable("copy not available, call sharedInstance instead")));


- (void)initiateWithConnectionDesired:(BOOL)desired;
- (void)initiateWithConnectionDesired:(BOOL)desired
                          usingAppKey:(NSString * _Nullable)key;

- (void)addDelegate:(id<TBDropboxClientDelegate> _Nonnull)delegate;
- (void)removeDelegate:(id<TBDropboxClientDelegate> _Nonnull)delegate;

@end

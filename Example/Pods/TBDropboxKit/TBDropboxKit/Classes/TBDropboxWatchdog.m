//
//  TBDropboxSnapshot.m
//  Pods
//
//  Created by Bucha Kanstantsin on 2/3/17.
//
//

#import "TBDropboxWatchdog.h"
#import "TBDropboxFolderEntry.h"
#import "TBDropboxEntryFactory.h"
#import "TBDropboxTask+Private.h"
#import "TBDropboxListFolderTask.h"


#define TBDropboxWatchdog_Cursor_PendingChanges_Key @"TBDropboxWatchdog_Cursor_PendingChanges_Key=TBDropboxCursor.NSString"
#define TBDropboxWatchdog_Cursor_WideAwake_Key @"TBDropboxWatchdog_Cursor_WideAwake_Key=TBDropboxCursor.NSString"
#define TBDropboxWatchdog_Schedule_Delay_Sec 5

// must be at least 30
#define TBDropboxWatchdog_Request_Timeout_Min_Sec 30
#define TBDropboxWatchdog_Request_Timeout_Default_Sec 60


@interface TBDropboxWatchdog ()

@property (weak, nonatomic, readwrite, nullable) id<TBDropboxClientSource> routesSource;
@property (strong, nonatomic, nullable) TBDropboxListFolderTask * pendingChangesTask;
@property (strong, nonatomic, nullable) DBRpcTask * wideAwakeTask;
@property (strong, nonatomic, readonly, nullable) DBFILESUserAuthRoutes * fileRoutes;
@property (strong, nonatomic) TBDropboxCursor * pendingChangesCursor;
@property (strong, nonatomic, readonly) TBDropboxCursor * wideAwakeCursor;
@property (assign, nonatomic, readwrite) TBDropboxWatchdogState state;
@property (strong, nonatomic) NSString * sessionID;
@property (strong, nonatomic, readwrite) TBLogger * logger;

@end


@implementation TBDropboxWatchdog

@synthesize wideAwakeCursor = _wideAwakeCursor,
            pendingChangesCursor = _pendingChangesCursor;

/// MARK: - property -

- (TBLogger *)logger {
    if (_logger != nil) {
        return _logger;
    }
    _logger = [TBLogger loggerWithName: NSStringFromClass([self class])];
    _logger.logLevel = TBLogLevelWarning;
    return _logger;
}

- (DBFILESUserAuthRoutes *)fileRoutes {
    DBFILESUserAuthRoutes * result = [self.routesSource provideFilesRoutesFor: self];
    
    [self.logger info: result  == nil ? @"failed to receive routes"
                                      : @"did receive routes"];
    [self.logger verbose: @"did receive routes %@ from %@", result,
                          self.routesSource];

    return result;
}

- (void)setWideAwakeTimeout:(NSUInteger)wideAwakeTimeout {
    if (wideAwakeTimeout < TBDropboxWatchdog_Request_Timeout_Min_Sec) {
        _wideAwakeTimeout = TBDropboxWatchdog_Request_Timeout_Min_Sec;
        return;
    }
    
    _wideAwakeTimeout = wideAwakeTimeout;
}

- (TBDropboxCursor *)wideAwakeCursor {
    return _pendingChangesCursor;
}

- (TBDropboxCursor *)pendingChangesCursor {
    if (_pendingChangesCursor != nil) {
        return _pendingChangesCursor;
    }
    _pendingChangesCursor = [self loadCursorUsingKey: TBDropboxWatchdog_Cursor_PendingChanges_Key
                                      sessionID: self.sessionID];
    return _pendingChangesCursor;
}

- (void)setPendingChangesCursor:(TBDropboxCursor *)pendingChangesCursor {
    if ([_pendingChangesCursor isEqualToString: pendingChangesCursor]) {
        return;
    }
    
    _pendingChangesCursor = pendingChangesCursor;
    [self saveCursor: _pendingChangesCursor
            usingKey: TBDropboxWatchdog_Cursor_PendingChanges_Key
           sessionID: self.sessionID];
}

- (void)setState:(TBDropboxWatchdogState)state {
    if (_state == state) {
        return;
    }
    
    _state = state;
    [self notifyThatDidChangeStateTo: state];
}

/// MARK: - life cycle -

- (instancetype)initInstance {
    if (self = [super init]) {
        _wideAwakeTimeout = TBDropboxWatchdog_Request_Timeout_Default_Sec;
    }
    return self;
}

+ (instancetype)watchdogUsingSource:(id<TBDropboxClientSource>)source {
    if (source == nil) {
        return nil;
    }
    
    TBDropboxWatchdog * result = [[[self class] alloc] initInstance];
    result.routesSource = source;
    result.sessionID = source.sessionID;
    [result.logger log:@"create instance <%@>", @(result.hash)];
    
    return result;
}

/// MARK: - public -

- (void)resume {
    [self.logger info:@"did receive resume"];
    
    BOOL couldResume = self.state == TBDropboxWatchdogStateUndefined
                       || self.state == TBDropboxWatchdogStatePaused;
    if (couldResume == NO) {
        [self.logger log:@"skipping resume because State: Resumed"];
        return;
    }
    
    [self.logger log:@"resume"];
    
    self.state = TBDropboxWatchdogStateResumed;
    
    [self startPendingChanges];
}

- (void)pause {
    [self.logger info:@"did receive pause"];
    
    if (self.state == TBDropboxQueueStatePaused) {
        [self.logger log:@"skipping resume because State: Paused"];
        return;
    }
    
    [self.logger log:@"pause"];
    
    [self dissmissProcessingTasks];

    self.state = TBDropboxWatchdogStatePaused;
}

- (void)resetCursor {
    [self.logger log:@"reset cursor"];
    
    BOOL shouldResume = self.state == TBDropboxWatchdogStateResumedProcessingChanges
                        || self.state == TBDropboxWatchdogStateResumedWideAwake;
    [self pause];
    
    self.pendingChangesCursor = nil;
    
    if (shouldResume) {
        [self resume];
    }
}

/// MARK: - private -

- (void)startPendingChanges {
    [self.logger info:@"did recieve start pending changes"];
    if (self.state != TBDropboxWatchdogStateResumed) {
        [self.logger log:@"skipping start pending changes because is not State: Resumed"];
        return;
    }
    
    [self.logger log:@"start pending changes"];
    [self.logger info: @"pendign changes cursor %@", self.pendingChangesCursor];
    
    self.state = TBDropboxWatchdogStateResumedProcessingChanges;
    
    weakCDB(wself);
    self.pendingChangesTask =
        [self pendingChangesTaskUsingCursor: self.pendingChangesCursor
                                 completion: ^(TBDropboxTask * _Nonnull task,
                                               NSError * _Nullable error) {
        wself.state = TBDropboxWatchdogStateResumed;
        
        TBDropboxListFolderTask * listTask = (TBDropboxListFolderTask *)task;
        NSArray * changes = listTask.folderMetadata;
        
        [wself notePendingChanges: changes];
        
        if (error != nil) {
            return;
        }
        
        wself.pendingChangesCursor = listTask.cursor;
        [wself.logger info:@"inquired cursor %@", wself.pendingChangesCursor];
        
        [wself tryBeWideAwake];
    }];
    
    NSAssert(self.pendingChangesTask != nil, @"Pending changes task never could be nil");
    if (self.pendingChangesTask == nil) {
        [self.logger error: @"Failed to create pending changes task"];
        [self scheduleProcessPendingChanges];
        return;
    }
    
    [self.logger info:@"start pending changes task: %@", self.pendingChangesTask];
    
    self.pendingChangesTask.state = TBDropboxTaskStateRunning;
    
    [self.pendingChangesTask runUsingRoutesSource: self.routesSource
                                   withCompletion: ^(NSError * _Nullable error) {
        if (error == nil) {
            return;
        }
         
        [wself.logger error: @"failed processing pending changes %@", error];
        [wself checkUnderlingErrorOf: error];
        [wself scheduleProcessPendingChanges];
    }];
}

- (void)scheduleProcessPendingChanges {
    int delay = TBDropboxWatchdog_Schedule_Delay_Sec;
    
    [self.logger log: @"schedule start pending changes after %@ sec", @(delay)];
    
    weakCDB(wself);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(delay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self.logger info: @"fire scheduled start pending"];
        
        [wself startPendingChanges];
    });
}

- (void)tryBeWideAwake {
    [self.logger info:@"received try wide awake"];
    if (self.state != TBDropboxWatchdogStateResumed) {
        [self.logger log:@"skipping try wide awake bacause is not State: Resumed"];
        return;
    }
    
    BOOL awailableWideAwake = YES;
    SEL selector = @selector(watchdogCouldBeWideAwake:);
    if ([self.delegate respondsToSelector: selector]) {
        awailableWideAwake = [self.delegate watchdogCouldBeWideAwake: self];
        [self.logger info: @"delegate %@ allow wide awake: %@",
                           self.delegate, awailableWideAwake ? @"YES" : @"NO"];
    }
    
    if (awailableWideAwake == NO) {
        [self.logger log: @"skip wide awake bacause forbidden by delegate"];
        [self pause];
        return;
    }
    
    [self startWideAwake];
}

- (void)startWideAwake {
    [self.logger info:@"received start wide awake"];
    if (self.state != TBDropboxWatchdogStateResumed) {
        [self.logger log:@"skipping start wide awake bacause is not State: Resumed"];
        return;
    }
    
    [self.logger log:@"start wide awake"];
    
    self.state = TBDropboxWatchdogStateResumedWideAwake;
  
    [self.logger info:@"create wide awake task using cursor %@", self.wideAwakeCursor];

    self.wideAwakeTask = [self.fileRoutes listFolderLongpoll: self.wideAwakeCursor
                                                     timeout: @(self.wideAwakeTimeout)];
    
    weakCDB(wself);
    [self.wideAwakeTask setResponseBlock:^(DBFILESListFolderLongpollResult *  _Nullable response,
                                           id  _Nullable routeError,
                                           DBRequestError * _Nullable requestError) {
        wself.state = TBDropboxWatchdogStateResumed;
        NSError * error = [TBDropboxTask errorUsingRequestError: requestError
                                               taskRelatedError: routeError
                                                           info: nil];
        if (error != nil) {
            [wself.logger error: @"failed wide awake %@", error];
            [wself checkUnderlingErrorOf: error];
            [wself scheduleWideAwake];
            return;
        }
        
        NSInteger changesCount = response.changes.integerValue;
        
        [wself.logger log: @"did finish wide awake with %@ incoming changes",
                           response.changes];
        
        wself.wideAwakeTask = nil;
        if (changesCount > 0) {
            [wself startPendingChanges];
        } else {
            [wself notePendingChanges:@[]];
            [wself scheduleWideAwake];
        }
    }];
    
    [self.logger info:@"start wide awake task %@", self.wideAwakeTask];
    
    [self.wideAwakeTask start];
}

- (void)scheduleWideAwake {
    int delay = TBDropboxWatchdog_Schedule_Delay_Sec;
    
    [self.logger log: @"schedule wide awake after %@ sec", @(delay)];
    
    weakCDB(wself);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(delay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self.logger info: @"fire scheduled wide awake"];

        [wself startWideAwake];
    });
}

/// MARK list folder task

- (TBDropboxListFolderTask *)pendingChangesTaskUsingCursor:(TBDropboxCursor *)cursor
                                                completion:(TBDropboxTaskCompletion _Nonnull)completion {
    if (cursor != nil) {
        [self.logger info: @"create pending changes usig cursor"];
        [self.logger verbose: @"cursor %@", cursor];
        
        TBDropboxListFolderTask * result =
            [TBDropboxListFolderTask taskUsingCursor: cursor
                                          completion: completion];
        return result;
    }
    
    [self.logger info: @"enquiring new pending changes task because of nil cursor"];
    TBDropboxFolderEntry * root =
        [TBDropboxEntryFactory folderEntryUsingDropboxPath: nil];
    TBDropboxListFolderTask * result =
        [TBDropboxListFolderTask taskUsingEntry: root
                                     completion: completion];
    result.recursive = YES;
    result.includeDeleted = YES;
    
    return result;
}

/// MARK: check error

- (void)checkUnderlingErrorOf:(NSError *)mainError {
    
    id error = mainError.userInfo[TBDropboxUnderlyingErrorKey];
    
    if ([error isKindOfClass:[DBRequestError class]] == NO) {
        return;
    }
    DBRequestError * requestError = (DBRequestError *)error;
    
    switch (requestError.tag) {
        case DBRequestErrorAuth: {
            [self notifyThatHasAuthError: mainError];
        } break;
        case DBRequestErrorHttp: {
            if (requestError.statusCode.integerValue == 409) {
                [self resetCursor];
            }
        } break;
            
        default:
            break;
    }
}

/// MARK: notify delegate

- (void)notifyThatHasAuthError:(NSError *)error {
    [self.logger warning:@"found auth error"];
    
    SEL selector = @selector(watchdog: didReceiveAuthError:);
    if ([self.delegate respondsToSelector:selector]) {
        [self.logger log:@"provide auth error to delegate %@", self.delegate];
        
        [self.delegate watchdog: self
            didReceiveAuthError: error];
    }
}

- (void)notifyThatDidChangeStateTo:(TBDropboxWatchdogState)state {

    [self.logger warning:@"%@", StringFromDropboxWatchdogState(state)];
    
    SEL selector = @selector(watchdog:didChangeStateTo:);
    if ([self.delegate respondsToSelector: selector]) {
        
        [self.logger log:@"provide %@ to delegate %@",
                        StringFromDropboxWatchdogState(state), self.delegate];
        
        [self.delegate watchdog: self
               didChangeStateTo: state];
    }
}

- (void)notePendingChanges:(NSArray *)changes {
    SEL selector = @selector(watchdog:didCollectPendingChanges:);
    [self.logger warning:@"enquired %@ pending changes", @(changes.count)];
    [self.logger verbose:@"pending changes:\r %@", changes.debugDescription];
    
    if ([self.delegate respondsToSelector: selector]) {
    
        [self.logger log:@"provide %@ pending changes to delegate %@",
                         @(changes.count), self.delegate];
        
        [self.delegate watchdog: self
       didCollectPendingChanges: changes];
    }
}

/// MARK cursor storage

- (TBDropboxCursor *)loadCursorUsingKey:(NSString *)key
                              sessionID:(NSString *)sessionID {
    [self.logger log: @"load cursor"];
    
    NSString * cursorKey =
        [self cursorStoringKeyUsingKey: key sessionID: sessionID];
    TBDropboxCursor * result =
        [[NSUserDefaults standardUserDefaults] objectForKey: cursorKey];
    
    [self.logger info: @"did load cursor %@", result];
    [self.logger verbose: @"for key %@ session id %@", key, sessionID];
    
    return result;
}

- (void)saveCursor:(TBDropboxCursor *)cursor
          usingKey:(NSString *)key
         sessionID:(NSString *)sessionID {
    [self.logger log: @"save cursor"];
    
    NSString * cursorKey =
        [self cursorStoringKeyUsingKey: key sessionID: sessionID];
    
    [self.logger verbose: @"using cursor key: %@", cursorKey];
    
    [[NSUserDefaults standardUserDefaults] setObject: cursor
                                              forKey: cursorKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.logger info: @"did save cursor %@", cursor];
    [self.logger verbose: @"for key %@ session id %@", key, sessionID];

}

- (NSString *)cursorStoringKeyUsingKey:(NSString *)key
                             sessionID:(NSString *)sessionID {
    NSString * result = [NSString stringWithFormat:@"%@+%@", key, sessionID];
    return result;
}

/// MARK dissmiss tasks

- (void)dissmissProcessingTasks {
    [self.logger log: @"dissmiss processing tasks"];
    
    [self.pendingChangesTask suspend];
    self.pendingChangesTask = nil;

    [self.wideAwakeTask suspend];
    self.wideAwakeTask = nil;
}
@end

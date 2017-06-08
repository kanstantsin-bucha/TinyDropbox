//
//  TBDropboxDocuments.m
//  Pods
//
//  Created by Bucha Kanstantsin on 12/29/16.
//
//

#import "TBDropboxClient.h"
#import "TBDropboxConnection+Private.h"
#import <CDBDelegateCollection/CDBDelegateCollection.h>
#import "TBDropboxChange.h"
#import "TBDropboxChangesProcessor.h"

#define TBDropboxClient_Watchdog_Resume_Delay_Sec 0

@interface TBDropboxClient ()
<
    TBDropboxConnectionDelegate,
    TBDropboxClientSource,
    TBDropboxWatchdogDelegate,
    TBDropboxQueueDelegate
>

@property (strong, nonatomic, readwrite, nullable) TBDropboxConnection * connection;
@property (strong, nonatomic, readonly) DBUserClient * client;
@property (strong, nonatomic, readwrite, nullable) TBDropboxQueue * tasksQueue;
@property (strong, nonatomic, readwrite, nullable) TBDropboxWatchdog * watchdog;
@property (strong, nonatomic) CDBDelegateCollection * delegates;
@property (strong, nonatomic, readwrite) NSString * sessionID;

@property (strong, nonatomic) NSDictionary * outgoingChanges;

@property (strong, nonatomic, readwrite) TBLogger * logger;

@end


@implementation TBDropboxClient

/// MARK: property

- (TBLogger *)logger {
    if (_logger != nil) {
        return _logger;
    }
    _logger = [TBLogger loggerWithName: NSStringFromClass([self class])];
    _logger.logLevel = TBLogLevelWarning;
    return _logger;
}

- (void)setConnectionDesired:(BOOL)connectionDesired {
    [self.logger verbose: @"Received call setConnectionDesired %@",
                            connectionDesired ? @"YES" : @"NO"];
    if (_connectionDesired == connectionDesired) {
        [self.logger verbose: @"Skipping: same value"];
        return;
    }
    
    _connectionDesired = connectionDesired;
    [self.logger info: @"Connection desired changed to %@",
                          connectionDesired ? @"YES" : @"NO"];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_connectionDesired) {
            [self.logger warning: @"open connection"];
            
            [self.connection openConnection];
        } else {
            [self.logger warning: @"pause connection"];
            [self.connection closeConnection];
            
            [self nullifyQueueAndWatchdog];
        }
    });
}

- (DBUserClient *)client {
    DBUserClient * result = [DBClientsManager authorizedClient];
    if (result == nil) {
        [self.logger error: @"Dropbox Client is nil. Should never happend"];
    }
    NSAssert(result != nil, @"[ERROR] Dropbox Client should never be nil!");
    return result;
}

- (TBDropboxQueue *)tasksQueue {
    if (_tasksQueue != nil) {
        return _tasksQueue;
    }
    
    [self.logger info: @"create task queue"];
    
    _tasksQueue = [TBDropboxQueue queueUsingSource: self];
    _tasksQueue.delegate = self;
    
    return _tasksQueue;
}

- (TBDropboxWatchdog *)watchdog {
    if (_watchdog != nil) {
        return _watchdog;
    }
    
    [self.logger info: @"create watchdog"];
    
    _watchdog = [TBDropboxWatchdog watchdogUsingSource: self];
    _watchdog.delegate = self;
    
    return _watchdog;
}

- (CDBDelegateCollection *)delegates {
    if (_delegates != nil) {
        return _delegates;
    }
    
    [self.logger info: @"create delegates collection"];
    
    _delegates =
        [[CDBDelegateCollection alloc] initWithProtocol:@protocol(TBDropboxClientDelegate)];
    
    return _delegates;
}

- (void)setWatchdogEnabled:(BOOL)watchdogEnabled {

    [self.logger verbose: @"receive call setWatchdogEnabled %@",
                            watchdogEnabled ? @"YES" : @"NO"];
    
    if (_watchdogEnabled == watchdogEnabled) {
        [self.logger verbose: @"Skipping: same value"];
        return;
    }
    
    [self.logger info: @"set watchdog enabled %@",
                       watchdogEnabled ? @"YES" : @"NO "];
    
    _watchdogEnabled = watchdogEnabled;
    
    if (_watchdogEnabled) {
        if (self.connection.connected) {
            [self resumeWatchdogAfterDelay: TBDropboxClient_Watchdog_Resume_Delay_Sec];
        }
    } else {
        [self pauseWatchdog];
    }
}

/// MARK: life cycle

+ (instancetype)sharedInstance {
    static TBDropboxClient * _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[super allocWithZone:NULL] initInstance];
        [_sharedInstance.logger log: @"create sharedInstance"];
    });
    
    return _sharedInstance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

- (instancetype)copyWithZone:(struct _NSZone *)zone {
    return self;
}

- (instancetype)initInstance {
    if (self = [super init]) {
    }
    return self;
}


- (void)initiateWithConnectionDesired:(BOOL)desired {
    [self initiateWithConnectionDesired: desired
                            usingAppKey: nil];
}

- (void)initiateWithConnectionDesired:(BOOL)desired
                          usingAppKey:(NSString *)key {
    if (key.length == 0) {
        [self.logger error:@"initiate called with nil app key"];
    }
    
    [self.logger info: @"initiate connection"];
    TBDropboxConnection * connection = [TBDropboxConnection connectionUsingAppKey: key
                                                                         delegate: self];
    [self.logger verbose: @"connection %@",
     connection];
    self.connection = connection;
    
    
    [self.logger log: @"initiated: connectionDesired: %@\r appkey %@",
     desired ? @"YES" : @"NO", key == nil ? @"not nil" : @"nil"];
    
    self.connectionDesired = desired;
    self.sessionID = self.connection.accessTokenUID;
}

/// MARK: protocols

/// MARK: TBDropboxConnectionDelegate

- (void)dropboxConnection:(TBDropboxConnection * _Nonnull)connection
         didChangeStateTo:(TBDropboxConnectionState)state {
    if (state == TBDropboxConnectionStateConnected) {
        [self.watchdog resetCursor];
    }
    
    [self.logger warning: @"connection %@",
                          StringFromDropboxConnectionState(state)];
    
    if (self.connection.connected) {
        [self resumeTasksQueue];
    } else {
        [self pauseTasksQueue];
    }
    
    SEL selector = @selector(dropboxConnection:
                              didChangeStateTo:);
    [self.delegates enumerateDelegatesRespondToSelector: selector
                                             usingBlock: ^(id<TBDropboxConnectionDelegate> delegate, BOOL *stop) {
        [self.logger verbose: @"connection %@ provided to delegate %@",
                              StringFromDropboxConnectionState(state), delegate];
                              
        [delegate dropboxConnection: connection
                   didChangeStateTo: state];
    }];
}

- (void)dropboxConnection:(TBDropboxConnection * _Nonnull)connection
     didChangeAuthStateTo:(TBDropboxAuthState)state
                withError:(NSError * _Nullable)error {
    
    [self.logger info: @"authentification %@",
                       StringFromDropboxAuthState(state)];
    
    SEL selector = @selector(dropboxConnection:
                          didChangeAuthStateTo:
                                     withError:);
    [self.delegates enumerateDelegatesRespondToSelector: selector
                                             usingBlock: ^(id<TBDropboxConnectionDelegate> delegate, BOOL *stop) {
        [self.logger verbose: @"provide authentification %@ to delegate %@",
                                StringFromDropboxAuthState(state), delegate];
        [delegate dropboxConnection: connection
               didChangeAuthStateTo: state
                          withError: error];
                          
        
    }];
}

- (void)dropboxConnection:(TBDropboxConnection *)connection
       didChangeSessionID:(NSString *)sessionID {
    [self.logger log: @"connection changed session ID to %@",
                      sessionID];
    if (sessionID == nil) {
        [self.logger info: @"skipping switching to different session"];
        return;
    }
    
    [self switchToDifferentSession: sessionID];
}

/// MARK: TBDropboxWatchdogDelegate

- (void)watchdog:(TBDropboxWatchdog *)watchdog
didChangeStateTo:(TBDropboxWatchdogState)state {
    [self.logger log: @"watchdog %@",
                      StringFromDropboxWatchdogState(state)];
    
    SEL selector = @selector(watchdog:
                             didChangeStateTo:);
    [self.delegates enumerateDelegatesRespondToSelector: selector
                                             usingBlock: ^(id<TBDropboxWatchdogDelegate> delegate, BOOL *stop) {
        [self.logger verbose: @"provide watchdog %@ to delegate %@",
                              StringFromDropboxWatchdogState(state), delegate];
        [delegate watchdog: watchdog
          didChangeStateTo: state];
        
    }];
}

- (void)watchdog:(TBDropboxWatchdog *)watchdog
    didCollectPendingChanges:(NSArray *)changes {
    [self.logger log: @"watchdog collected pending metadata items count %@",
                      @(changes.count)];
    [self.logger verbose: @"pending changes:\r %@",
                          changes];
    
    if (self.connection.connected) {
        [self resumeTasksQueue];
    }
    
    NSArray * incomingChanges = nil;
    if (self.outgoingChanges.count == 0) {
        incomingChanges = changes;
    } else {
        [self.logger info: @"filter metadata to exclude app outgoing metadata"];
        incomingChanges =
            [TBDropboxChangesProcessor processMetadataChanges: changes
                                          byExcludingOutgoing: self.outgoingChanges];
    }
    
    [self.logger info: @"incoming metadata items count %@",
                       @(incomingChanges.count)];
    [self.logger verbose: @"incoming metadata items:\r %@",
                          incomingChanges];
    
    [self provideIncomingMetadataChanges: incomingChanges];
}

- (BOOL)watchdogCouldBeWideAwake:(TBDropboxWatchdog *)watchdog {
    BOOL result = self.tasksQueue.hasPendingTasks == NO;
    [self.logger log: @"watchdog proceed wide awake: %@",
                      result ? @"YES" : @"NO" ];
    return result;
}

- (void)watchdog:(TBDropboxWatchdog *)watchdog
didReceiveAuthError:(NSError *)error {
    [self.logger error: @"watchdog acquired Auth error %@",
                        error.localizedDescription];
    [self handleAuthError: error];
}

/// MARK: TBDropboxQueueDelegate

- (void)queue:(TBDropboxQueue *)queue
    didChangeStateTo:(TBDropboxQueueState)state {
    
    [self.logger log: @"tasks queue %@",
                      StringFromDropboxQueueState(state)];
    
    if (state == TBDropboxQueueStateResumedProcessing) {
        [self pauseWatchdog];
    }
    if (state == TBDropboxQueueStateResumedNoLoad) {
        [self resumeWatchdogAfterDelay: TBDropboxClient_Watchdog_Resume_Delay_Sec];
    }
}

- (void)queue:(TBDropboxQueue *)queue
    didFinishBatchOfTasks:(NSArray *)tasks {
    [self.logger log: @"tasks queue finished batch (%@/max %@) of tasks",
                      @(tasks.count), @(self.tasksQueue.batchSize)];
    [self.logger info: @"batch tasks:\r %@",
                       tasks];
    
    if (self.watchdogEnabled == NO) {
        [self.logger log: @"skipping processing outgoing metadata items because Watchdog disabled"];
        return;
    }
    
    [self pauseTasksQueue];
    
    [self.logger log: @"create outgoing metadata items using tasks"];
    
    self.outgoingChanges =
        [TBDropboxChangesProcessor outgoingMetadataChangesUsingTasks: tasks];
    
    [self.logger verbose: @"outgoing metadata items:\r %@",
                          self.outgoingChanges];
    
    [self resumeWatchdogAfterDelay: TBDropboxClient_Watchdog_Resume_Delay_Sec];
}

- (void)queue:(TBDropboxQueue *)queue
    didReceiveAuthError:(NSError *)error {
    [self.logger error: @"tasks queue acquired Auth error %@",
                        error.localizedDescription];
    [self handleAuthError: error];
}

/// MARK: TBDropboxClientSource

- (DBFILESUserAuthRoutes *)provideFilesRoutesFor:(NSObject *)inquirer {
    [self.logger info: @"provide file routes to %@", inquirer];
    
    DBFILESUserAuthRoutes * result = self.client.filesRoutes;
    
    [self.logger verbose: @"did provide file routes %@ to %@", result, inquirer];
    return result;
}

/// MARK: public

- (void)addDelegate:(id<TBDropboxClientDelegate>)delegate {
    [self.logger warning:@"add delegate"];
    
    [self.delegates addDelegate: delegate];
    
    [self.logger log: @"did add delegate %@", delegate];
}

- (void)removeDelegate:(id<TBDropboxClientDelegate>)delegate {
    [self.logger warning: @"remove delegate"];
    
    [self.delegates removeDelegate: delegate];
    
    [self.logger log: @"did remove delegate %@", delegate];
}

/// MARK: private

/// MARK logic controls

- (void)pauseTasksQueue {
    [self.logger log: @"pause tasks queue"];
    
    [self.tasksQueue pause];
}

- (void)resumeTasksQueue {
    [self.logger log: @"resume tasks queue"];
    
    [self.tasksQueue resume];
}

- (void)pauseWatchdog {
    [self.logger log: @"pause watchdog"];
    
    [self.watchdog pause];
}

- (void)resumeWatchdog {
    [self.logger log: @"resume watchdog"];
    
    [self.watchdog resume];
}

- (void)resumeWatchdogAfterDelay:(NSUInteger)sec {
    [self.logger info: @"will resume watchdog after %@ sec", @(sec)];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(sec * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (self.watchdogEnabled == NO) {
        
            [self.logger info: @"skipping watchdog resume because it is disabled"];
            return;
        }
        
        BOOL queueNotProcessing = self.tasksQueue.state == TBDropboxQueueStateResumedNoLoad
                                  || self.tasksQueue.state == TBDropboxQueueStatePaused;
        
        if (queueNotProcessing == NO) {
            
            [self.logger info: @"skipping watchdog resume because tasks queue processing tasks"];
            return;
        }
        
        [self resumeWatchdog];
    });
}

/// handle auth error

- (void)handleAuthError:(NSError *)error {
    [self.logger log: @"auth error %@", error];
    
    [self pauseTasksQueue];
    [self pauseWatchdog];
    
    [self.logger log: @"process user reauthorization"];
    [self.connection reauthorizeClient];
}

/// MARK provide changes

- (void)provideIncomingMetadataChanges:(NSArray *)metadataChanges {
    NSArray * changes =
        [TBDropboxChangesProcessor changesUsingMetadataCahnges:metadataChanges];
    
    [self.logger info: @"did prepare incoming changes count %@", @(changes.count)];
    [self.logger verbose: @"incoming changes:\r %@", changes];
    
    SEL selector = @selector(client:didReceiveIncomingChanges:);
    [self.delegates enumerateDelegatesRespondToSelector: selector
                                             usingBlock:^(id<TBDropboxClientDelegate> delegate, BOOL *stop) {
        [self.logger warning:@"provide %@ changes to delegate %@", @(changes.count),
                             delegate];
        
        [delegate client: self
didReceiveIncomingChanges: changes];
    }];
}

/// MARK handle switch of session

- (void)switchToDifferentSession:(NSString *)sessionID {
    if ([self.sessionID isEqualToString: sessionID]) {
    
        [self.logger log: @"skipping switch to session with same ID"];
        return;
    }
    
    [self.logger warning:@"switch to session <%@>", sessionID];
    
    self.sessionID = sessionID;
    
    [self nullifyQueueAndWatchdog];
}

- (void)nullifyQueueAndWatchdog {
    [self.logger log: @"nullify watchdog and tasks queue"];
    self.watchdog = nil;
    self.tasksQueue = nil;
}

@end

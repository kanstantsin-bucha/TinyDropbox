//
//  TBDropboxQueue.m
//  Pods
//
//  Created by Bucha Kanstantsin on 2/6/17.
//
//

#import "TBDropboxQueue.h"
#import "TBDropboxEntry.h"
#import "TBDropboxTask+Private.h"
#import "TBDropboxClient.h"

#define TBDropboxQueue_Batch_Size_Default 20


@interface TBDropboxQueue ()

@property (weak, nonatomic, readwrite, nullable) id<TBDropboxClientSource> routesSource;

@property (strong, nonatomic) NSMutableArray<TBDropboxTask *> * scheduledTasksHolder;
@property (strong, nonatomic) NSMutableArray<TBDropboxTask *> * processedTasksBatchHolder;
@property (assign, nonatomic, readonly) TBDropboxTaskID * nextTaskID;
@property (assign, nonatomic) NSUInteger taskID;
@property (assign, nonatomic, readwrite) TBDropboxQueueState state;
@property (strong, nonatomic, readwrite) TBDropboxTask * currentTask;
@property (strong, nonatomic, readwrite) NSString * sessionID;

@end


@implementation TBDropboxQueue

/// MARK: property

- (NSArray<TBDropboxTask *> *)scheduledTasks {
    NSArray * result = [self.scheduledTasksHolder copy];
    return result;
}

- (TBDropboxTaskID *)nextTaskID {
    self.taskID += 1;
    TBDropboxTaskID * result = @(self.taskID);
    return result;
}

- (NSMutableArray<TBDropboxTask *> *)scheduledTasksHolder {
    if (_scheduledTasksHolder != nil) {
        return _scheduledTasksHolder;
    }
    
    _scheduledTasksHolder = [NSMutableArray array];
    return _scheduledTasksHolder;
}

- (NSMutableArray<TBDropboxTask *> *)processedTasksBatchHolder {
    if (_processedTasksBatchHolder != nil) {
        return _processedTasksBatchHolder;
    }
    
    _processedTasksBatchHolder = [NSMutableArray array];
    return _processedTasksBatchHolder;
}

- (BOOL)hasPendingTasks {
    BOOL result = self.scheduledTasksHolder.count > 0
    || self.currentTask != nil;
    return result;
}

- (void)setState:(TBDropboxQueueState)state {
    if (_state == state) {
        return;
    }
    
    _state = state;
    [self notifyThatDidChangeStateTo: state];
}

/// MARK: life cycle

- (instancetype)initInstance {
    if (self = [super init]) {
        _batchSize = TBDropboxQueue_Batch_Size_Default;
    }
    return self;
}

+ (instancetype)queueUsingSource:(id<TBDropboxClientSource>)source {
    if (source == nil) {
        return nil;
    }
    
    TBDropboxQueue * result = [[[self class] alloc] initInstance];
    result.routesSource = source;
    result.sessionID = source.sessionID;
    
    return result;
}

/// MARK: public

- (void)resume {
    if (self.state != TBDropboxQueueStatePaused) {
        return;
    }
    
    self.state = TBDropboxQueueStateResumedNoLoad;
    
    if (self.hasPendingTasks) {
        [self startProcessing];
    }
}

- (void)pause {
    [self.currentTask suspend];
    self.currentTask.state = TBDropboxTaskStateSuspended;
    
    self.state = TBDropboxQueueStatePaused;
}

- (NSNumber *)addTask:(TBDropboxTask *)task {
    if (task == nil) {
        return nil;
    }
    
    if (task.state != TBDropboxTaskStateReady) {
        return nil;
    }
    
    task.state = TBDropboxTaskStateScheduled;
    task.ID = self.nextTaskID;
    task.scheduledInQueue = self;
    
    [self.scheduledTasksHolder addObject:task];
    
    
    if (self.state != TBDropboxQueueStateResumedProcessing) {
        [self startProcessing];
    }
    
    return task.ID;
}

- (BOOL)removeTask:(TBDropboxTask *)task {
    if ([self.scheduledTasksHolder containsObject:task] == NO) {
        return NO;
    }
    
    [self.scheduledTasksHolder removeObject:task];
    task.state = TBDropboxTaskStateReady;
    task.ID = nil;
    task.scheduledInQueue = nil;
    return YES;
}

- (TBDropboxTask *)taskByID:(TBDropboxTaskID *)ID {
    NSPredicate * predicate = [self tasksPredicateByID: ID];
    NSArray * filtered =
    [self.scheduledTasksHolder filteredArrayUsingPredicate: predicate];
    TBDropboxTask * result = filtered.firstObject;
    return result;
}

- (NSArray<TBDropboxTask *> *)tasksByEntry:(id<TBDropboxEntry>)entry {
    NSPredicate * predicate = [self tasksPredicateByPath: entry.dropboxPath];
    NSArray * result =
    [self.scheduledTasksHolder filteredArrayUsingPredicate: predicate];
    return result;
}

/// MARK: queue

- (void)startProcessing {
    
    self.state = TBDropboxQueueStateResumedProcessing;
    
    BOOL shouldRestoreCurrent = self.currentTask != nil
    && self.currentTask.state != TBDropboxTaskStateSucceed;
    
    if (shouldRestoreCurrent) {
        BOOL resumed = [self.currentTask resume];
        if (resumed) {
            return;
        }
        
        [self runTask: self.currentTask];
    } else {
        [self runNextTask];
    }
}

- (void)runNextTask {
    if (self.state == TBDropboxQueueStatePaused) {
        return;
    }
    
    self.currentTask = self.scheduledTasksHolder.firstObject;
    
    [self runTask: self.currentTask];
}

- (void)finishCurrentTask {
    [self.processedTasksBatchHolder addObject: self.currentTask];
    self.currentTask = nil;
    
    if (self.processedTasksBatchHolder.count >= self.batchSize) {
        [self finishBatchOfTasks];
    }
    
    [self runNextTask];
}

- (void)finishBatchOfTasks {
    SEL selector = @selector(queue:didFinishBatchOfTasks:);
    if ([self.delegate respondsToSelector:selector]) {
        [self.delegate queue: self
       didFinishBatchOfTasks: [self.processedTasksBatchHolder copy]];
    }
    self.processedTasksBatchHolder = nil;
}

- (void)runTask:(TBDropboxTask *)runningTask {
    if (self.state == TBDropboxQueueStatePaused) {
        return;
    }
    
    if (runningTask == nil) {
        self.state = TBDropboxQueueStateResumedNoLoad;
        [self finishBatchOfTasks];
        return;
    }
    
    if (self.routesSource == nil) {
        return;
    }
    
    [self.scheduledTasksHolder removeObject: runningTask];
    runningTask.state = TBDropboxTaskStateRunning;
    
    weakCDB(wself);
    [runningTask runUsingRoutesSource: self.routesSource
                       withCompletion: ^(NSError * _Nullable error) {
        if (error != nil) {
            runningTask.state = TBDropboxTaskStateFailed;
            [self checkUnderlingErrorOf: error];
        } else {
            runningTask.state = TBDropboxTaskStateSucceed;
        }
       
        [wself finishCurrentTask];
    }];
}

- (void)checkUnderlingErrorOf:(NSError *)mainError {
    id error = mainError.userInfo[TBDropboxUnderlyingErrorKey];
    
    if ([error isKindOfClass:[DBRequestError class]] == NO) {
        return;
    }
    
    DBRequestErrorTag tag = [(DBRequestError *)error tag];
    
    BOOL receivedAuthError = tag == DBRequestErrorAuth;
    if (receivedAuthError == NO) {
        return;
    }
    
    SEL selector = @selector(queue: didReceiveAuthError:);
    if ([self.delegate respondsToSelector:selector]) {
        [self.delegate queue: self
         didReceiveAuthError: mainError];
    }
}

/// MAKR: notify delegate

- (void)notifyThatDidChangeStateTo:(TBDropboxQueueState)state {
    SEL selector = @selector(queue:didChangeStateTo:);
    if ([self.delegate respondsToSelector: selector]) {
        [self.delegate queue: self
            didChangeStateTo: state];
    }
}

/// MARK: logging


/// MARK: predicates

- (NSPredicate * )tasksPredicateByID:(TBDropboxTaskID *)ID {
    NSPredicate * result = [NSPredicate predicateWithFormat:@"ID == %@", ID];
    return result;
}

- (NSPredicate * )tasksPredicateByPath:(NSString *)path {
    NSPredicate * result = [NSPredicate predicateWithFormat:@"item.dropboxPath like %@", path];
    return result;
}

@end

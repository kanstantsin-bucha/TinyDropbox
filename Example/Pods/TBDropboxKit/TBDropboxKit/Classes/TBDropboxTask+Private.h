//
//  TBDropboxTask+Private.h
//  Pods
//
//  Created by Bucha Kanstantsin on 2/6/17.
//
//

#ifndef TBDropboxTask_Private_h
#define TBDropboxTask_Private_h

#import "TBDropboxTask.h"


@interface TBDropboxTask ()

@property (assign, nonatomic, readwrite) TBDropboxTaskState state;
@property (assign, nonatomic, readwrite) TBDropboxTaskType type;
@property (strong, nonatomic, readwrite, nonnull) id<TBDropboxEntry> entry;

@property (copy, nonatomic, readwrite, nullable) TBDropboxTaskID * ID;
@property (weak, nonatomic, readwrite, nullable) TBDropboxQueue * scheduledInQueue;

@property (strong, nonatomic, nullable) DBTask * dropboxTask;
@property (strong, nonatomic, nullable) TBDropboxTaskCompletion completion;

@property (strong, nonatomic, readwrite, nullable) NSError * runningError;

- (instancetype _Nullable)initInstance;

- (void)runUsingRoutesSource:(id<TBDropboxClientSource> _Nonnull)routesSource
              withCompletion:(CDBErrorCompletion _Nonnull)completion;
- (void)performMainUsingRoutes:(DBFILESUserAuthRoutes * _Nonnull)routes
                withCompletion:(CDBErrorCompletion _Nonnull)completion;

- (void)suspend;
- (BOOL)resume;

- (NSError * _Nullable)composeErrorUsingRequestError:(DBRequestError * _Nullable)requestError
                                    taskRelatedError:(id _Nullable)relatedError;

+ (NSError * _Nullable)errorUsingRequestError:(DBRequestError * _Nullable)requestError
                             taskRelatedError:(id _Nullable)relatedError
                                         info:(NSDictionary * _Nullable)info;

- (NSError * _Nullable)errorFileNotExistsAtURL:(NSURL * _Nonnull)URL
                                   description:(NSString * _Nonnull)description;

@end

#endif /* TBDropboxTask_Private_h */

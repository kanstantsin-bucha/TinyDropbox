//
//  TBDropboxTask.m
//  Pods
//
//  Created by Bucha Kanstantsin on 2/3/17.
//
//

#import "TBDropboxTask.h"
#import "TBDropboxTask+Private.h"
#import "TBDropboxQueue.h"

#define TBDropboxTaskDescriptionKey @"TBDropboxTaskDescriptionKey"

@implementation TBDropboxTask

/// MARK: life cycle

- (instancetype)initInstance {
    if (self = [super init]) {
    }
    return self;
}

/// MARK: private

- (void)suspend {
    if (self.dropboxTask == nil) {
        return;
    }
    
    [self.dropboxTask suspend];
}

- (BOOL)resume {
    if (self.dropboxTask == nil) {
        return NO;
    }
    
    [self.dropboxTask resume];
    return YES;
}

- (void)runUsingRoutesSource:(id<TBDropboxClientSource>)routesSource
              withCompletion:(CDBErrorCompletion)completion {
    
    if (self.state != TBDropboxTaskStateRunning) {
        NSError * error = [self failedToProcessNotRunningTaskError];
        completion(error);
        if (self.completion != nil) {
            self.completion(self, error);
        }
    }
    
    DBFILESUserAuthRoutes * routes = [routesSource provideFilesRoutesFor: self];
    if (routes == nil) {
        NSError * error = [self failedToRunNoRoutesError];
        completion(error);
        if (self.completion != nil) {
            self.completion(self, error);
        }
        return;
    }
    
    [self performMainUsingRoutes: routes
                  withCompletion: ^(NSError * _Nullable error) {
        self.dropboxTask = nil;
        
        completion(error);
        if (self.completion != nil) {
            self.completion(self, error);
        }
    }];
}

- (void)performMainUsingRoutes:(DBFILESUserAuthRoutes *)routes
                withCompletion:(CDBErrorCompletion _Nonnull)completion {
    
    NSAssert(NO, @"main logic method required redefinition in subclass");
    completion([self redefinitionRequiredError]);
}

/// MARK: error

- (NSError *)failedToProcessNotRunningTaskError {
    NSString * description = @"Failed to process task that was not running";
    NSError * result = [NSError errorWithDomain: TBDropboxErrorDomain
                                           code: 100
                                       userInfo: @{ NSLocalizedDescriptionKey : description}];
    return result;
}

- (NSError *)failedToRunNoRoutesError {
    NSString * description = @"Failed to run task that has no files routes";
    NSError * result = [NSError errorWithDomain: TBDropboxErrorDomain
                                           code: 101
                                       userInfo: @{ NSLocalizedDescriptionKey : description}];
    return result;
}

- (NSError *)redefinitionRequiredError {
    NSString * description = @"Main logic method required redefinition in subclass";
    NSError * result = [NSError errorWithDomain: TBDropboxErrorDomain
                                           code: 102
                                       userInfo: @{ NSLocalizedDescriptionKey : description}];
    return result;
}

- (NSError *)composeErrorUsingRequestError:(DBRequestError * _Nullable)requestError
                          taskRelatedError:(id _Nullable)relatedError {
    NSDictionary * info = @{ TBDropboxTaskDescriptionKey: self.description };
    NSError * result = [[self class] errorUsingRequestError: requestError
                                           taskRelatedError: relatedError
                                                       info: info];
    return result;
}

/// MARK: dropbox errors

/// TODO: improve errors based on extended description
/// https://github.com/dropbox/dropbox-sdk-obj-c

+ (NSError *)errorUsingRequestError:(DBRequestError * _Nullable)requestError
                   taskRelatedError:(id _Nullable)relatedError
                               info:(NSDictionary *)info {
    if (requestError != nil) {
        NSError * error = [self errorUsingRequestError: requestError
                                                  info: info];
        return error;
    }
    
    if (relatedError != nil) {
        NSError * error = [self errorUsingRelatedError: relatedError
                                                  info: info];
        return error;
    }
    
    return nil;
}

+ (NSError *)errorUsingRelatedError:(id _Nonnull)relatedError
                               info:(NSDictionary *)info {
    NSError * result = nil;
    if ([relatedError isKindOfClass:[DBFILESListFolderError class]]) {
        result = [self errorUsingFolderError: relatedError
                                        info: info];
    }
    
    if (result == nil) {
        NSString * message =
            [NSString stringWithFormat:@"Related error %@", relatedError];
        NSDictionary * info = @{NSLocalizedDescriptionKey: message,
                                TBDropboxUnderlyingErrorKey: relatedError};
        result = [NSError errorWithDomain: TBDropboxErrorDomain
                                     code: 200
                                 userInfo: info];
    }
    
    return result;
}

+ (NSDictionary *)infoUsingMessage:(NSString *)message
                   underlyingError:(id)error
                    additionalInfo:(NSDictionary *)info {
    NSMutableDictionary * result = [NSMutableDictionary dictionary];
    if (message.length > 0) {
        result[NSLocalizedDescriptionKey] = message;
    }
    
    if (error != nil) {
        result[TBDropboxUnderlyingErrorKey] = error;
    }
    
    if (info.allKeys.count > 0) {
        [result addEntriesFromDictionary:info];
    }
    
    return result;
}

+ (NSError *)errorUsingRequestError:(DBRequestError *)error
                               info:(NSDictionary *)info {
    NSString * message =
        [NSString stringWithFormat: @"Generic request error %@. %@",
         [error tagName],
          error.description];
    NSDictionary * userInfo = [self infoUsingMessage: message
                                     underlyingError: error
                                      additionalInfo: info];

    NSError * result = [NSError errorWithDomain: TBDropboxErrorDomain
                                           code: 301
                                       userInfo: userInfo];
    return result;
}

+ (NSError *)errorUsingFolderError:(DBFILESListFolderError *)error
                              info:(NSDictionary *)info {
    NSString * message =
        [NSString stringWithFormat: @"Route-specific error %@.",
                                    [error tagName]];
    
    if ([error isPath]) {
        message =
            [NSString stringWithFormat: @"%@. Invalid path: %@",
                                        message, error.path];
    }
    
    message = [NSString stringWithFormat: @"%@. %@",
                                          message, error.description];
    
    NSDictionary * userInfo = [self infoUsingMessage: message
                                     underlyingError: error
                                      additionalInfo: info];
    NSError * result = [NSError errorWithDomain: TBDropboxErrorDomain
                                           code: 201
                                       userInfo: userInfo];
    return result;
}



- (NSError *)errorFileNotExistsAtURL:(NSURL *)URL
                         description:(NSString *)description {
    NSString * message =
        [NSString stringWithFormat: @"File not exists at URL %@ %@",
                                    URL.absoluteString,
                                    description];
    
    NSDictionary * userInfo = @{ NSLocalizedDescriptionKey: message };
    NSError * result = [NSError errorWithDomain: TBDropboxErrorDomain
                                           code: 401
                                       userInfo: userInfo];
    return result;
}

/// MARK: description

- (NSString *)description {
    NSString * result =
        [NSString stringWithFormat:@"%@ <%@>\
                                   \r %@\
                                   \r Path: %@",
                         NSStringFromClass([self class]),
                         @(self.hash),
                         StringFromDropboxTaskState(self.state),
                         self.entry.readablePath];
    return result;
}

@end

//
//  TBDropboxConnection.h
//  Pods
//
//  Created by Bucha Kanstantsin on 12/12/2016.
//
//

#import <Foundation/Foundation.h>
#import <TBLogger/TBLogger.h>
#import "TBDropboxClient.h"
#import "TBDropbox.h"


@interface TBDropboxConnection : NSObject

@property (assign, nonatomic, readonly) TBDropboxConnectionState state;

/**
 Returns id of last connected user (this is provided by server with a token during auth)
 if it has changed than we log in with different user account
 */
@property (copy, nonatomic, readonly, nullable) NSString * accessTokenUID;

/**
  Returns YES if user connected to dropbox
 */
@property (assign, nonatomic, readonly) BOOL connected;

/**
 @brief: Change logger.logLevel option to enable verdbose logging
 Default setup is TBLogLevelWarning
 **/

@property (strong, nonatomic, readonly, nullable) TBLogger * logger;

+ (instancetype _Nonnull)new __unavailable;
- (id _Nonnull) init __unavailable;

- (BOOL)handleAuthorisationRedirectURL:(NSURL * _Nonnull)url;

@end

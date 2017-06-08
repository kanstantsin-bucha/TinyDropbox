//
//  TBDropboxConnection+Private.h
//  Pods
//
//  Created by Bucha Kanstantsin on 2/7/17.
//
//

#ifndef TBDropboxConnection_Private_h
#define TBDropboxConnection_Private_h

#import "TBDropboxConnection.h"
#import "TBDropbox.h"


@interface TBDropboxConnection ()

@property (weak, nonatomic, nullable) id<TBDropboxConnectionDelegate> delegate;

- (void)openConnection;
- (void)closeConnection;
- (void)pauseConnection;
- (void)reauthorizeClient;

+ (instancetype _Nullable)connectionUsingAppKey:(NSString * _Nonnull)key
                                       delegate:(id<TBDropboxConnectionDelegate> _Nonnull)delegate;

@end

#endif /* TBDropboxConnection_Private_h */

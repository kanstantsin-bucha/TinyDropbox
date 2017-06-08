//
//  TBDropboxLocalChange.h
//  Pods
//
//  Created by Bucha Kanstantsin on 3/15/17.
//
//

#import <Foundation/Foundation.h>
#import "TBDropbox.h"

@interface TBDropboxLocalChange : NSObject

@property (strong, nonatomic, readonly, nullable) NSURL * localURL;
@property (strong, nonatomic, readonly, nonnull) NSString * dropboxPath;
@property (assign, nonatomic, readonly) TBDropboxChangeAction action;

+ (instancetype _Nullable)changeByMirroringLocalURL:(NSURL * _Nonnull)localURL
                                       usingBaseURL:(NSURL *_Nonnull)baseURL
                                             action:(TBDropboxChangeAction)action;

+ (instancetype _Nullable)changeAtURL:(NSURL * _Nullable)localURL
                          dropboxPath:(NSString * _Nonnull)path
                               action:(TBDropboxChangeAction)action;

+ (instancetype _Nonnull)new __unavailable;
- (id _Nonnull) init __unavailable;

@end

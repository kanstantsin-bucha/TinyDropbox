//
//  TBDropboxChange.h
//  Pods
//
//  Created by Bucha Kanstantsin on 3/15/17.
//
//

#import <Foundation/Foundation.h>
#import "TBDropbox.h"


@interface TBDropboxChange : NSObject

@property (strong, nonatomic, readonly, nonnull) NSString * dropboxPath;
@property (assign, nonatomic, readonly) TBDropboxChangeAction action;
@property (strong, nonatomic, readonly, nonnull) DBFILESMetadata * metadata;

+ (instancetype _Nullable)changeUsingMetadata:(DBFILESMetadata * _Nonnull)metadata;
- (NSURL * _Nullable)localURLUsingBaseURL:(NSURL * _Nonnull)baseURL;

+ (instancetype _Nonnull)new __unavailable;
- (id _Nonnull) init __unavailable;

@end

//
//  TBDropboxDeletedEntry+Private.h
//  Pods
//
//  Created by Bucha Kanstantsin on 3/13/17.
//
//

#import "TBDropboxDeletedEntry.h"

#ifndef TBDropboxDeletedEntry_Private_h
#define TBDropboxDeletedEntry_Private_h

@interface TBDropboxDeletedEntry ()

@property (assign, nonatomic, readwrite) TBDropboxEntrySource source;

@property (copy, nonatomic, readwrite, nonnull) NSString * dropboxPath;
@property (copy, nonatomic, readwrite, nullable) NSNumber * size;

@property (strong, nonatomic, readwrite, nullable) DBFILESMetadata * metadata;


- (instancetype _Nullable)initInstance;

@end

#endif /* TBDropboxDeletedEntry_Private_h */

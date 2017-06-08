//
//  TBDropboxEntry+Private.h
//  Pods
//
//  Created by Bucha Kanstantsin on 2/22/17.
//
//

#import "TBDropboxFileEntry.h"

#ifndef TBDropboxFileEntry_Private_h
#define TBDropboxFileEntry_Private_h

@interface TBDropboxFileEntry ()

@property (assign, nonatomic, readwrite) TBDropboxEntrySource source;

@property (copy, nonatomic, readwrite, nonnull) NSString * dropboxPath;
@property (copy, nonatomic, readwrite, nullable) NSNumber * size;

@property (strong, nonatomic, readwrite, nullable) DBFILESMetadata * metadata;


- (instancetype _Nullable)initInstance;

@end

#endif /* TBDropboxFileEntry_Private_h */

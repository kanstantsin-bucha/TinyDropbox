//
//  TBDropboxFolderEntry+Private.h
//  Pods
//
//  Created by Bucha Kanstantsin on 2/8/17.
//
//

#ifndef TBDropboxFolderEntry_Private_h
#define TBDropboxFolderEntry_Private_h

#import "TBDropboxFolderEntry.h"

@interface TBDropboxFolderEntry ()

@property (assign, nonatomic, readwrite) TBDropboxEntrySource source;

@property (copy, nonatomic, readwrite, nonnull) NSString * dropboxPath;
@property (copy, nonatomic, readwrite, nullable) NSNumber * size;

@property (strong, nonatomic, readwrite, nullable) DBFILESMetadata * metadata;

- (instancetype _Nullable)initInstance;

@end

#endif /* TBDropboxFolderEntry_Private_h */

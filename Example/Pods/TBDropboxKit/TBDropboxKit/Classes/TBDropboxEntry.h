//
//  TBDropboxEntry.h
//  Pods
//
//  Created by Bucha Kanstantsin on 2/24/17.
//
//

#ifndef TBDropboxEntry_h
#define TBDropboxEntry_h

#import "TBDropbox.h"

@protocol TBDropboxEntry <NSObject>

@property (assign, nonatomic, readonly) TBDropboxEntrySource source;

@property (copy, nonatomic, readonly, nonnull) NSString * fileName;
@property (copy, nonatomic, readonly, nonnull) NSString * dropboxPath;
@property (copy, nonatomic, readonly, nonnull) NSString * readablePath;
@property (copy, nonatomic, readonly, nullable) NSNumber * size;

@property (strong, nonatomic, readonly, nullable) DBFILESMetadata * metadata;

@end

#endif /* TBDropboxEntry_h */

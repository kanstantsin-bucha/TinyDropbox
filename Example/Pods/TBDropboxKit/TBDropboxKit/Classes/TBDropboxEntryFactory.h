//
//  TBDropboxEntryFactory.h
//  Pods
//
//  Created by Bucha Kanstantsin on 2/23/17.
//
//

#import <Foundation/Foundation.h>
#import "TBDropboxFileEntry.h"
#import "TBDropboxFolderEntry.h"



@interface TBDropboxEntryFactory : NSObject

+ (id<TBDropboxEntry> _Nullable)entryUsingMetadata:(DBFILESMetadata * _Nonnull)metadata;
+ (TBDropboxFileEntry * _Nullable)fileEntryUsingDropboxPath:(NSString * _Nonnull)path;
+ (TBDropboxFolderEntry * _Nullable)folderEntryUsingDropboxPath:(NSString * _Nullable)path;
+ (TBDropboxFileEntry * _Nullable)fileEntryByMirroringLocalURL: (NSURL * _Nonnull) fileURL
                                                  usingBaseURL: (NSURL * _Nonnull) baseURL;
+ (TBDropboxFolderEntry * _Nullable)folderEntryByMirroringLocalURL: (NSURL * _Nonnull) fileURL
                                                      usingBaseURL: (NSURL * _Nonnull) baseURL;

+ (NSArray<id<TBDropboxEntry>> * _Nullable)entriesUsingMetadata:(NSArray<DBFILESMetadata *> * _Nonnull)metadataEntries;

@end

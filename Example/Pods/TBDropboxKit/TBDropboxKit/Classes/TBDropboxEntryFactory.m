//
//  TBDropboxEntryFactory.m
//  Pods
//
//  Created by Bucha Kanstantsin on 2/23/17.
//
//

#import "TBDropboxEntryFactory.h"
#import "TBDropboxEntry.h"
#import "TBDropboxFileEntry+Private.h"
#import "TBDropboxFolderEntry+Private.h"
#import "TBDropboxDeletedEntry+Private.h"


@implementation TBDropboxEntryFactory

+ (TBDropboxFileEntry *)fileEntryUsingDropboxPath:(NSString *)path {
    if (path.length == 0
        || [path hasSuffix:@"/"]) {
        return nil;
    }
    
    TBDropboxFileEntry * result = [[TBDropboxFileEntry alloc] initInstance];
    result.source = TBDropboxEntrySourcePath;
    result.dropboxPath = path;
    return result;
}

+ (TBDropboxFileEntry *)fileEntryUsingMetadata:(DBFILESFileMetadata *)metadata {
    if (metadata == nil) {
        return nil;
    }

    TBDropboxFileEntry * result = [[TBDropboxFileEntry alloc] initInstance];
    
    result.source = TBDropboxEntrySourceMetadata;
    result.dropboxPath = metadata.pathDisplay;
    result.size = metadata.size;
    result.metadata = metadata;
    
    return result;
}

+ (TBDropboxFolderEntry *)folderEntryUsingDropboxPath:(NSString *)path {
    NSString * dropboxPath = [self folderPathUsingProvidedPath: path];
    if (dropboxPath == nil) {
        return nil;
    }
    
    TBDropboxFolderEntry * result = [[TBDropboxFolderEntry alloc] initInstance];
    result.source = TBDropboxEntrySourcePath;
    result.dropboxPath = dropboxPath;
    return result;
}


+ (TBDropboxFolderEntry *)folderEntryUsingMetadata:(DBFILESFolderMetadata *)metadata {
    if (metadata == nil) {
        return nil;
    }
    
    TBDropboxFolderEntry * result = [[TBDropboxFolderEntry alloc] initInstance];

    result.source = TBDropboxEntrySourceMetadata;
    result.dropboxPath = metadata.pathDisplay;
    result.metadata = metadata;
    
    return result;
}

+ (TBDropboxDeletedEntry *)deletedEntryUsingMetadata:(DBFILESDeletedMetadata *)metadata {
    if (metadata == nil) {
        return nil;
    }
    
    TBDropboxDeletedEntry * result = [[TBDropboxDeletedEntry alloc] initInstance];
    
    result.source = TBDropboxEntrySourceMetadata;
    result.dropboxPath = metadata.pathDisplay;
    result.metadata = metadata;
    
    return result;
}

+ (id<TBDropboxEntry>)entryUsingMetadata:(DBFILESMetadata *)metadata {
    id<TBDropboxEntry> result = nil;
    
    if ([metadata isKindOfClass:[DBFILESDeletedMetadata class]]) {
        result = [self deletedEntryUsingMetadata: (DBFILESDeletedMetadata *)metadata];
    }
    if ([metadata isKindOfClass:[DBFILESFileMetadata class]]) {
        result = [self fileEntryUsingMetadata: (DBFILESFileMetadata *) metadata];
    }
    
    if ([metadata isKindOfClass:[DBFILESFolderMetadata class]]) {
        result = [self folderEntryUsingMetadata: (DBFILESFolderMetadata *) metadata];
    }
    
    return result;
}

+ (NSArray<id<TBDropboxEntry>> *)entriesUsingMetadata:(NSArray<DBFILESMetadata *> * _Nonnull)metadataEntries {
    NSMutableArray * result = [NSMutableArray array];
    for (DBFILESMetadata * metadata in metadataEntries) {
        id<TBDropboxEntry> entry = [TBDropboxEntryFactory entryUsingMetadata: metadata];
        if (entry == nil) {
            NSLog(@"[ERROR] Could not create entry using metadata: %@", metadata);
            continue;
        }
        
        [result addObject: entry];
    }
    
    return [result copy];
}

/// MARK: - private -

+ (TBDropboxFileEntry *)fileEntryByMirroringLocalURL:(NSURL *)fileURL
                                        usingBaseURL:(NSURL *)baseURL {
    if ([fileURL.absoluteString hasSuffix: @"/"]) {
        return nil;
    }
    
    NSString * dropboxPath = [self relativeURLStringFromURL: fileURL
                                               usingBaseURL: baseURL];
    
    TBDropboxFileEntry * result = [self fileEntryUsingDropboxPath:dropboxPath];
    return result;
}

+ (TBDropboxFolderEntry *)folderEntryByMirroringLocalURL: (NSURL *) fileURL
                                            usingBaseURL: (NSURL *) baseURL {
    if ([fileURL.absoluteString hasSuffix: @"/"] == NO) {
        return nil;
    }
    
    NSString * dropboxPath = [self relativeURLStringFromURL: fileURL
                                               usingBaseURL: baseURL];
    
    TBDropboxFolderEntry * result = [self folderEntryUsingDropboxPath: dropboxPath];
    return result;
}


+ (NSString *)relativeURLStringFromURL:(NSURL *)URL
                          usingBaseURL:(NSURL *)baseURL {
    NSRange baseRange = [URL.path rangeOfString: baseURL.path];
    NSInteger relativeURLstartIndex = NSMaxRange(baseRange);
    if (baseRange.location == NSNotFound
        ||  relativeURLstartIndex >= URL.path.length) {
        return nil;
    }
    
    NSString * result = [URL.path substringFromIndex: relativeURLstartIndex];
    return result;
}

+ (NSString *)folderPathUsingProvidedPath:(NSString *)path {
    if (path == nil) {
        return TBDropboxFolderEntry_Root_Folder_Path;
    }
    
    if (path.length == 0) {
        return nil;
    }
    
    // dropbox requrements
    if ([path hasPrefix: @"/"] == NO) {
        return nil;
    }
    
    return path;
}

@end

//
//  TBDropboxChange.h
//  Pods
//
//  Created by Bucha Kanstantsin on 3/13/17.
//
//

#import <Foundation/Foundation.h>
#import "TBDropbox.h"
#import "TBDropboxTask.h"
#import "TBDropboxChange.h"


@interface TBDropboxChangesProcessor : NSObject

+ (NSArray <TBDropboxChange *> *)changesUsingMetadataCahnges:(NSArray <DBFILESMetadata *> *)changes;

+ (NSArray <DBFILESMetadata *> *)processMetadataChanges:(NSArray <DBFILESMetadata *> *)changes
                                    byExcludingOutgoing:(NSDictionary <NSString *, DBFILESMetadata *> *)outgoingChanges;

+ (NSDictionary <NSString *, DBFILESMetadata *> *)outgoingMetadataChangesUsingTasks:(NSArray<TBDropboxTask *> *)tasks;

@end

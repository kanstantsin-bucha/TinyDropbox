## TBDropboxKit

Released in april and used gracefully in app store already

[![CI Status](http://img.shields.io/travis/truebucha/TBDropboxKit.svg?style=flat)](https://travis-ci.org/truebucha/TBDropboxKit)
[![Version](https://img.shields.io/cocoapods/v/TBDropboxKit.svg?style=flat)](http://cocoapods.org/pods/TBDropboxKit)
[![License](https://img.shields.io/cocoapods/l/TBDropboxKit.svg?style=flat)](http://cocoapods.org/pods/TBDropboxKit)
[![Platform](https://img.shields.io/cocoapods/p/TBDropboxKit.svg?style=flat)](http://cocoapods.org/pods/TBDropboxKit)

## Brief 

  Stable version, core updated to ObjectiveDropboxOfficial 3.1.1.
  This framework provide basic two way synchronization functionality for dropbox and changes nofification in both ways.
  It uses official dropbox API version 2 under the hood. It smoothes broken changes that official guys do every release.
  It was written using SOLID principles in DRY mode

## Example

1) initiate dropbox after application will launch
```
self.dropbox = [TBDropboxClient sharedInstance];
// passing YES to ConnectionDesired makes it connect instantly
// use NO if you want connect after some onthe services will start or 
// based on application settings like I do in this example
[self.dropbox initiateWithConnectionDesired: self.settings.syncType == AppSyncDropbox
                                usingAppKey: self.dropboxAppKey];
[self.dropbox addDelegate: self];

// you could use some specific settings to make framework log more events
self.dropbox.tasksQueue.batchSize = QM_Dropbox_Queue_Batch_Size;
self.dropbox.watchdog.logger.logLevel = TBLogLevelInfo;
self.dropbox.connection.logger.logLevel = TBLogLevelVerbose;
self.dropbox.logger.logLevel = TBLogLevelInfo;
```
2) implement this delegate's methods
```
#pragma mark - TBDropboxClientDelegate -

#pragma mark TBDropboxClient

- (void)client:(TBDropboxClient *)client
    didReceiveIncomingChanges:(NSArray<TBDropboxChange *> *)changes {    
     // get your sinchronized documents base url
    NSArray * URLs = [[NSFileManager defaultManager] URLsForDirectory: NSDocumentDirectory
                                                            inDomains: NSUserDomainMask];
    NSURL * baseURL = URLs.lastObject;

    for (TBDropboxChange * change in changes) {
        NSURL * itemURL = [change localURLUsingBaseURL: baseURL];
        NSLog(@"%@", change);
        switch (change.action) {
            case TBDropboxChangeActionUpdateFile: {
                [self dropboxSyncChangedDocumentAtURL: itemURL
                                          dropboxPath: change.dropboxPath
                                           completion: ^(NSError * _Nullable error) {
                      if (error != nil) {
                          NSLog(@"Dropbox local state Synchronization Failed %@", error);
                          return;
                      }
                      // update ui
                      //[self handleDidChangeDocumentAtURL: itemURL];  
                  }];
            }   break;
            case TBDropboxChangeActionDelete: {
                // delete file and update ui
                //[self handleDidRemoveDocumentAtURL: itemURL];
               
            }   break;
            case TBDropboxChangeActionUpdateFolder: {
                // Do nothing for created folders,
                // will create them when files appears inside
            }   break;
            default: {
                NSLog(@" acquire unsupported action in Dropbox change = %@",
                change);
            }   break;
        }
    }
}

#pragma mark TBDropboxConnectionDelegate

- (void)dropboxConnection:(TBDropboxConnection *)connection
         didChangeStateTo:(TBDropboxConnectionState)state {
    switch (connection.state) {
        case TBDropboxConnectionStateReconnected: {
            [self handleDropboxDidReconnect];
            // available notifications about server changes
            self.dropbox.watchdogEnabled = YES;
        }   break;
        case TBDropboxConnectionStateConnected: {
            [self handleDropboxDidConnect];
            // available notifications about server changes
            self.dropbox.watchdogEnabled = YES;
        }   break;
        case TBDropboxConnectionStatePaused:
        case TBDropboxConnectionStateDisconnected: {
            [self handleDropboxDidDisconnect];
            self.dropbox.watchdogEnabled = NO;
        }   break;
        case TBDropboxConnectionStateAuthorization: {
            
        }   break;
        case TBDropboxConnectionStateUndefined: {
            
        }   break;
        
        default:
            break;
    }
}

- (void)dropboxConnection:(TBDropboxConnection *)connection
     didChangeAuthStateTo:(TBDropboxAuthState)state
                withError:(NSError *)error {
    
}
```
3.) To upload/delete/move create a task then add it to the queue
```
using [self.dropbox.tasksQueue addTask: task];

- (TBDropboxUploadFileTask *)dropboxUploadTaskUsingDocumentURL:(NSURL *)documentURL
                                                       baseURL:(NSURL *)baseURL
                                                withCompletion:(CDBErrorCompletion)completion {
    TBDropboxFileEntry * entry =
        [TBDropboxEntryFactory fileEntryByMirroringLocalURL: documentURL
                                               usingBaseURL: baseURL];
    TBDropboxUploadFileTask * result =
        [TBDropboxUploadFileTask taskUsingEntry: entry
                                        fileURL: documentURL
                                     completion: ^(TBDropboxTask * _Nonnull task,
                                                   NSError * _Nullable error) {
        if (completion != nil) {
            completion(error);
        }
    }];
    
    return result;
}

- (TBDropboxDeleteEntryTask *)dropboxDeleteTaskUsingDocumentURL:(NSURL *)documentURL
                                                        baseURL:(NSURL *)baseURL
                                                 withCompletion:(CDBErrorCompletion)completion {
    TBDropboxFileEntry * entry =
    [TBDropboxEntryFactory fileEntryByMirroringLocalURL: documentURL
                                           usingBaseURL: baseURL];
    TBDropboxDeleteEntryTask * result =
        [TBDropboxDeleteEntryTask taskUsingEntry: entry
                                      completion: ^(TBDropboxTask * _Nonnull task,
                                                    NSError * _Nullable error) {
        completion(error);
    }];
    
    return result;
}

- (TBDropboxMoveEntryTask *)dropboxMoveTaskUsingDocumentURL:(NSURL *)documentURL
                                             destinationURL:(NSURL *)destinationURL
                                                    baseURL:(NSURL *)baseURL
                                             withCompletion:(CDBErrorCompletion)completion {
    TBDropboxFileEntry * entry =
        [TBDropboxEntryFactory fileEntryByMirroringLocalURL: documentURL
                                               usingBaseURL: baseURL];
    TBDropboxFileEntry * destinationEntry =
        [TBDropboxEntryFactory fileEntryByMirroringLocalURL: destinationURL
                                               usingBaseURL: baseURL];
    TBDropboxMoveEntryTask * result =
        [TBDropboxMoveEntryTask taskUsingEntry: entry
                              destinationEntry: destinationEntry
                                    completion: ^(TBDropboxTask * _Nonnull task,
                                                   NSError * _Nullable error) {
        completion(error);
    }];
    
    return result;
}
```
4.) Sync incoming changes & Download
```
- (void)dropboxSyncChangedDocumentAtURL:(NSURL *)URL
                            dropboxPath:(NSString *)path
                             completion:(CDBErrorCompletion)completion {
    if (self.dropbox.connection.connected == NO) {
        if (completion != nil){
       	 	NSString * description =
        		[NSString stringWithFormat: @"Failed to proceed with disconnected dropbox\
              		                        \r document URL: %@", URL];
   			    NSError * error = [NSError errorWithDomain: NSStringFromClass([self class])
                                        		      code: 4
                                    		      userInfo: @{ NSLocalizedDescriptionKey: description }];
            completion(error);
        }
        return;
    }
    
    TBDropboxFileEntry * entry =
        [TBDropboxEntryFactory fileEntryUsingDropboxPath: path];
    TBDropboxTask * downloadTask =
        [TBDropboxDownloadFileTask taskUsingEntry: entry
                                          fileURL: URL
                                       completion: ^(TBDropboxTask * _Nonnull task, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"FAILED dropboxSyncChangedDocumentAtURL: %@\
                       /r Dropbox path %@", URL, path);
        }
        if (completion != nil) {
            completion(error);
        }
    }];
    
    if (downloadTask == nil) {
        NSLog(@"FAILED create task for dropboxSyncChangedDocumentAtURL: %@\
                   \r Dropbox path: %@", URL, path);
    }
    
    [self.dropbox.tasksQueue addTask: downloadTask];
}
```
5.) Cleanup
```
- (void)cleanupDropboxAppContainerWithCompletion:(CDBErrorCompletion _Nonnull)completion {
    TBDropboxFolderEntry * rootEntry = [TBDropboxEntryFactory folderEntryUsingDropboxPath:nil];
    TBDropboxListFolderTask * cleanupTask =
        [TBDropboxListFolderTask taskUsingEntry: rootEntry
                                     completion: ^(TBDropboxTask * _Nonnull task,
                                                   NSError * _Nullable error) {
         NSArray * entries = [(TBDropboxListFolderTask *)task folderEntries];
         
         if (entries.count == 0) {
             if (completion != nil) {
                 completion(nil);
             }
             return;
         }
         
         __block NSUInteger counter = 0;
         __block NSUInteger count = entries.count;
         __block NSError * deleteError = nil;
         
         for (id<TBDropboxEntry> deleteEntry in entries) {
             TBDropboxDeleteEntryTask * deleteTask =
                [TBDropboxDeleteEntryTask taskUsingEntry: deleteEntry
                                              completion: ^(TBDropboxTask * _Nonnull task, NSError * _Nullable error) {
                    counter++;
                    if (deleteError != nil) {
                        deleteError = error;
                    }

                    if (counter == count
                        && completion != nil) {
                        completion(error);
                    }
                }];
             
             [self.dropbox.tasksQueue addTask: deleteTask];
         }
    }];
    
    if (cleanupTask == nil
        && completion != nil) {
        NSDictionary * info = @{NSLocalizedDescriptionKey : @"Clean up root folder task failed"};
        NSError * error = 
        	[NSError errorWithDomain: NSStringFromClass([self class])
                                code: 1
                            userInfo: info];
        completion(error);
    }
    
    [self.dropbox.tasksQueue addTask: cleanupTask];
}
```
To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

TBDropboxKit is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "TBDropboxKit"
```

## Author

truebucha, Kanstantsin Bucha truebucha@gmail.com

## License

TBDropboxKit is available under the MIT license. See the LICENSE file for more info.

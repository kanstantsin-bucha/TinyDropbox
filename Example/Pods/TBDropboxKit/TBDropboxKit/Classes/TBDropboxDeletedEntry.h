//
//  TBDropboxDeletedEntry.h
//  Pods
//
//  Created by Bucha Kanstantsin on 3/13/17.
//
//

#import <Foundation/Foundation.h>
#import "TBDropboxEntry.h"
#import "TBDropbox.h"


@interface TBDropboxDeletedEntry : NSObject<TBDropboxEntry>

+ (instancetype)new __unavailable;
- (id) init __unavailable;

@end

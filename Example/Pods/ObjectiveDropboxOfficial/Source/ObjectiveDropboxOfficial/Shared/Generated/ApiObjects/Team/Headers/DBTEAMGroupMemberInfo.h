///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///
/// Auto-generated by Stone, do not modify.
///

#import <Foundation/Foundation.h>

#import "DBSerializableProtocol.h"

@class DBTEAMGroupAccessType;
@class DBTEAMGroupMemberInfo;
@class DBTEAMMemberProfile;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - API Object

///
/// The `GroupMemberInfo` struct.
///
/// Profile of group member, and role in group.
///
/// This class implements the `DBSerializable` protocol (serialize and
/// deserialize instance methods), which is required for all Obj-C SDK API route
/// objects.
///
@interface DBTEAMGroupMemberInfo : NSObject <DBSerializable, NSCopying>

#pragma mark - Instance fields

/// Profile of group member.
@property (nonatomic, readonly) DBTEAMMemberProfile *profile;

/// The role that the user has in the group.
@property (nonatomic, readonly) DBTEAMGroupAccessType *accessType;

#pragma mark - Constructors

///
/// Full constructor for the struct (exposes all instance variables).
///
/// @param profile Profile of group member.
/// @param accessType The role that the user has in the group.
///
/// @return An initialized instance.
///
- (instancetype)initWithProfile:(DBTEAMMemberProfile *)profile accessType:(DBTEAMGroupAccessType *)accessType;

- (instancetype)init NS_UNAVAILABLE;

@end

#pragma mark - Serializer Object

///
/// The serialization class for the `GroupMemberInfo` struct.
///
@interface DBTEAMGroupMemberInfoSerializer : NSObject

///
/// Serializes `DBTEAMGroupMemberInfo` instances.
///
/// @param instance An instance of the `DBTEAMGroupMemberInfo` API object.
///
/// @return A json-compatible dictionary representation of the
/// `DBTEAMGroupMemberInfo` API object.
///
+ (nullable NSDictionary<NSString *, id> *)serialize:(DBTEAMGroupMemberInfo *)instance;

///
/// Deserializes `DBTEAMGroupMemberInfo` instances.
///
/// @param dict A json-compatible dictionary representation of the
/// `DBTEAMGroupMemberInfo` API object.
///
/// @return An instantiation of the `DBTEAMGroupMemberInfo` object.
///
+ (DBTEAMGroupMemberInfo *)deserialize:(NSDictionary<NSString *, id> *)dict;

@end

NS_ASSUME_NONNULL_END

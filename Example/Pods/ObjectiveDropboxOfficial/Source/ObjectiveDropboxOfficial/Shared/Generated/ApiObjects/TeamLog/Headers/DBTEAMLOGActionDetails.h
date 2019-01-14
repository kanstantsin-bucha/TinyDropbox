///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///
/// Auto-generated by Stone, do not modify.
///

#import <Foundation/Foundation.h>

#import "DBSerializableProtocol.h"

@class DBTEAMLOGActionDetails;
@class DBTEAMLOGJoinTeamDetails;
@class DBTEAMLOGMemberRemoveActionType;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - API Object

///
/// The `ActionDetails` union.
///
/// Additional information indicating the action taken that caused status
/// change.
///
/// This class implements the `DBSerializable` protocol (serialize and
/// deserialize instance methods), which is required for all Obj-C SDK API route
/// objects.
///
@interface DBTEAMLOGActionDetails : NSObject <DBSerializable, NSCopying>

#pragma mark - Instance fields

/// The `DBTEAMLOGActionDetailsTag` enum type represents the possible tag states
/// with which the `DBTEAMLOGActionDetails` union can exist.
typedef NS_ENUM(NSInteger, DBTEAMLOGActionDetailsTag) {
  /// Additional information relevant when a new member joins the team.
  DBTEAMLOGActionDetailsTeamJoinDetails,

  /// Define how the user was removed from the team.
  DBTEAMLOGActionDetailsRemoveAction,

  /// (no description).
  DBTEAMLOGActionDetailsOther,

};

/// Represents the union's current tag state.
@property (nonatomic, readonly) DBTEAMLOGActionDetailsTag tag;

/// Additional information relevant when a new member joins the team. @note
/// Ensure the `isTeamJoinDetails` method returns true before accessing,
/// otherwise a runtime exception will be raised.
@property (nonatomic, readonly) DBTEAMLOGJoinTeamDetails *teamJoinDetails;

/// Define how the user was removed from the team. @note Ensure the
/// `isRemoveAction` method returns true before accessing, otherwise a runtime
/// exception will be raised.
@property (nonatomic, readonly) DBTEAMLOGMemberRemoveActionType *removeAction;

#pragma mark - Constructors

///
/// Initializes union class with tag state of "team_join_details".
///
/// Description of the "team_join_details" tag state: Additional information
/// relevant when a new member joins the team.
///
/// @param teamJoinDetails Additional information relevant when a new member
/// joins the team.
///
/// @return An initialized instance.
///
- (instancetype)initWithTeamJoinDetails:(DBTEAMLOGJoinTeamDetails *)teamJoinDetails;

///
/// Initializes union class with tag state of "remove_action".
///
/// Description of the "remove_action" tag state: Define how the user was
/// removed from the team.
///
/// @param removeAction Define how the user was removed from the team.
///
/// @return An initialized instance.
///
- (instancetype)initWithRemoveAction:(DBTEAMLOGMemberRemoveActionType *)removeAction;

///
/// Initializes union class with tag state of "other".
///
/// @return An initialized instance.
///
- (instancetype)initWithOther;

- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Tag state methods

///
/// Retrieves whether the union's current tag state has value
/// "team_join_details".
///
/// @note Call this method and ensure it returns true before accessing the
/// `teamJoinDetails` property, otherwise a runtime exception will be thrown.
///
/// @return Whether the union's current tag state has value "team_join_details".
///
- (BOOL)isTeamJoinDetails;

///
/// Retrieves whether the union's current tag state has value "remove_action".
///
/// @note Call this method and ensure it returns true before accessing the
/// `removeAction` property, otherwise a runtime exception will be thrown.
///
/// @return Whether the union's current tag state has value "remove_action".
///
- (BOOL)isRemoveAction;

///
/// Retrieves whether the union's current tag state has value "other".
///
/// @return Whether the union's current tag state has value "other".
///
- (BOOL)isOther;

///
/// Retrieves string value of union's current tag state.
///
/// @return A human-readable string representing the union's current tag state.
///
- (NSString *)tagName;

@end

#pragma mark - Serializer Object

///
/// The serialization class for the `DBTEAMLOGActionDetails` union.
///
@interface DBTEAMLOGActionDetailsSerializer : NSObject

///
/// Serializes `DBTEAMLOGActionDetails` instances.
///
/// @param instance An instance of the `DBTEAMLOGActionDetails` API object.
///
/// @return A json-compatible dictionary representation of the
/// `DBTEAMLOGActionDetails` API object.
///
+ (nullable NSDictionary<NSString *, id> *)serialize:(DBTEAMLOGActionDetails *)instance;

///
/// Deserializes `DBTEAMLOGActionDetails` instances.
///
/// @param dict A json-compatible dictionary representation of the
/// `DBTEAMLOGActionDetails` API object.
///
/// @return An instantiation of the `DBTEAMLOGActionDetails` object.
///
+ (DBTEAMLOGActionDetails *)deserialize:(NSDictionary<NSString *, id> *)dict;

@end

NS_ASSUME_NONNULL_END

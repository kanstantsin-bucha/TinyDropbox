///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///
/// Auto-generated by Stone, do not modify.
///

#import <Foundation/Foundation.h>

#import "DBSerializableProtocol.h"

@class DBTEAMLOGSignInAsSessionStartDetails;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - API Object

///
/// The `SignInAsSessionStartDetails` struct.
///
/// Started admin sign-in-as session.
///
/// This class implements the `DBSerializable` protocol (serialize and
/// deserialize instance methods), which is required for all Obj-C SDK API route
/// objects.
///
@interface DBTEAMLOGSignInAsSessionStartDetails : NSObject <DBSerializable, NSCopying>

#pragma mark - Instance fields

#pragma mark - Constructors

///
/// Full constructor for the struct (exposes all instance variables).
///
/// @return An initialized instance.
///
- (instancetype)initDefault;

- (instancetype)init NS_UNAVAILABLE;

@end

#pragma mark - Serializer Object

///
/// The serialization class for the `SignInAsSessionStartDetails` struct.
///
@interface DBTEAMLOGSignInAsSessionStartDetailsSerializer : NSObject

///
/// Serializes `DBTEAMLOGSignInAsSessionStartDetails` instances.
///
/// @param instance An instance of the `DBTEAMLOGSignInAsSessionStartDetails`
/// API object.
///
/// @return A json-compatible dictionary representation of the
/// `DBTEAMLOGSignInAsSessionStartDetails` API object.
///
+ (NSDictionary *)serialize:(DBTEAMLOGSignInAsSessionStartDetails *)instance;

///
/// Deserializes `DBTEAMLOGSignInAsSessionStartDetails` instances.
///
/// @param dict A json-compatible dictionary representation of the
/// `DBTEAMLOGSignInAsSessionStartDetails` API object.
///
/// @return An instantiation of the `DBTEAMLOGSignInAsSessionStartDetails`
/// object.
///
+ (DBTEAMLOGSignInAsSessionStartDetails *)deserialize:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
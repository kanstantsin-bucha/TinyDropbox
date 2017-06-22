///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///
/// Auto-generated by Stone, do not modify.
///

#import <Foundation/Foundation.h>

#import "DBSerializableProtocol.h"

@class DBFILESPreviewArg;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - API Object

///
/// The `PreviewArg` struct.
///
/// This class implements the `DBSerializable` protocol (serialize and
/// deserialize instance methods), which is required for all Obj-C SDK API route
/// objects.
///
@interface DBFILESPreviewArg : NSObject <DBSerializable, NSCopying>

#pragma mark - Instance fields

/// The path of the file to preview.
@property (nonatomic, readonly, copy) NSString *path;

/// Deprecated. Please specify revision in path instead.
@property (nonatomic, readonly, copy, nullable) NSString *rev;

#pragma mark - Constructors

///
/// Full constructor for the struct (exposes all instance variables).
///
/// @param path The path of the file to preview.
/// @param rev Deprecated. Please specify revision in path instead.
///
/// @return An initialized instance.
///
- (instancetype)initWithPath:(NSString *)path rev:(nullable NSString *)rev;

///
/// Convenience constructor (exposes only non-nullable instance variables with
/// no default value).
///
/// @param path The path of the file to preview.
///
/// @return An initialized instance.
///
- (instancetype)initWithPath:(NSString *)path;

- (instancetype)init NS_UNAVAILABLE;

@end

#pragma mark - Serializer Object

///
/// The serialization class for the `PreviewArg` struct.
///
@interface DBFILESPreviewArgSerializer : NSObject

///
/// Serializes `DBFILESPreviewArg` instances.
///
/// @param instance An instance of the `DBFILESPreviewArg` API object.
///
/// @return A json-compatible dictionary representation of the
/// `DBFILESPreviewArg` API object.
///
+ (NSDictionary *)serialize:(DBFILESPreviewArg *)instance;

///
/// Deserializes `DBFILESPreviewArg` instances.
///
/// @param dict A json-compatible dictionary representation of the
/// `DBFILESPreviewArg` API object.
///
/// @return An instantiation of the `DBFILESPreviewArg` object.
///
+ (DBFILESPreviewArg *)deserialize:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
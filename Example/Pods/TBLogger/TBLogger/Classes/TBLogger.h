//
//  TBLogger.h
//  Pods
//
//  Created by Bucha Kanstantsin on 2/11/17.
//
//

typedef NS_ENUM(NSUInteger, TBLogLevel) {
    TBLogLevelVerbose = 0,
    TBLogLevelInfo = 1,
    TBLogLevelLog = 2,
    TBLogLevelWarning = 3,
    TBLogLevelError = 4,
    TBLogLevelSilent = 5,
};

//      [levelDescription] loggerName logMessage
#define dTBLogDefaultFormat @"[%@] %@: %@\r"


@interface TBLogger : NSObject

/**
 @brief: shown after level description mark - [levelDescription] loggerName logMessage
 @see dTBLogInitialFormat
 **/

@property (copy, nonatomic, readonly, nullable) NSString * loggerName;

/**
 @brief: accepts 3 objects - [levelDescription] loggerName logMessage
 @see dTBLogInitialFormat
 **/

@property (copy, nonatomic, nonnull) NSString * logFormatString;

/**
 @brief: set desired log level
         defaul value is TBLogLevelLog
**/

@property (assign, nonatomic) TBLogLevel logLevel;

+ (instancetype _Nonnull)loggerWithName:(NSString * _Nullable)name;
                                
- (instancetype _Nonnull)init __unavailable;
+ (instancetype _Nonnull)new __unavailable;

- (void)verbose:(NSString * _Nullable)format, ... NS_FORMAT_FUNCTION(1,2);
- (void)info:(NSString * _Nullable)format, ... NS_FORMAT_FUNCTION(1,2);
- (void)log:(NSString * _Nullable)format, ... NS_FORMAT_FUNCTION(1,2);
- (void)warning:(NSString * _Nullable)format, ... NS_FORMAT_FUNCTION(1,2);
- (void)error:(NSString * _Nullable)format, ... NS_FORMAT_FUNCTION(1,2);

/**
 @brief: in case you want provide your own level description
         add localized strings for VERBOSE, INFO, LOG, WARNING, ERROR
         or
         inherite your class from TBLogger and override this method
 @see TBLogLevel
 **/

- (NSString * _Nonnull)localizedDescriptionUsingLogLevel:(TBLogLevel)level;

@end

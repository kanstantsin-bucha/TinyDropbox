//
//  TBDropboxConnection.m
//  Pods
//
//  Created by Bucha Kanstantsin on 12/12/2016.
//
//

#import "TBDropboxConnection+Private.h"


#define AccessTokenUIDKey @"TB.TBDropboxConnection.AccessToken.UID=NSString"


@interface TBDropboxConnection ()

@property (assign, nonatomic, readwrite) TBDropboxConnectionState state;
@property (copy, nonatomic, readwrite) NSString * accessTokenUID;
@property (assign, nonatomic, readwrite) BOOL connected;

@property (strong, nonatomic, readwrite) TBLogger * logger;

@end


@implementation TBDropboxConnection

@synthesize accessTokenUID = _accessTokenUID;

/// MARK: property

- (TBLogger *)logger {
    if (_logger != nil) {
        return _logger;
    }
    _logger = [TBLogger loggerWithName: NSStringFromClass([self class])];
    _logger.logLevel = TBLogLevelWarning;
    return _logger;
}

- (void)setState:(TBDropboxConnectionState)state {
    [self.logger verbose: @"did receive %@", StringFromDropboxConnectionState(state)];
    if (_state == state) {
        return;
    }
    
    _state = state;
    
    if (self.connected) {
        [self noteChangedSessionID: self.accessTokenUID];
    }
    
    [self noteConnectionStateChanged: _state];
}

- (BOOL)connected {
    BOOL result = self.state == TBDropboxConnectionStateConnected
                  || self.state == TBDropboxConnectionStateReconnected;
    [self.logger info: @"did provide connected %@", NSStringFromBool(result)];
    return result;
}

- (void)setAccessTokenUID:(NSString *)tokenUID {
    [self.logger verbose: @"did receive store token UID %@", tokenUID];
    if (_accessTokenUID == tokenUID) {
        return;
    }
    _accessTokenUID = tokenUID;
    
    [self saveAccessTokenUID: tokenUID];
}

- (NSString *)accessTokenUID {
    if (_accessTokenUID != nil) {
        [self.logger info: @"did provide token UID %@", _accessTokenUID];
        return _accessTokenUID;
    }
    
    _accessTokenUID = [self loadPreviousAccessTokenUID];
    [self.logger log: @"did load token UID %@", _accessTokenUID];
    return _accessTokenUID;
}

/// MARK: life cycle

- (instancetype)initInstance {
    if (self = [super init]) {
    }
    return self;
}

+ (instancetype _Nullable)connectionUsingAppKey:(NSString * _Nonnull)key
                                       delegate:(id<TBDropboxConnectionDelegate> _Nonnull)delegate {
    if (key == nil) {
        key = [self apiKeyUsingInfoPlist];
    }
    
    NSAssert(key.length != 0, @"dropbox connection required app key");
    
    if (key == nil
        || delegate == nil) {
        NSLog(@"[ERROR] Failed to create connection with key:%@\rdelegate: %@", key, delegate);
        return nil;
    }
    
    TBDropboxConnection * result = [[[self class] alloc] initInstance];
    if (result == nil) {
        NSLog(@"[ERROR] Failed to create connection with key:%@\rdelegate: %@", key, delegate);
        return result;
    }

    [result subscribeToNotifications];

#ifdef __APPLE__
    #if TARGET_OS_OSX
        // Mac
        [DBClientsManager setupWithAppKeyDesktop: key];
    #elif TARGET_OS_IOS
        // iOS and simulator
        [DBClientsManager setupWithAppKey: key];
    #else
        // undefined
        
    #endif
#endif

    result.delegate = delegate;
    result.state = TBDropboxConnectionStateDisconnected;
    
    [result.logger warning: @"initiated %@", result];
    
    return result;
}

/// MARK: public

- (BOOL)handleAuthorisationRedirectURL:(NSURL *)url {
    [self.logger verbose: @"did receive handle auth URL %@", url];
    if (url == nil) {
        return NO;
    }
    
    NSString * dropboxScheme = [[self class] flatURLSchemesFromInfoPlist].firstObject;
    
    [self.logger info: @"did provide URL schemes: %@", dropboxScheme];
    
    if ([url.scheme isEqualToString:dropboxScheme] == NO) {
        [self.logger log: @"skipping url beacuse it is not a dropbox scheme URL %@", url];
        return NO;
    }
    
    BOOL result = [self handleDropboxAuthorisationRedirectURL:url];
    [self.logger warning: @"did handle auth URL: %@", NSStringFromBool(result)];
    return result;
}

/// MARK - protected -

- (void)openConnection {
    [self.logger verbose: @"did receive open connection"];
    
    if (self.state == TBDropboxConnectionStateAuthorization
        || self.connected) {
        
        [self.logger log: @"skipping open connection because already in state %@",
                          StringFromDropboxConnectionState(self.state)];
        return;
    }
    
    if ([DBClientsManager authorizedClient] != nil
        && [[DBClientsManager authorizedClient] isAuthorized]) {
        
        [self.logger log: @"open connection with authorized client %@", [DBClientsManager authorizedClient]];
        
        self.state = TBDropboxConnectionStateReconnected;
        return;
    }
    
    if (self.accessTokenUID != nil) {
        BOOL succeed = [DBClientsManager authorizeClientFromKeychain: self.accessTokenUID];
        if (succeed) {
            [self.logger log: @"open connection with reauthorized client %@ using token UID %@",
                              [DBClientsManager authorizedClient], self.accessTokenUID];
            
            self.state = TBDropboxConnectionStateReconnected;
            return;
        }
    }
    
    [self authorize];
}

- (void)closeConnection {
    [self.logger verbose: @"did receive close connection"];
    
    [DBClientsManager unlinkAndResetClients];
    self.accessTokenUID = nil;
    self.state = TBDropboxConnectionStateDisconnected;
    
    [self.logger log: @"did close connection"];
}

- (void)pauseConnection {
    [self.logger verbose: @"did receive pause connection"];
    
    self.state = TBDropboxConnectionStatePaused;
    
    [self.logger log: @"did pause connection"];
}

- (void)reauthorizeClient {
    [self.logger verbose: @"did receive reauthorize client"];
    
    [self.logger log: @"did reauthorize client with token UID %@", self.accessTokenUID];
    
    if (self.accessTokenUID != nil) {
        [self.logger info: @"clear access token %@/r with UID %@", self.accessTokenUID, self.accessTokenUID];
        [DBClientsManager unlinkAndResetClient: self.accessTokenUID];
        self.accessTokenUID = nil;
    }
    
    [self authorize];
}

/// MARK: notifications

- (void)subscribeToNotifications {
#ifdef __APPLE__
    #if TARGET_OS_OSX
        // Mac
    
    #elif TARGET_OS_IOS
        // iOS and simulator
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(appBecomeActive:)
                                                     name: UIApplicationDidBecomeActiveNotification
                                                   object: nil];
        
        [self.logger info: @"did subscribe to AppBecomeActive notification"];
    #else
        // undefined
        
    #endif
#endif
}

/// MARK: private

- (void)authorize {
    [self.logger warning: @"start authorization"];
    
    if (self.state == TBDropboxConnectionStateUndefined) {
        [self.logger warning: @"skipping authorize bacause invalid connection state"];
        return;
    }
    
#ifdef __APPLE__
    #if TARGET_OS_OSX
        // Mac
    
        void (^ openURL)(NSURL *) = ^(NSURL * url) {
            [self noteAuthStateChanged: TBDropboxAuthStateAuthorization];
            [[NSWorkspace sharedWorkspace] openURL: url];
            [self.logger log: @"did open auth url"];
            [self.logger verbose: @"auth url %@", url];
        };
        
        self.state = TBDropboxConnectionStateAuthorization;
        [self noteAuthStateChanged: TBDropboxAuthStateInitiated];
        
        NSViewController * authController = [NSViewController new];
        
        [DBClientsManager authorizeFromControllerDesktop: [NSWorkspace sharedWorkspace]
                                              controller: authController
                                                 openURL: openURL];
    #elif TARGET_OS_IOS
        // iOS and simulator
    
        void (^ openURL)(NSURL *) = ^(NSURL * url) {
            [self noteAuthStateChanged: TBDropboxAuthStateAuthorization];
            [[UIApplication sharedApplication] openURL: url];
            [self.logger log: @"did open auth url"];
            [self.logger verbose: @"auth url %@", url];
        };
        
        self.state = TBDropboxConnectionStateAuthorization;
        [self noteAuthStateChanged: TBDropboxAuthStateInitiated];
        
        [DBClientsManager authorizeFromController: [UIApplication sharedApplication]
                                       controller: [UIApplication sharedApplication].keyWindow.rootViewController
                                          openURL: openURL];
    #else
        // undefined
        
    #endif
#endif

    [self.logger log: @"did auth from controller"];
}

/// MARK: connection logic

- (void)appBecomeActive:(NSNotification *)notification {
    [self.logger verbose: @"did receive appBecomeActive notification"];
    if (self.state != TBDropboxConnectionStateAuthorization) {
        return;
    }
    
    [self.logger warning: @"did cancel auth that was pending in background"];
    
    self.state = TBDropboxConnectionStateDisconnected;
    [self noteAuthStateChanged: TBDropboxAuthStateCancelled];
}

/// MARK: note state changes

- (void)noteConnectionStateChanged:(TBDropboxConnectionState)state {
    [self.logger warning: @"did change to %@", StringFromDropboxConnectionState(state)];
    
    SEL stateChangeSEL = @selector(dropboxConnection:didChangeStateTo:);
    if ([self.delegate respondsToSelector: stateChangeSEL] == NO) {
        return;
    }
    
    [self.logger info: @"did provide %@ to %@", StringFromDropboxConnectionState(state), self.delegate];
    
    [self.delegate dropboxConnection: self
                    didChangeStateTo: self.state];
}

- (void)noteAuthStateChanged:(TBDropboxAuthState)state {
    [self noteAuthStateChanged: state
                         error: nil];
}

- (void)noteAuthStateChanged:(TBDropboxAuthState)state
                       error:(NSError *)error {
    [self.logger log: @"did change to %@", StringFromDropboxAuthState(state)];
    
    if (error != nil) {
        [self.logger error:@"auth error: %@", error];
    }
    
    SEL authStateChangeSEL = @selector(dropboxConnection:didChangeAuthStateTo:withError:);
    if ([self.delegate respondsToSelector: authStateChangeSEL] == NO) {
        return;
    }
    
    [self.logger info: @"did provide %@ to %@", StringFromDropboxAuthState(state), self.delegate];
    
    [self.delegate dropboxConnection: self
                didChangeAuthStateTo: state
                           withError: error];
}

/// MARK provide session ID

- (void)noteChangedSessionID:(NSString *)sessionID {
    
    [self.logger log: @"did change session id %@", sessionID];

    SEL selector = @selector(dropboxConnection:didChangeSessionID:);
    if ([self.delegate respondsToSelector: selector] == NO) {
        return;
    }
    
    [self.logger info: @"did provide session id %@ to %@", sessionID, self.delegate];
    
    [self.delegate dropboxConnection: self
                  didChangeSessionID: sessionID];
}

/// MARK: redirect URL

- (BOOL)handleDropboxAuthorisationRedirectURL:(NSURL *)url {

    [self.logger verbose: @"did receive auth redirect URL: %@", url];
    
    if (self.state != TBDropboxConnectionStateAuthorization) {
    
        [self.logger warning: @"skipping auth url bacause not in Auth state"];
        [self.logger verbose: @"auth URL: %@", url];
        
        return NO;
    }
    
    DBOAuthResult * authResult = [DBClientsManager handleRedirectURL: url];
    if (authResult == nil) {
        
        [self.logger error: @"failed parse auth url to authResult: %@", url];
    
        return NO;
    }
    
    if ([authResult isSuccess]) {
        NSString * incomingTokenUID = authResult.accessToken.uid;
        
        [self.logger log: @"handle auth URL: success auth"];
        [self.logger info: @"with incoming token uid %@", incomingTokenUID];
        
        if ([self.accessTokenUID isEqualToString: incomingTokenUID]) {
            self.state = TBDropboxConnectionStateReconnected;
        } else {
            self.accessTokenUID = authResult.accessToken.uid;
            self.state = TBDropboxConnectionStateConnected;
        }
        
        [self noteAuthStateChanged: TBDropboxAuthStateSucceed];
        
    } else if ([authResult isCancel]) {
    
        [self.logger log: @"handle auth URL: user cancel auth"];
        
        self.state = TBDropboxConnectionStateDisconnected;
        [self noteAuthStateChanged: TBDropboxAuthStateCancelled];
        
    } else if ([authResult isError]) {
        NSError * error = [self errorUsingAuthResult:authResult];
        
        [self.logger error: @"handle auth URL: auth error"];
        
        self.state = TBDropboxConnectionStateDisconnected;
        [self noteAuthStateChanged: TBDropboxAuthStateGotError
                             error: error];
    }
    
    return YES;
}

// MARK: dropbox url schemes

+ (NSString *)apiKeyUsingInfoPlist {
    NSArray * schemes = [self flatURLSchemesFromInfoPlist];
    NSString * schema = schemes.firstObject;
    if (schema == nil
        || schema.length < 4) {
        return nil;
    }
    
    NSString * result = [schema substringFromIndex:3];
    return result;
}

+ (NSArray *)flatURLSchemesFromInfoPlist {
    NSArray * URLTypes =
        [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleURLTypes"];
    
    NSArray * result = [self flatURLSchemesUsingURLTypes: URLTypes];
    return result;
}

+ (NSArray *)flatURLSchemesUsingURLTypes:(NSArray *)types {
    NSMutableArray * schemes = [NSMutableArray array];
    for (NSDictionary * type in types) {
        NSArray * typeSchemes = type[@"CFBundleURLSchemes"];
        if (typeSchemes.count == 0) {
            continue;
        }
        
        [schemes addObjectsFromArray: typeSchemes];
    }
    
    if (schemes.count == 0) {
        return nil;
    }
    
    NSPredicate * dropboxSchemePredicate =
        [NSPredicate predicateWithFormat: @"SELF BEGINSWITH[cd] %@", @"db-"];
    NSArray * result = [schemes filteredArrayUsingPredicate: dropboxSchemePredicate];
    
    return result;
}

/// MARK: token uid

- (void)saveAccessTokenUID:(NSString *)tokenUID {
    [self.logger verbose: @"will store token UID %@", tokenUID];

    [[NSUserDefaults standardUserDefaults] setObject: tokenUID
                                              forKey: AccessTokenUIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.logger log: @"did store token UID %@", tokenUID];
}

- (NSString *)loadPreviousAccessTokenUID {
    [self.logger verbose: @"will load token UID"];
    
    NSString * result =
        [[NSUserDefaults standardUserDefaults] objectForKey: AccessTokenUIDKey];
        
    if ([result isKindOfClass:[NSString class]] == NO) {
    
        [self.logger warning: @"class mismash in loadede token UID %@", result];
        [self.logger log: @"did load token UID %@", nil];
        return nil;
    }
    
    [self.logger log: @"did load token UID %@", result];
    
    return result;
}

/// MARK convert auth result to NSError

- (NSError *)errorUsingAuthResult:(DBOAuthResult *)authResult {
    NSDictionary * userInfo = @{ NSLocalizedDescriptionKey: authResult.errorDescription };
    NSError * result = [NSError errorWithDomain: TBDropboxErrorDomain
                                           code: authResult.errorType
                                       userInfo: userInfo];
    return result;
}

@end

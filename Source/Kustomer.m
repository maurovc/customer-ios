//
//  Kustomer.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/1/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "Kustomer.h"
#import "Kustomer_Private.h"

#import "KUSUserSession.h"

static NSString *kKustomerOrgIdKey = @"org";
static NSString *kKustomerOrgNameKey = @"orgName";

@interface Kustomer ()

@property (nonatomic, strong) KUSUserSession *userSession;

@property (nonatomic, copy, readwrite) NSString *apiKey;
@property (nonatomic, copy, readwrite) NSString *orgId;
@property (nonatomic, copy, readwrite) NSString *orgName;

@end

@implementation Kustomer

#pragma mark - Class methods

+ (void)initializeWithAPIKey:(NSString *)apiKey
{
    [[self sharedInstance] setApiKey:apiKey];
}

+ (void)resetTracking
{
    [[self sharedInstance] resetTracking];
}

#pragma mark - Lifecycle methods

+ (instancetype)sharedInstance
{
    static Kustomer *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)setApiKey:(NSString *)apiKey
{
    NSAssert(apiKey != nil, @"Kustomer requires a non-nil API key");

    NSArray<NSString *> *apiKeyParts = [apiKey componentsSeparatedByString:@"."];
    NSAssert(apiKeyParts.count > 2, @"Kustomer API key has unexpected format");

    NSString *base64EncodedTokenJson = paddedBase64String(apiKeyParts[1]);
    NSDictionary *tokenPayload = jsonFromBase64EncodedJsonString(base64EncodedTokenJson);

    _apiKey = [apiKey copy];
    self.orgId = tokenPayload[kKustomerOrgIdKey];
    self.orgName = tokenPayload[kKustomerOrgNameKey];
    NSAssert(self.orgName.length > 0, @"Kustomer API key missing expected field: orgName");

    self.userSession = [[KUSUserSession alloc] initWithOrgName:self.orgName];

    NSLog(@"Kustomer initialized for organization: %@", self.orgName);
}

#pragma mark - Private methods

- (KUSUserSession *)userSession
{
    NSAssert(_userSession, @"Kustomer needs to be initialized before use");
    return _userSession;
}

#pragma mark - Internal methods

- (void)resetTracking
{
    // TODO: Re-implement tracking clear
}

#pragma mark - Helper functions

NS_INLINE NSString *paddedBase64String(NSString *base64String) {
    if (base64String.length % 4) {
        NSUInteger paddedLength = base64String.length + (4 - (base64String.length % 4));
        return [base64String stringByPaddingToLength:paddedLength withString:@"=" startingAtIndex:0];
    }
    return base64String;
}

NS_INLINE NSDictionary *jsonFromBase64EncodedJsonString(NSString *base64EncodedJson) {
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64EncodedJson options:kNilOptions];
    return [NSJSONSerialization JSONObjectWithData:decodedData options:kNilOptions error:NULL];
}

@end

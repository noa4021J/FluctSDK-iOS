//
//  FSSRewardedVideoCustomEventAppLovin.m
//  FluctSDK
//
//  Copyright © 2017年 fluct, Inc. All rights reserved.
//

#import "FSSRewardedVideoCustomEventAppLovin.h"
#import <AppLovinSDK/AppLovinSDK.h>

@interface FSSRewardedVideoCustomEventAppLovin () <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdVideoPlaybackDelegate>

@property (nonatomic, copy) NSString *placement;
@property (nonatomic) ALIncentivizedInterstitialAd *rewardedVideo;

+ (ALSdk *)sharedWithKey:(NSString *)sdkKey;
+ (ALIncentivizedInterstitialAd *)rewardedVideoWithSdk:(ALSdk *)sdk;

@end

@implementation FSSRewardedVideoCustomEventAppLovin

+ (ALSdk *)sharedWithKey:(NSString *)sdkKey {
    return [ALSdk sharedWithKey:sdkKey];
}

+ (ALIncentivizedInterstitialAd *)rewardedVideoWithSdk:(ALSdk *)sdk {
    return [[ALIncentivizedInterstitialAd alloc] initWithSdk:sdk];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary delegate:(id<FSSRewardedVideoCustomEventDelegate>)delegate testMode:(BOOL)testMode debugMode:(BOOL)debugMode {
    self = [super initWithDictionary:dictionary delegate:delegate testMode:testMode debugMode:debugMode];
    if (self) {
        static dispatch_once_t onceToken;
        ALSdk *applovinSDK = [FSSRewardedVideoCustomEventAppLovin sharedWithKey:dictionary[@"sdk_key"]];
        dispatch_once(&onceToken, ^{
            applovinSDK.settings.isVerboseLogging = debugMode;
            applovinSDK.settings.isTestAdsEnabled = testMode;
            [applovinSDK initializeSdk];
        });
        _rewardedVideo = [FSSRewardedVideoCustomEventAppLovin rewardedVideoWithSdk:applovinSDK];
        _rewardedVideo.adDisplayDelegate = self;
        _rewardedVideo.adVideoPlaybackDelegate = self;
        _placement = dictionary[@"placement"];
    }
    return self;
}

- (void)loadRewardedVideoWithDictionary:(NSDictionary *)dictionary {
    if ([self.rewardedVideo isReadyForDisplay]) {
        _adnwStatus = FSSRewardedVideoADNWStatusLoaded;
        [self.delegate rewardedVideoDidLoadForCustomEvent:self];
    } else {
        [self.rewardedVideo preloadAndNotify:self];
        _adnwStatus = FSSRewardedVideoADNWStatusLoading;
    }
}

- (FSSRewardedVideoADNWStatus)loadStatus {
    return _adnwStatus;
}

- (void)presentRewardedVideoAdFromViewController:(UIViewController *)viewController {
    if ([self.rewardedVideo isReadyForDisplay]) {
        [self.rewardedVideo showOver:viewController.view.window placement:self.placement andNotify:nil];
    } else {
        NSError *error = [NSError errorWithDomain:FSSRewardedVideoAdsSDKDomain code:FSSRewardedVideoAdErrorNotReady userInfo:nil];
        [self.delegate rewardedVideoDidFailToPlayForCustomEvent:self fluctError:error adnetworkError:kALErrorCodeIncentiviziedAdNotPreloaded];
    }
}

- (NSString *)sdkVersion {
    return [ALSdk version];
}

- (void)invalidate {
    self.rewardedVideo = nil;
}

#pragma mark ALAdLoadDelegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(FSSRewardedVideoWorkQueue(), ^{
        _adnwStatus = FSSRewardedVideoADNWStatusLoaded;
        [weakSelf.delegate rewardedVideoDidLoadForCustomEvent:weakSelf];
    });
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(FSSRewardedVideoWorkQueue(), ^{
        _adnwStatus = FSSRewardedVideoADNWStatusNotDisplayable;
        switch (code) {
        case kALErrorCodeNoFill:
            [weakSelf.delegate rewardedVideoDidFailToLoadForCustomEvent:weakSelf
                                                             fluctError:[NSError errorWithDomain:FSSRewardedVideoAdsSDKDomain
                                                                                            code:FSSRewardedVideoAdErrorNoAds
                                                                                        userInfo:nil]
                                                         adnetworkError:code];
            break;
        case kALErrorCodeIncentivizedValidationNetworkTimeout:
            [weakSelf.delegate rewardedVideoDidFailToLoadForCustomEvent:weakSelf
                                                             fluctError:[NSError errorWithDomain:FSSRewardedVideoAdsSDKDomain
                                                                                            code:FSSRewardedVideoAdErrorTimeout
                                                                                        userInfo:nil]
                                                         adnetworkError:code];
            break;
        case kALErrorCodeUnableToRenderAd:
            [weakSelf.delegate rewardedVideoDidFailToPlayForCustomEvent:weakSelf
                                                             fluctError:[NSError errorWithDomain:FSSRewardedVideoAdsSDKDomain
                                                                                            code:FSSRewardedVideoAdErrorPlayFailed
                                                                                        userInfo:nil]
                                                         adnetworkError:code];
            break;
        default:
            [weakSelf.delegate rewardedVideoDidFailToLoadForCustomEvent:weakSelf
                                                             fluctError:[NSError errorWithDomain:FSSRewardedVideoAdsSDKDomain
                                                                                            code:FSSRewardedVideoAdErrorUnknown
                                                                                        userInfo:nil]
                                                         adnetworkError:code];
            break;
        }
    });
}

#pragma mark ALAdDisplayDelegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(FSSRewardedVideoWorkQueue(), ^{
        [weakSelf.delegate rewardedVideoWillAppearForCustomEvent:weakSelf];
        [weakSelf.delegate rewardedVideoDidAppearForCustomEvent:weakSelf];
    });
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(FSSRewardedVideoWorkQueue(), ^{
        [weakSelf.delegate rewardedVideoWillDisappearForCustomEvent:weakSelf];
        [weakSelf.delegate rewardedVideoDidDisappearForCustomEvent:weakSelf];
    });
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(FSSRewardedVideoWorkQueue(), ^{
        [weakSelf.delegate rewardedVideoDidClickForCustomEvent:weakSelf];
    });
}

#pragma mark ALAdVideoPlaybackDelegate

- (void)videoPlaybackBeganInAd:(ALAd *)ad {
}

- (void)videoPlaybackEndedInAd:(ALAd *)ad atPlaybackPercent:(NSNumber *)percentPlayed fullyWatched:(BOOL)wasFullyWatched {
    if (wasFullyWatched) {
        __weak __typeof(self) weakSelf = self;
        dispatch_async(FSSRewardedVideoWorkQueue(), ^{
            [weakSelf.delegate rewardedVideoShouldRewardForCustomEvent:weakSelf];
        });
    }
}

@end
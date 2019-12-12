//
//  xlLPlayerView.h
//  Ship
//
//  Created by xlL on 2019/11/3.
//  Copyright © 2019 xlL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

NS_ASSUME_NONNULL_BEGIN

@class BRPlayer;
@class BRPlayerView;
@class BRPlayerViewCache;

#pragma mark - BRPlayerProtocol

typedef NS_ENUM(NSUInteger, BRPlayerStatus)  {
    BRPlayerStatusUnknown = 0,
    BRPlayerStatusReadyToPlay,
    BRPlayerStatusFailed,
    BRPlayerStatusBuffering,
    BRPlayerStatusPlaying,
    BRPlayerStatusPause,
    BRPlayerStatusStop,
    BRPlayerStatusDownloading,
};

@protocol BRPlayerProtocol <NSObject>

/// set loop play, default value -1
@property (nonatomic, assign) NSInteger loopPlayCount;

/// when AVPlayer status become AVPlayerItemStatusReadyToPlay, will call [player play], default value YES
@property (nonatomic, assign) BOOL autoPlayWhenReadyToPlay;

/// enable playing while downloading
@property (nonatomic, assign) BOOL enablePlayWhileDownload;

@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) BRPlayerStatus status;

/// playing URL
@property (nonatomic, readonly) NSURL *URL;

/// playing asset
@property (nonatomic, readonly) AVAsset *asset;

- (instancetype)initWithURL:(NSURL *)URL;
- (instancetype)initWithAsset:(AVAsset *)asset;
- (instancetype)initWithAsset:(AVAsset *)asset videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVAudioMix *)audioMix;

- (void)reloadWithURL:(NSURL *)URL;
- (void)reloadWithAsset:(AVAsset *)asset;
- (void)reloadWithAsset:(AVAsset *)asset videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVAudioMix *)audioMix;

- (void)play;
- (void)pause;
- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler;

@end

#pragma mark - BRPlayerDelegate

@protocol BRPlayerDelegate <NSObject>

@optional

- (void)player:(BRPlayer *)player statusDidChange:(BRPlayerStatus)status;

/// when AVPlayer status become AVPlayerItemStatusReadyToPlay
- (void)player:(BRPlayer *)player readyToPlayWithDuration:(Float64)duration;

/// when AVPlayer status become AVPlayerItemStatusFailed or AVPlayerItemStatusUnknown
- (void)player:(BRPlayer *)player failToPlayWithError:(NSError *)error;

//playing

- (void)player:(BRPlayer *)player playingWithProgress:(CGFloat)progress currentTime:(CGFloat)time;
- (void)player:(BRPlayer *)player playEndWithProgress:(CGFloat)progress currentTime:(CGFloat)time;
- (void)player:(BRPlayer *)player playingOrPauseStatusChange:(BOOL)isPlaying;
- (void)player:(BRPlayer *)player playingWithLoadedBuffer:(BOOL)isPlaying;

@end

@protocol BRPlayerCacheDataSource <NSObject>

@required
- (id<AVAssetResourceLoaderDelegate>)player:(BRPlayer *)player;

@end

#pragma mark - BRPlayer

@interface BRPlayer : NSObject <BRPlayerProtocol>

@property (nonatomic, weak) id<BRPlayerDelegate> delegate;
@property (nonatomic, weak) id<BRPlayerCacheDataSource> dataSource;

@property (nonatomic, strong) CALayer *layer;

/// when use this method, the View invoke BRPlayerProtocol method will forward to BRPlayer
- (void)attachView:(UIView *)view;

@end


#pragma mark - BRPlayerViewDeleate

typedef NS_ENUM(NSUInteger, BRScrollType) {
    BRScrollTypeBaseLine,
    BRScrollTypeRect,
};

@protocol BRPlayerViewDeleate <NSObject>

//scroll
- (void)scrollInType:(BRScrollType)type currentInRect:(BRPlayerView *)currentInPlayerView willInRect:(BRPlayerView *)willInPlayerView;

@end

#pragma mark - BRPlayerView

@interface BRPlayerView : UIView <BRPlayerProtocol>

@property (nonatomic, weak) id<BRPlayerViewDeleate> delegate;

@property (nonatomic, strong) BRPlayer *player;

/// set Overlap auto to hide
@property (nonatomic, assign) BOOL isOverlapViewAutoHide;

- (instancetype)initWithURL:(NSURL *)URL;

- (void)setOverlapView:(UIView *)view;

@end

@interface BRPlayerView (BRScroll)

- (void)scrollWithView:(UIScrollView *)scrollView hitRect:(CGRect)testRect withType:(BRScrollType)type;

@end

NS_ASSUME_NONNULL_END

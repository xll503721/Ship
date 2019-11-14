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

typedef NS_ENUM(NSUInteger, BRScrollType) {
    BRScrollTypeBaseLine,
    BRScrollTypeRect,
};

@class BRPlayerView;
@class BRPlayerViewCache;

@protocol BRPlayerViewDeleate <NSObject>

@optional
//loading

/// when AVPlayer status become AVPlayerItemStatusReadyToPlay
/// @param playerView view
/// @param duration video total duration
- (void)playerView:(BRPlayerView *)playerView readyToPlayWithDuration:(Float64)duration;

/// when AVPlayer status become AVPlayerItemStatusFailed or AVPlayerItemStatusUnknown
/// @param playerView view
/// @param error error description
- (void)playerView:(BRPlayerView *)playerView failToPlayWithError:(NSError *)error;

//playing

- (void)playerView:(BRPlayerView *)playerView playingWithProgress:(CGFloat)progress currentTime:(CGFloat)time;
- (void)playerView:(BRPlayerView *)playerView playEndWithProgress:(CGFloat)progress currentTime:(CGFloat)time;
- (void)playerView:(BRPlayerView *)playerView playingOrPauseStatusChange:(BOOL)isPlaying;
- (void)playerView:(BRPlayerView *)playerView playingWithLoadedBuffer:(BOOL)isPlaying;

//scroll
- (void)scrollInType:(BRScrollType)type currentInRect:(BRPlayerView *)currentInPlayerView willInRect:(BRPlayerView *)willInPlayerView;


@end

@interface BRPlayerView : UIView

@property (nonatomic, weak) id<BRPlayerViewDeleate> delegate;

/// set loop play, default value -1
@property (nonatomic, assign) NSInteger loopPlayCount;

/// set Overlap auto to hide
@property (nonatomic, assign) BOOL isOverlapViewAutoHide;

/// when AVPlayer status become AVPlayerItemStatusReadyToPlay, will call [player play], default value YES
@property (nonatomic, assign) BOOL autoPlayWhenReadyToPlay;

/// enable playing while downloading
@property (nonatomic, assign) BOOL enablePlayWhileDownload;

@property (nonatomic, readonly) BOOL isPlaying;

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) AVAsset *asset;


- (instancetype)initWithURL:(NSURL *)URL;
- (instancetype)initWithAsset:(AVAsset *)asset;
- (instancetype)initWithAsset:(AVAsset *)asset videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVAudioMix *)audioMix;

- (void)play;
- (void)pause;
- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler;

- (void)setOverlapView:(UIView *)view;

@end

@interface BRPlayerView (BRScroll)

- (void)scrollWithView:(UIScrollView *)scrollView hitRect:(CGRect)testRect withType:(BRScrollType)type;

@end

NS_ASSUME_NONNULL_END

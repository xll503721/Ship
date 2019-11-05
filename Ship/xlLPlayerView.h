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

@class xlLPlayerView;

@protocol xlLPlayerViewDeleate <NSObject>

@optional
//loading

/// when AVPlayer status become AVPlayerItemStatusReadyToPlay
/// @param playerView view
/// @param duration video total duration
- (void)playerView:(xlLPlayerView *)playerView readyToPlayWithDuration:(Float64)duration;

/// when AVPlayer status become AVPlayerItemStatusFailed or AVPlayerItemStatusUnknown
/// @param playerView view
/// @param error error description
- (void)playerView:(xlLPlayerView *)playerView failToPlayWithError:(NSError *)error;

//playing

- (void)playerView:(xlLPlayerView *)playerView playingWithProgress:(CGFloat)progress currentTime:(CGFloat)time;
- (void)playerView:(xlLPlayerView *)playerView playEndWithProgress:(CGFloat)progress currentTime:(CGFloat)time;
- (void)playerView:(xlLPlayerView *)playerView playingOrPauseStatusChange:(BOOL)isPlaying;
- (void)playerView:(xlLPlayerView *)playerView playingWithLoadedBuffer:(BOOL)isPlaying;

@end

@interface xlLPlayerView : UIView

@property (nonatomic, weak) id<xlLPlayerViewDeleate> delegate;

/// set loop play
@property (nonatomic, assign) NSInteger loopPlayCount;

/// set Overlap auto to hide
@property (nonatomic, assign) BOOL isOverlapViewAutoHide;

/// when AVPlayer status become AVPlayerItemStatusReadyToPlay, will call [player play]
@property (nonatomic, assign) BOOL autoPlayWhenReadyToPlay;
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

@interface xlLPlayerView (XLAutoLoad)

- (void)autoLoadWithScrollView:(UIScrollView *)scrollView;

@end

NS_ASSUME_NONNULL_END

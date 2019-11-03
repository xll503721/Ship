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

NS_ASSUME_NONNULL_BEGIN

@class xlLPlayerView;

@protocol xlLPlayerViewDeleate <NSObject>

@optional
- (void)playerView:(xlLPlayerView *)playerView readyToPlayWithDuration:(Float64)duration;
- (void)playerView:(xlLPlayerView *)playerView failToPlayWithError:(NSError *)error;

- (void)playerView:(xlLPlayerView *)playerView playingWithProgress:(CGFloat)progress;

@end

@interface xlLPlayerView : UIView

@property (nonatomic, weak) id<xlLPlayerViewDeleate> delegate;

@property (nonatomic, assign) NSInteger loopCount;

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) AVAsset *asset;

- (instancetype)initWithURL:(NSURL *)URL;
- (instancetype)initWithAsset:(AVAsset *)asset;
- (instancetype)initWithAsset:(AVAsset *)asset videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVAudioMix *)audioMix;

- (void)play;
- (void)pause;

@end

NS_ASSUME_NONNULL_END

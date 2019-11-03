//
//  xlLPlayerView.m
//  Ship
//
//  Created by xlL on 2019/11/3.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "xlLPlayerView.h"

typedef void (^ObserveBlock) (NSString *keyPath, id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context);

@interface xlLPlayerView ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) NSTimer *progressTimer;
@property (nonatomic, strong) NSDictionary<NSString *, ObserveBlock> *observeBlocks;
@property (nonatomic, assign) Float64 duration;

@property (nonatomic, strong) UILabel *durationLabel;

@end

@implementation xlLPlayerView

- (void)dealloc
{
    [self remoeObserver];
}

- (instancetype)initWithURL:(NSURL *)URL
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.playerItem = [AVPlayerItem playerItemWithURL:URL];
        
        [self commonInit];
        [self viewsCommonInit];
    }
    return self;
}

- (instancetype)initWithAsset:(AVAsset *)asset
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
        
        [self commonInit];
        [self viewsCommonInit];
    }
    return self;
}

- (instancetype)initWithAsset:(AVAsset *)asset videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVAudioMix *)audioMix
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
        self.playerItem.videoComposition = videoComposition;
        self.playerItem.audioMix = audioMix;
        
        [self commonInit];
        [self viewsCommonInit];
        
    }
    return self;
}

- (void)commonInit {
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.layer addSublayer:self.playerLayer];
    
//    [self remoeObserver];
    [self addObserver];
    
    __weak typeof(self) wself = self;
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:playingWithProgress:)]) {
            [self.delegate playerView:self playingWithProgress:0];
        }
        
        if (CMTimeGetSeconds(wself.player.currentTime) == wself.duration) {
            [timer invalidate];
        }
    }];
}

- (void)viewsCommonInit {
    [self addSubview:self.durationLabel];
}

- (void)addObserver {
    [self.observeBlocks enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ObserveBlock  _Nonnull obj, BOOL * _Nonnull stop) {
        [self.playerItem addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew context:nil];
    }];
}

- (void)remoeObserver {
    [self.observeBlocks enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ObserveBlock  _Nonnull obj, BOOL * _Nonnull stop) {
        [self.playerItem removeObserver:self forKeyPath:key];
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    ObserveBlock observeBlock = self.observeBlocks[keyPath];
    if (observeBlock) {
        observeBlock(keyPath, object, change, context);
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.playerLayer.frame = self.bounds;
    self.durationLabel.frame = CGRectMake(self.bounds.size.width - 20, self.bounds.size.height - 20, self.bounds.size.width, 20);
}

- (void)play {
    [self.player play];
}

- (void)pause {
    [self.player pause];
}

#pragma mark - setter

- (void)setURL:(NSURL *)URL {
    if (![URL.path isEqualToString:_URL.path]) {
        _URL = URL;
        self.playerItem = [AVPlayerItem playerItemWithURL:_URL];
        [self commonInit];
    }
}

- (void)setAsset:(AVAsset *)asset {
    if (_asset !=  asset) {
        _asset = asset;
        self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
        [self commonInit];
    }
}

- (void)setDuration:(Float64)duration {
    _duration = duration;
    
    self.durationLabel.text = @(duration).stringValue;
}

#pragma mark - getter

- (NSDictionary<NSString *, ObserveBlock> *)observeBlocks {
    if (!_observeBlocks) {
        _observeBlocks = @{
            @"status": [self statusBlock],
        };
    }
    return _observeBlocks;
}

- (ObserveBlock)statusBlock {
    return ^ (NSString *keyPath, id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context){
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] intValue];
        if (status == AVPlayerItemStatusReadyToPlay) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:readyToPlayWithDuration:)]) {
                [self.delegate playerView:self readyToPlayWithDuration:CMTimeGetSeconds(self.playerItem.duration)];
            }
            
            self.duration = (NSInteger)round(CMTimeGetSeconds(self.playerItem.duration));
        }
        else if (status == AVPlayerItemStatusFailed || status == AVPlayerItemStatusUnknown) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:failToPlayWithError:)]) {
                NSError *error = [NSError errorWithDomain:@"" code:1000 userInfo:nil];
                [self.delegate playerView:self failToPlayWithError:error];
            }
        }
    };
}

- (UILabel *)durationLabel {
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _durationLabel.textColor = [UIColor whiteColor];
    }
    return _durationLabel;
}

@end

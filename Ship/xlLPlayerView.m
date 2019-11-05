//
//  xlLPlayerView.m
//  Ship
//
//  Created by xlL on 2019/11/3.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "xlLPlayerView.h"


static CGFloat kXlLPlayerToobarViewHeight = 30;
static const char kXlLPlayerViewSelf;
static const char kXlLPlayerViewCurrentPlaying;
static const char kXlLPlayerViewScrollViewDelegate;

@interface xlLPlayerContentView : UIView

@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UILabel *startTimeLabel;
@property (nonatomic, strong) UILabel *endTimeLabel;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UIButton *fullScreenButton;

@property (nonatomic, strong) UIView *toobarView;

@end

@implementation xlLPlayerContentView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.toobarView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.toobarView.frame = CGRectMake(0, self.bounds.size.height - kXlLPlayerToobarViewHeight, self.bounds.size.width, kXlLPlayerToobarViewHeight);
    self.fullScreenButton.frame = CGRectMake(self.toobarView.bounds.size.width - self.toobarView.bounds.size.height,
                                             0,
                                             self.toobarView.bounds.size.height,
                                             self.toobarView.bounds.size.height);
    self.actionButton.frame = CGRectMake(0, 0, kXlLPlayerToobarViewHeight, self.toobarView.bounds.size.height);
    self.startTimeLabel.frame = CGRectMake(self.actionButton.frame.origin.x + kXlLPlayerToobarViewHeight,
                                           0,
                                           self.startTimeLabel.font.pointSize * 5,
                                           self.toobarView.bounds.size.height);
    self.slider.frame = CGRectMake(self.startTimeLabel.frame.origin.x + self.startTimeLabel.frame.size.width,
                                   0,
                                   self.bounds.size.width - self.actionButton.bounds.size.width - (self.startTimeLabel.bounds.size.width * 2) - self.fullScreenButton.bounds.size.width,
                                   self.toobarView.bounds.size.height);
    self.endTimeLabel.frame = CGRectMake(self.slider.frame.origin.x + self.slider.frame.size.width,
                                         0,
                                         self.startTimeLabel.font.pointSize * 5,
                                         self.toobarView.bounds.size.height);
}

- (void)setDurationTimeWithString:(NSString *)timeString {
    self.endTimeLabel.text = [NSString stringWithFormat:@"00:20", timeString];
}

#pragma mark - getter

- (UISlider *)slider {
    if (!_slider) {
        _slider = [[UISlider alloc] initWithFrame:CGRectZero];
    }
    return _slider;
}

- (UILabel *)endTimeLabel {
    if (!_endTimeLabel) {
        _endTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _endTimeLabel.font = [UIFont systemFontOfSize:12.0f];
        _endTimeLabel.textColor = [UIColor whiteColor];
        _endTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _endTimeLabel;
}

- (UILabel *)startTimeLabel {
    if (!_startTimeLabel) {
        _startTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _startTimeLabel.font = [UIFont systemFontOfSize:12.0f];
        _startTimeLabel.textColor = [UIColor whiteColor];
        _startTimeLabel.text = @"00:00";
        _startTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _startTimeLabel;
}

- (UIButton *)actionButton {
    if (!_actionButton) {
        _actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    return _actionButton;
}

- (UIButton *)fullScreenButton {
    if (!_fullScreenButton) {
        _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    return _fullScreenButton;
}

- (UIView *)toobarView {
    if (!_toobarView) {
        _toobarView = [[UIView alloc] initWithFrame:CGRectZero];
        
        [_toobarView addSubview:self.actionButton];
        [_toobarView addSubview:self.startTimeLabel];
        [_toobarView addSubview:self.slider];
        [_toobarView addSubview:self.endTimeLabel];
        [_toobarView addSubview:self.fullScreenButton];
    }
    return _toobarView;
}


@end

typedef void (^ObserveBlock) (NSString *keyPath, id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context);

@interface xlLPlayerView ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) NSDictionary<NSString *, ObserveBlock> *observeBlocks;
@property (nonatomic, assign) Float64 duration;

@property (nonatomic, strong) xlLPlayerContentView *contentView;

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

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.playerLayer.frame = self.bounds;
    self.contentView.frame = self.bounds;
}

- (void)commonInit {
    __weak typeof(self) wself = self;
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 5) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        CGFloat progress = CMTimeGetSeconds(wself.player.currentItem.currentTime) / CMTimeGetSeconds(wself.player.currentItem.duration);
        if (wself.delegate && [wself.delegate respondsToSelector:@selector(playerView:playingWithProgress:currentTime:)]) {
            CGFloat currentTime = wself.playerItem.currentTime.value / wself.playerItem.currentTime.timescale;
            [wself.delegate playerView:wself playingWithProgress:progress currentTime:currentTime];
        }
        
        wself.contentView.slider.value = progress;
    }];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.layer addSublayer:self.playerLayer];
    
    [self addObserver];
}

- (void)viewsCommonInit {
    [self addSubview:self.contentView];
}

- (void)addObserver {
    [self.observeBlocks enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ObserveBlock  _Nonnull obj, BOOL * _Nonnull stop) {
        [self.playerItem addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew context:nil];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPlayerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPlayerItemPlaybackStalled:) name:AVPlayerItemPlaybackStalledNotification object:self.playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppResignActive:) name:UIApplicationWillResignActiveNotification object:self.playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:self.playerItem];
}

- (void)remoeObserver {
    [self.observeBlocks enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ObserveBlock  _Nonnull obj, BOOL * _Nonnull stop) {
        [self.playerItem removeObserver:self forKeyPath:key];
    }];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)reload {
    __weak typeof(self) wself = self;
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 5) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        CGFloat progress = CMTimeGetSeconds(wself.player.currentItem.currentTime) / CMTimeGetSeconds(wself.player.currentItem.duration);
        if (wself.delegate && [wself.delegate respondsToSelector:@selector(playerView:playingWithProgress:currentTime:)]) {
            CGFloat currentTime = wself.playerItem.currentTime.value / wself.playerItem.currentTime.timescale;
            [wself.delegate playerView:wself playingWithProgress:progress currentTime:currentTime];
        }
        
        wself.contentView.slider.value = progress;
    }];
    [self remoeObserver];
    [self addObserver];
}

#pragma mark - Observer

- (void)onPlayerItemDidPlayToEndTime:(NSNotification *)notification {
    AVPlayerItem *playerItem = notification.object;
    if (playerItem != self.playerItem) {
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:playingWithProgress:currentTime:)]) {
        CGFloat currentTime = self.playerItem.currentTime.value / self.playerItem.currentTime.timescale;
        CGFloat progress = CMTimeGetSeconds(self.player.currentItem.currentTime) / CMTimeGetSeconds(self.player.currentItem.duration);
        [self.delegate playerView:self playingWithProgress:progress currentTime:currentTime];
    }
    
    if (self.loopPlayCount > 0) {
        self.loopPlayCount--;
        [self pause];
        [self seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
            
        }];
        [self play];
    }
}

- (void)onAppResignActive:(NSNotification *)notification {
    [self pause];
}

- (void)onAppBecomeActive:(NSNotification *)notification {
    if (self.isPlaying) {
        [self play];
    }
}

- (void)onPlayerItemPlaybackStalled:(NSNotification *)notification {
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    ObserveBlock observeBlock = self.observeBlocks[keyPath];
    if (observeBlock) {
        observeBlock(keyPath, object, change, context);
    }
}

#pragma mark - public method

- (void)play {
    [self.player play];
}

- (void)pause {
    [self.player pause];
}

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler {
    [self.player seekToTime:time completionHandler:completionHandler];
}

- (void)setOverlapView:(UIView *)view {
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.contentView addSubview:view];
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
        [self reload];
    }
}

- (void)setDuration:(Float64)duration {
    _duration = duration;
    
    self.contentView.endTimeLabel.text = @(duration).stringValue;
}

#pragma mark - getter

- (NSDictionary<NSString *, ObserveBlock> *)observeBlocks {
    if (!_observeBlocks) {
        _observeBlocks = @{
            @"status": [self statusBlock],
            @"loadedTimeRanges": [self loadedTimeRangesBlock],
            @"playbackBufferEmpty": [self playbackBufferEmptyBlock],
            @"playbackLikelyToKeepUp": [self playbackLikelyToKeepUpBlock],
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
            if (self.autoPlayWhenReadyToPlay) {
//                [self.player play];
            }
        }
        else if (status == AVPlayerItemStatusFailed || status == AVPlayerItemStatusUnknown) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:failToPlayWithError:)]) {
                NSError *error = [NSError errorWithDomain:@"" code:1000 userInfo:nil];
                [self.delegate playerView:self failToPlayWithError:error];
            }
        }
    };
}

- (ObserveBlock)loadedTimeRangesBlock {
    return ^ (NSString *keyPath, id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context){
        CMTimeRange timeRange = [self.playerItem.loadedTimeRanges.firstObject CMTimeRangeValue];//本次缓冲时间范围
        Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
        Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        NSLog(@"当前缓冲时间:%f",totalBuffer);
    };
}

- (ObserveBlock)playbackBufferEmptyBlock {
    return ^ (NSString *keyPath, id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context){
        BOOL empty = [change[NSKeyValueChangeNewKey] intValue];
        if (!empty) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:playingOrPauseStatusChange:)]) {
                [self.delegate playerView:self playingOrPauseStatusChange:empty];
            }
        }
    };
}

- (ObserveBlock)playbackLikelyToKeepUpBlock {
    return ^ (NSString *keyPath, id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context){
        if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:playingOrPauseStatusChange:)]) {
            [self.delegate playerView:self playingOrPauseStatusChange:YES];
        }
//        [self.player play];
    };
}

#pragma mark - getter

- (xlLPlayerContentView *)contentView {
    if (!_contentView) {
        _contentView = [[xlLPlayerContentView alloc] initWithFrame:CGRectZero];
    }
    return _contentView;
}

- (BOOL)isPlaying {
    return self.player.rate == 0;
}

@end


@implementation xlLPlayerView (XLAutoLoad)

- (void)autoLoadWithScrollView:(UIScrollView *)scrollView {
    
    objc_setAssociatedObject(self, &kXlLPlayerViewScrollViewDelegate, scrollView.delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    NSMapTable<NSString *, xlLPlayerView *> *playViews = objc_getAssociatedObject(scrollView.delegate, &kXlLPlayerViewSelf);
    if (!playViews) {
        playViews = [NSMapTable mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableWeakMemory];
        objc_setAssociatedObject(scrollView.delegate, &kXlLPlayerViewSelf, playViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    
    [playViews setObject:self forKey:[NSString stringWithFormat:@"%p", self]];
    
    [self createSubClassWithObject:scrollView.delegate];
    [self hookWithObject:scrollView.delegate Selector:@selector(scrollViewDidScroll:) imp:newScrollViewDidScroll];
    [self hookWithObject:scrollView.delegate Selector:@selector(scrollViewDidEndDecelerating:) imp:newScrollViewDidEndDecelerating];
    [self hookWithObject:scrollView.delegate Selector:@selector(scrollViewDidEndDragging:willDecelerate:) imp:newScrollViewDidEndDragging];
}

- (void)createSubClassWithObject:(NSObject *)o {
    NSString *oldClass = NSStringFromClass(object_getClass(o));
    if (![oldClass hasPrefix:@"BRPlayView_"]) {
        NSString *newClass = [NSString stringWithFormat:@"BRPlayView_%@",oldClass];
        Class subClass = objc_lookUpClass(newClass.UTF8String);
        if (!subClass) {
            subClass = objc_allocateClassPair(object_getClass(o), newClass.UTF8String, 0);
            objc_registerClassPair(subClass);
        }
        object_setClass(o, subClass);
    }
}

- (void)hookWithObject:(NSObject *)o Selector:(SEL)selector imp:(void *)imp {
    
    NSString *subClassName = NSStringFromClass(object_getClass(o));
    if (![subClassName hasPrefix:@"BRPlayView_"]) {
        return;
    }
    
    Class subClass = object_getClass(o);
    Method superSelector = class_getInstanceMethod([o superclass], selector);
    const char *selectorTypes = method_getTypeEncoding(superSelector);
    class_addMethod(subClass, selector, (IMP)imp, selectorTypes);
}

void newScrollViewDidEndDecelerating(id self, SEL _cmd, void *parameter) {
    UIScrollView *scrollView = (__bridge UIScrollView *)parameter;
    if (![scrollView respondsToSelector:@selector(delegate)]) {
        return;
    }
    
    struct objc_super superClass = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(scrollView.delegate))
    };
    
    ((void (*) (id, SEL, void *))(void *)objc_msgSendSuper)((__bridge id)(&superClass), _cmd, parameter);
    
    calculatePlayingView(parameter);
}

void newScrollViewDidEndDragging(id self, SEL _cmd, void *parameter1, void *parameter2) {
    UIScrollView *scrollView = (__bridge UIScrollView *)parameter1;
    BOOL decelerate = parameter2;
    if (![scrollView respondsToSelector:@selector(delegate)]) {
        return;
    }
    
    struct objc_super superClass = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(scrollView.delegate))
    };
    
    ((void (*) (id, SEL, void *, void *))(void *)objc_msgSendSuper)((__bridge id)(&superClass), _cmd, parameter1, parameter2);
    
    if (!decelerate) {
        newScrollViewDidEndDecelerating(self, _cmd, parameter1);
    }
}

void newScrollViewDidScroll(id self, SEL _cmd, void *parameter) {
    
    UIScrollView *scrollView = (__bridge UIScrollView *)parameter;
    if (![scrollView respondsToSelector:@selector(delegate)]) {
        return;
    }
    
    struct objc_super superClass = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(scrollView.delegate))
    };
    
    ((void (*) (id, SEL, void *))(void *)objc_msgSendSuper)((__bridge id)(&superClass), _cmd, parameter);
}

void calculatePlayingView(void *parameter) {
    UIScrollView *scrollView = (__bridge UIScrollView *)parameter;
    if (![scrollView respondsToSelector:@selector(delegate)]) {
        return;
    }
    
    NSMapTable<NSString *, xlLPlayerView *> *playViews = objc_getAssociatedObject(scrollView.delegate, &kXlLPlayerViewSelf);
    xlLPlayerView *currentPlayingView = objc_getAssociatedObject(scrollView.delegate, &kXlLPlayerViewCurrentPlaying);
    
    __block xlLPlayerView *willPlayingView = currentPlayingView;
    __block xlLPlayerView *topPlayingView = nil;
    __block CGFloat distance = scrollView.bounds.size.height;
    CGFloat scrollViewHeightOffsetCenterY = scrollView.contentOffset.y + (scrollView.bounds.size.height / 2);
    
    NSArray<xlLPlayerView *> *allPlayViews = [[playViews objectEnumerator] allObjects];
    [allPlayViews enumerateObjectsUsingBlock:^(xlLPlayerView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {

        CGRect frame = view.frame;
        if ([scrollView isKindOfClass:[UITableView class]]) {
            frame = [view convertRect:view.frame toView:scrollView];
        }
        
        NSLog(@"view.frame: %@, add: %p", [NSValue valueWithCGRect:frame], view);
        NSLog(@"scrollview: %@", [NSValue valueWithCGPoint:scrollView.contentOffset]);
        NSLog(@"idx:%ld", idx);
        NSLog(@"==================");
        
        
        //Pause except what's playing
        if (currentPlayingView != view && [view isPlaying]) {
            [view pause];
        }
        
        //calculate base line
        CGFloat baseLine = 0;
        if (frame.origin.y > scrollViewHeightOffsetCenterY) {
            baseLine = frame.origin.y + frame.size.height;
        }
        else if (frame.origin.y < scrollViewHeightOffsetCenterY) {
            baseLine = frame.origin.y;
        }
        
        //Look for what will play
        CGFloat newDistance = fabs(baseLine - scrollViewHeightOffsetCenterY);
        if (newDistance < distance && view != currentPlayingView) {
            distance = newDistance;
            
            willPlayingView = view;
        }
        
    }];
    
    //Play the first one for the first time
    if (!willPlayingView) {
        willPlayingView = topPlayingView;
    }
    
    if (willPlayingView && currentPlayingView != willPlayingView) {
        objc_setAssociatedObject(scrollView.delegate, &kXlLPlayerViewCurrentPlaying, willPlayingView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [currentPlayingView pause];
        [willPlayingView play];
    }
}



@end

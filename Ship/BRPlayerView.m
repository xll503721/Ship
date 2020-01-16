//
//  xlLPlayerView.m
//  Ship
//
//  Created by xlL on 2019/11/3.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "BRPlayerView.h"
#import "BRLog.h"
#import "BRPlayerCache.h"

static CGFloat kXlLPlayerToobarViewHeight = 30;
static const char kBRPlayerViewSelf;
static const char kBRPlayerViewCurrentPlaying;
static const char kBRPlayerViewScrollViewDelegate;
static const char kBRPlayerViewScrollViewScrollInRect;
static const char kBRPlayerViewScrollViewScrollHitType;
static const char kBRPlayerInner;

static NSString *BRPlayerURLScheme = @"BRURLScheme";
static NSString *const BRPlayerForwardInvocationSelectorName = @"__brplayer_forwardInvocation:";

#pragma mark - BRPlayer

static IMP brplayer_getMsgForwardIMP(NSObject *self, SEL selector) {
    IMP msgForwardIMP = _objc_msgForward;
#if !defined(__arm64__)
    Method method = class_getInstanceMethod(self.class, selector);
    const char *encoding = method_getTypeEncoding(method);
    BOOL methodReturnsStructValue = encoding[0] == _C_STRUCT_B;
    if (methodReturnsStructValue) {
        @try {
            NSUInteger valueSize = 0;
            NSGetSizeAndAlignment(encoding, &valueSize, NULL);
            
            if (valueSize == 1 || valueSize == 2 || valueSize == 4 || valueSize == 8) {
                methodReturnsStructValue = NO;
            }
        } @catch (__unused NSException *e) {}
    }
    if (methodReturnsStructValue) {
        msgForwardIMP = (IMP)_objc_msgForward_stret;
    }
#endif
    return msgForwardIMP;
}

static void __BRPLAYER_ARE_BEING_CALLED__(__unsafe_unretained NSObject *self, SEL selector, NSInvocation *invocation) {
    NSLog(@"selector is: %@", NSStringFromSelector(invocation.selector));
    
    BRPlayer *player = (BRPlayer *)objc_getAssociatedObject(self, &kBRPlayerInner);
    [player performSelector:selector];
}

typedef void (^ObserveBlock) (NSString *keyPath, id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context);

@interface BRPlayer ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) NSDictionary<NSString *, ObserveBlock> *observeBlocks;
@property (nonatomic, assign) Float64 duration;

@property (nonatomic, strong) id<AVAssetResourceLoaderDelegate> cache;

@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign, setter=autoPlayWhenReadyToPlay:, getter=autoPlayWhenReadyToPlay) BOOL _autoPlayWhenReadyToPlay;
@property (nonatomic, assign, setter=enablePlayWhileDownload:, getter=enablePlayWhileDownload) BOOL _enablePlayWhileDownload;
@property (nonatomic, assign, setter=loopPlayCount:, getter=loopPlayCount) NSInteger _loopPlayCount;

/// playing URL
@property (nonatomic, strong) NSURL *URL;

/// playing asset
@property (nonatomic, strong) AVAsset *asset;

@end

@implementation BRPlayer

- (void)dealloc
{
    [self br_removeObserver];
}

- (instancetype)initWithURL:(NSURL *)URL
{
    self = [super init];
    if (self) {
        
        self.URL = URL;
        self.playerItem = [AVPlayerItem playerItemWithURL:URL];
        
        [self br_commonInit];
    }
    return self;
}

- (instancetype)initWithAsset:(AVAsset *)asset
{
    self = [super init];
    if (self) {
        
        self.asset = asset;
        self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
        
        [self br_commonInit];
    }
    return self;
}

- (instancetype)initWithAsset:(AVAsset *)asset videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVAudioMix *)audioMix
{
    self = [super init];
    if (self) {
        
        self.asset = asset;
        self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
        self.playerItem.videoComposition = videoComposition;
        self.playerItem.audioMix = audioMix;
        
        [self br_commonInit];
    }
    return self;
}

- (void)br_commonInit {
    
    __weak typeof(self) wself = self;
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 5) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        CGFloat progress = CMTimeGetSeconds(wself.player.currentItem.currentTime) / CMTimeGetSeconds(wself.player.currentItem.duration);
        if (wself.delegate && [wself.delegate respondsToSelector:@selector(player:playingWithProgress:currentTime:)]) {
            CGFloat currentTime = wself.playerItem.currentTime.value / wself.playerItem.currentTime.timescale;
            [wself.delegate player:wself playingWithProgress:progress currentTime:currentTime];
        }
        
    }];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    
    self._autoPlayWhenReadyToPlay = YES;
    self._loopPlayCount = -1;
    
    [self br_addObserver];
}

- (void)br_addObserver {
    [self.observeBlocks enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ObserveBlock  _Nonnull obj, BOOL * _Nonnull stop) {
        [self.playerItem addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew context:nil];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(br_onPlayerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(br_onPlayerItemPlaybackStalled:) name:AVPlayerItemPlaybackStalledNotification object:self.playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(br_onAppResignActive:) name:UIApplicationWillResignActiveNotification object:self.playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(br_onAppBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:self.playerItem];
}

- (void)br_removeObserver {
    [self.observeBlocks enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ObserveBlock  _Nonnull obj, BOOL * _Nonnull stop) {
        [self.playerItem removeObserver:self forKeyPath:key];
    }];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)br_reload {
    __weak typeof(self) wself = self;
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 5) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        CGFloat progress = CMTimeGetSeconds(wself.player.currentItem.currentTime) / CMTimeGetSeconds(wself.player.currentItem.duration);
        if (wself.delegate && [wself.delegate respondsToSelector:@selector(player:playingWithProgress:currentTime:)]) {
            CGFloat currentTime = wself.playerItem.currentTime.value / wself.playerItem.currentTime.timescale;
            [wself.delegate player:wself playingWithProgress:progress currentTime:currentTime];
        }
    }];
    [self br_removeObserver];
    [self br_addObserver];
}

#pragma mark - Observer

- (void)br_onPlayerItemDidPlayToEndTime:(NSNotification *)notification {
    AVPlayerItem *playerItem = notification.object;
    if (playerItem != self.playerItem) {
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(player:playingWithProgress:currentTime:)]) {
        CGFloat currentTime = self.playerItem.currentTime.value / self.playerItem.currentTime.timescale;
        CGFloat progress = CMTimeGetSeconds(self.player.currentItem.currentTime) / CMTimeGetSeconds(self.player.currentItem.duration);
        [self.delegate player:self playingWithProgress:progress currentTime:currentTime];
    }
    
    if (self.loopPlayCount > 0) {
        self.loopPlayCount--;
        [self pause];
        [self seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
            
        }];
        [self play];
    }
    else {
        self.loopPlayCount = -1;
    }
}

- (void)br_onAppResignActive:(NSNotification *)notification {
    [self pause];
}

- (void)br_onAppBecomeActive:(NSNotification *)notification {
    if (self.isPlaying) {
        [self play];
    }
}

- (void)br_onPlayerItemPlaybackStalled:(NSNotification *)notification {
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    ObserveBlock observeBlock = self.observeBlocks[keyPath];
    if (observeBlock) {
        observeBlock(keyPath, object, change, context);
    }
}

- (void)br_reset {
    
    //reset property
    self.loopPlayCount = -1;
    self.autoPlayWhenReadyToPlay = NO;
    
    //remove all observer
    [self br_removeObserver];
    
    //remove layer
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
    
    //clear AVPlayer
    [self.player pause];
    [self.player cancelPendingPrerolls];
    self.player = nil;
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

- (void)reloadWithURL:(NSURL *)URL {
    [self br_reset];
}

- (void)attachView:(UIView *)view {
    if (![view conformsToProtocol:@protocol(BRPlayerProtocol)]) {
        BRDebugLog(@"can not attache class of %@ view, because that not conforms `BRPlayerProtocol`", view.class);
        return;
    }
    
    static NSSet *disallowedSelectorList;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        disallowedSelectorList = [NSSet setWithObjects:@"retain", @"release", @"autorelease", @"forwardInvocation:", @"delegate", @"dataSource", @"playerLayer", @"attachView:", nil];
    });
    
    unsigned int count;
    Method *methods = class_copyMethodList([self class], &count);
    for (int i = 0; i < count; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        const char *typeEncoding = method_getTypeEncoding(method);
        NSString *name =  NSStringFromSelector(selector);
        
        NSString *selectorName = NSStringFromSelector(selector);
        
        if ([disallowedSelectorList containsObject:selectorName] || [name hasPrefix:@"br_"] || ![self respondsToSelector:selector]) {
            continue;
        }
        
        class_replaceMethod(view.class, selector, brplayer_getMsgForwardIMP(self, selector), typeEncoding);
    }
    
    IMP originalImplementation = class_replaceMethod(view.class, @selector(forwardInvocation:), (IMP)__BRPLAYER_ARE_BEING_CALLED__, "v@:@");
    if (originalImplementation) {
        class_addMethod(view.class, NSSelectorFromString(BRPlayerForwardInvocationSelectorName), originalImplementation, "v@:@");
    }
    
    objc_setAssociatedObject(view, &kBRPlayerInner, self, OBJC_ASSOCIATION_ASSIGN);
}

#pragma mark - private

- (NSURL *)composeFakeVideoURL {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:self.URL resolvingAgainstBaseURL:NO];
    components.scheme = BRPlayerURLScheme;
    return [components URL];
}

#pragma mark - setter

- (void)setAutoPlayWhenReadyToPlay:(BOOL)autoPlayWhenReadyToPlay {
    __autoPlayWhenReadyToPlay = autoPlayWhenReadyToPlay;
}

- (BOOL)autoPlayWhenReadyToPlay {
    return __autoPlayWhenReadyToPlay;
}

- (void)setLoopPlayCount:(NSInteger)loopPlayCount {
    __loopPlayCount = loopPlayCount;
}

- (NSInteger)loopPlayCount {
    return __loopPlayCount;
}

- (void)setEnablePlayWhileDownload:(BOOL)enablePlayWhileDownload {
    __enablePlayWhileDownload = enablePlayWhileDownload;
    if (!enablePlayWhileDownload) {
        [self br_reset];
        
        if (self.asset) {
            self.playerItem = [AVPlayerItem playerItemWithAsset:self.asset];
        }
        
        if (self.URL) {
            self.playerItem = [AVPlayerItem playerItemWithURL:self.URL];
        }
        
        [self br_commonInit];
        return;
    }
    
    if (!self.dataSource || ![self.dataSource respondsToSelector:@selector(player:)]) {
        @throw [NSException exceptionWithName:@"BRPlayerException" reason:@"dataSource required method not implement" userInfo:nil];
    }
    
    [self br_reset];
    
    self.cache = [self.dataSource player:self];
    AVURLAsset *videoURLAsset = [AVURLAsset URLAssetWithURL:[self composeFakeVideoURL] options:nil];
    [videoURLAsset.resourceLoader setDelegate:self.cache queue:dispatch_get_main_queue()];
    self.playerItem = [AVPlayerItem playerItemWithAsset:videoURLAsset];
    [self br_commonInit];
}

- (BOOL)enablePlayWhileDownload {
    return __enablePlayWhileDownload;
}

- (void)setURL:(NSURL *)URL {
    if (![URL.path isEqualToString:_URL.path]) {
        _URL = URL;
        self.playerItem = [AVPlayerItem playerItemWithURL:_URL];
        [self br_commonInit];
    }
}

- (void)setAsset:(AVAsset *)asset {
    if (_asset !=  asset) {
        _asset = asset;
        self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
        [self br_reload];
    }
}

- (void)setDuration:(Float64)duration {
    _duration = duration;
}

#pragma mark - getter

- (NSDictionary<NSString *, ObserveBlock> *)observeBlocks {
    if (!_observeBlocks) {
        _observeBlocks = @{
            @"status": [self br_statusBlock],
            @"loadedTimeRanges": [self br_loadedTimeRangesBlock],
            @"playbackBufferEmpty": [self br_playbackBufferEmptyBlock],
            @"playbackLikelyToKeepUp": [self br_playbackLikelyToKeepUpBlock],
        };
    }
    return _observeBlocks;
}

- (ObserveBlock)br_statusBlock {
    return ^ (NSString *keyPath, id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context){
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] intValue];
        BRDebugLog(@"status is: %@", status == AVPlayerItemStatusReadyToPlay ? @"AVPlayerItemStatusReadyToPlay" : @"AVPlayerItemStatusFailed");
        if (self.delegate && [self.delegate respondsToSelector:@selector(player:statusDidChange:)] && self.status != (BRPlayerStatus)status) {
            [self.delegate player:self statusDidChange:(BRPlayerStatus)status];
        }
        
        if (status == AVPlayerItemStatusReadyToPlay) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(player:readyToPlayWithDuration:)]) {
                [self.delegate player:self readyToPlayWithDuration:CMTimeGetSeconds(self.playerItem.duration)];
            }
            
            self.duration = (NSInteger)round(CMTimeGetSeconds(self.playerItem.duration));
            if (self.autoPlayWhenReadyToPlay) {
                [self.player play];
            }
        }
        else if (status == AVPlayerItemStatusFailed || status == AVPlayerItemStatusUnknown) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(player:failToPlayWithError:)]) {
                NSError *error = [NSError errorWithDomain:@"" code:1000 userInfo:nil];
                [self.delegate player:self failToPlayWithError:error];
            }
        }
    };
}

- (ObserveBlock)br_loadedTimeRangesBlock {
    return ^ (NSString *keyPath, id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context){
        CMTimeRange timeRange = [self.playerItem.loadedTimeRanges.firstObject CMTimeRangeValue];//本次缓冲时间范围
        Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
        Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        
        NSLog(@"当前缓冲时间:%f",totalBuffer);
        
        if (self.autoPlayWhenReadyToPlay) {
            [self.player play];
        }
    };
}

- (ObserveBlock)br_playbackBufferEmptyBlock {
    return ^ (NSString *keyPath, id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context){
        BOOL empty = [change[NSKeyValueChangeNewKey] intValue];
        if (!empty) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(player:playingOrPauseStatusChange:)]) {
                [self.delegate player:self playingOrPauseStatusChange:empty];
            }
        }
    };
}

- (ObserveBlock)br_playbackLikelyToKeepUpBlock {
    return ^ (NSString *keyPath, id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context){
        if (self.delegate && [self.delegate respondsToSelector:@selector(player:playingOrPauseStatusChange:)]) {
            [self.delegate player:self playingOrPauseStatusChange:YES];
        }
        
        NSLog(@"isPlaybackLikelyToKeepUp is: %ld", (long)self.playerItem.isPlaybackLikelyToKeepUp);
        if (self.autoPlayWhenReadyToPlay) {
            [self.player play];
        }
    };
}

@synthesize status;

@end

#pragma mark - BRPlayerContentView

@interface BRPlayerContentView : UIView

@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UILabel *startTimeLabel;
@property (nonatomic, strong) UILabel *endTimeLabel;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UIButton *fullScreenButton;

@property (nonatomic, strong) UIView *toobarView;

@end

@implementation BRPlayerContentView

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

@interface BRPlayerView () <BRPlayerCacheDataSource>

@property (nonatomic, strong) BRPlayer *player;

@end

@implementation BRPlayerView

- (instancetype)initWithURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        _player = [[BRPlayer alloc] initWithURL:URL];
        _player.dataSource = self;
        [_player attachView:self];
        [self.layer addSublayer:_player.playerLayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _player.playerLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    
}

- (void)onPlayButton {
    [self play];
}

- (id<AVAssetResourceLoaderDelegate>)player:(BRPlayer *)player {
    return BRPlayerCache.new;
}

#pragma mark - getter

@end


@implementation BRPlayerView (BRScroll)

- (void)scrollWithView:(UIScrollView *)scrollView hitRect:(CGRect)testRect withType:(BRScrollType)type {
    objc_setAssociatedObject(scrollView.delegate, &kBRPlayerViewScrollViewScrollInRect, [NSValue valueWithCGRect:testRect], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(scrollView.delegate, &kBRPlayerViewScrollViewScrollHitType, @(type), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, &kBRPlayerViewScrollViewDelegate, scrollView.delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    NSMapTable<NSString *, BRPlayerView *> *playViews = objc_getAssociatedObject(scrollView.delegate, &kBRPlayerViewSelf);
    if (!playViews) {
        playViews = [NSMapTable mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableWeakMemory];
        objc_setAssociatedObject(scrollView.delegate, &kBRPlayerViewSelf, playViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect frame = [self convertRect:self.frame toView:scrollView];
        [playViews setObject:self forKey:NSStringFromCGRect(frame)];
    });
    
    [self subclassWithView:scrollView];
}

- (void)subclassWithView:(UIScrollView *)scrollView {
    
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
    
    CGFloat scrollViewHeightOffsetCenterY = scrollView.contentOffset.y + (scrollView.bounds.size.height / 2);
    CGRect frame = CGRectZero;
    BRPlayerView *currentPlayingView = objc_getAssociatedObject(scrollView.delegate, &kBRPlayerViewCurrentPlaying);
    if ([scrollView isKindOfClass:[UITableView class]]) {
        frame = [currentPlayingView convertRect:currentPlayingView.frame toView:scrollView];
    }
    
    if (!CGRectContainsPoint(frame, CGPointMake(0, scrollViewHeightOffsetCenterY))) {
        [currentPlayingView pause];
    }
    
    NSValue *baseRectValue = objc_getAssociatedObject(scrollView.delegate, &kBRPlayerViewScrollViewScrollInRect);
    CGRect debugViewFrame = baseRectValue.CGRectValue;
    if (baseRectValue && !CGRectEqualToRect(debugViewFrame, CGRectZero)) {
        debugViewFrame.origin.y += scrollView.contentOffset.y;
    }
    else {
        debugViewFrame = CGRectMake(0, scrollViewHeightOffsetCenterY, scrollView.bounds.size.width, 1);
    }
    
    UIView *view = [scrollView viewWithTag:1000];
    if (!view) {
        
        view = [[UIView alloc] initWithFrame:CGRectZero];
        view.tag = 1000;
        view.layer.borderColor = [UIColor redColor].CGColor;
        view.layer.borderWidth = 1;
        [scrollView addSubview:view];
    }
    
    view.frame = debugViewFrame;
}

void calculatePlayingView(void *parameter) {
    UIScrollView *scrollView = (__bridge UIScrollView *)parameter;
    if (![scrollView respondsToSelector:@selector(delegate)]) {
        return;
    }
    
    NSMapTable<NSString *, BRPlayerView *> *playViews = objc_getAssociatedObject(scrollView.delegate, &kBRPlayerViewSelf);
    BRPlayerView *currentPlayingView = objc_getAssociatedObject(scrollView.delegate, &kBRPlayerViewCurrentPlaying);
    
    __block BRPlayerView *willInPlayerView = currentPlayingView;
    __block NSMutableArray<BRPlayerView *> *willInPlayerViews = @[].mutableCopy;
    CGFloat scrollViewHeightOffsetCenterY = scrollView.contentOffset.y + (scrollView.bounds.size.height / 2);
    __block CGFloat maxInOfBaseRectSpace = 0;
    
    NSValue *baseRectValue = objc_getAssociatedObject(scrollView.delegate, &kBRPlayerViewScrollViewScrollInRect);
    CGRect baseRect = baseRectValue.CGRectValue;
    if (baseRectValue && !CGRectEqualToRect(baseRect, CGRectZero)) {
        baseRect.origin.y += scrollView.contentOffset.y;
    }
    
    NSArray<BRPlayerView *> *allPlayViews = [[playViews objectEnumerator] allObjects];
    [allPlayViews enumerateObjectsUsingBlock:^(BRPlayerView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {

        CGRect frame = view.frame;
        if ([scrollView isKindOfClass:[UITableView class]]) {
            frame = [view convertRect:view.frame toView:scrollView];
        }
        
        //Pause except what's playing
        if (currentPlayingView != view && [view isPlaying]) {
            [view pause];
        }
        
        //Look for what will play, baseRect first
        if (!CGRectEqualToRect(baseRect, CGRectZero)) {
            
        }
        else {
            if (CGRectContainsPoint(frame, CGPointMake(0, scrollViewHeightOffsetCenterY))) {
                [willInPlayerViews removeAllObjects];
                [willInPlayerViews addObject:view];
            }
        }
        
    }];
    
    if (willInPlayerView) {
        objc_setAssociatedObject(scrollView.delegate, &kBRPlayerViewCurrentPlaying, willInPlayerView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        if (!currentPlayingView) {
            currentPlayingView = willInPlayerView;
        }
        
        if (currentPlayingView.delegate &&
            willInPlayerView.delegate &&
            [currentPlayingView.delegate respondsToSelector:@selector(scrollInType:currentInRect:willInRect:)] &&
            [willInPlayerView.delegate respondsToSelector:@selector(scrollInType:currentInRect:willInRect:)] &&
            currentPlayingView.delegate == willInPlayerView.delegate) {
            [currentPlayingView.delegate scrollInType:BRScrollTypeBaseLine currentInRect:currentPlayingView willInRect:willInPlayerView];
        }
    }
}

void debugViewInScrollView(void *parameter) {
    
}

@end


//
//  xlLPlayerView.m
//  Ship
//
//  Created by xlL on 2019/11/3.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "BRPlayerView.h"


static CGFloat kXlLPlayerToobarViewHeight = 30;
static const char kBRPlayerViewSelf;
static const char kBRPlayerViewCurrentPlaying;
static const char kBRPlayerViewScrollViewDelegate;
static const char kBRPlayerViewScrollViewScrollInRect;
static const char kBRPlayerViewScrollViewScrollHitType;

typedef struct _BRRange {
    long long location;
    long long length;
} BRRange;

NS_INLINE BRRange BRMakeRange(long long loc, long long len) {
    BRRange r;
    r.location = loc;
    r.length = len;
    return r;
}



#pragma mark - BRPlayerViewDownload

@interface BRPlayerViewDownload : NSObject

@end

@protocol BRPlayerViewDownloadDelegate <NSObject>

- (void)download:(BRPlayerViewDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response;
- (void)download:(BRPlayerViewDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response contentLength:(int64_t)length contentType:(NSString *)type contentRange:(BRRange)range;
- (void)download:(BRPlayerViewDownload *)download didReceiveData:(NSData *)data;
- (void)download:(BRPlayerViewDownload *)download didCompleteWithError:(NSError *)error;

@end

@interface BRPlayerViewDownload () <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSArray<NSString *> *allHeaderKeys;
@property (nonatomic, weak) id<BRPlayerViewDownloadDelegate> delegagte;
@property (nonatomic, assign) NSRange range;

@property (nonatomic, strong) NSFileHandle *writeHandle;
@property (nonatomic, strong) NSMutableData *data;

@end

@implementation BRPlayerViewDownload

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *tempPath =  [document stringByAppendingPathComponent:@"temp.mp4"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
            [[NSFileManager defaultManager] createFileAtPath:tempPath contents:nil attributes:nil];
            
        } else {
            [[NSFileManager defaultManager] createFileAtPath:tempPath contents:nil attributes:nil];
        }
        
        self.writeHandle = [NSFileHandle fileHandleForWritingAtPath:tempPath];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)URL
{
    self = [super init];
    if (self) {
        [self commonInitWithURL:URL];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)URL reqeustRange:(NSRange)range
{
    self = [super init];
    if (self) {
        
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *tempPath =  [document stringByAppendingPathComponent:@"temp.mp4"];
        self.writeHandle = [NSFileHandle fileHandleForWritingAtPath:tempPath];
        
        [self commonInitWithURL:URL];
        self.range = range;
    }
    return self;
}

- (void)commonInitWithURL:(NSURL *)URL {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];
    [request setValue:[NSString stringWithFormat:@"bytes=%ld-%ld", self.range.location, self.range.length] forHTTPHeaderField:@"Range"];
    NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *sharedSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    self.dataTask = [sharedSession dataTaskWithRequest:request];
}

- (void)startWithURL:(NSURL *)URL reqeustRange:(NSRange)range {
    self.range = range;
    [self commonInitWithURL:URL];
    [self.dataTask resume];
}

- (NSString *)headerFieldWithKey:(NSString *)key allHeaderFields:(NSDictionary<NSString *, NSString *> *)headerFields {
    NSString *value = headerFields[key];
    if (![value isEqualToString:@""] && value) {
        return value;
    }
    return nil;
}

#pragma mark - NSURLSession delegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    
    if (self.delegagte && [self.delegagte respondsToSelector:@selector(download:didReceiveResponse:)]) {
        [self.delegagte download:self didReceiveResponse:httpResponse];
    }
    else if (self.delegagte && [self.delegagte respondsToSelector:@selector(download:didReceiveResponse:contentLength:contentType:contentRange:)]) {
        
        NSDictionary<NSString *, NSString *> *allHeaderFields = httpResponse.allHeaderFields;
        NSString *contentRange = [self headerFieldWithKey:@"Content-Range" allHeaderFields:allHeaderFields];
        NSString *contentType = [self headerFieldWithKey:@"Content-Type" allHeaderFields:allHeaderFields];
        NSArray<NSString *> *contentRanges = [contentRange componentsSeparatedByString:@"/"];
        NSArray<NSString *> *numbersContentRanges = [[contentRanges.firstObject componentsSeparatedByString:@" "].lastObject componentsSeparatedByString:@"-"];
        
        int64_t contentLength = httpResponse.expectedContentLength;
        
        [self.delegagte download:self didReceiveResponse:httpResponse contentLength:contentLength contentType:contentType contentRange:BRMakeRange(numbersContentRanges.firstObject.longLongValue, numbersContentRanges.lastObject.longLongValue)];
    }
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    [self.writeHandle seekToEndOfFile];
    [self.writeHandle writeData:data];
    
    if (self.delegagte && [self.delegagte respondsToSelector:@selector(download:didReceiveData:)]) {
        [self.delegagte download:self didReceiveData:data];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    if (self.delegagte && [self.delegagte respondsToSelector:@selector(download:didCompleteWithError:)]) {
        [self.delegagte download:self didCompleteWithError:error];
    }
}

#pragma mark - getter

- (NSArray<NSString *> *)allHeaderKeys {
    return @[@"Content-Range"];
}

@end

#pragma mark - BRPlayerViewCache

@protocol BRPlayerViewCacheDelegate <NSObject>



@end

@interface BRPlayerViewCache : NSObject <AVAssetResourceLoaderDelegate, BRPlayerViewDownloadDelegate>

@property (nonatomic, strong) NSMutableArray<AVAssetResourceLoadingRequest *> *pendingRequests;
@property (nonatomic, weak) id<BRPlayerViewCacheDelegate> delegate;

@property (nonatomic, strong) BRPlayerViewDownload *download;

@end


@implementation BRPlayerViewCache

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.pendingRequests = @[].mutableCopy;
    }
    return self;
}

- (NSRange)fetchRequestRangeWithRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSUInteger location, length;
    // data range.
    if ([loadingRequest.dataRequest respondsToSelector:@selector(requestsAllDataToEndOfResource)] && loadingRequest.dataRequest.requestsAllDataToEndOfResource) {
        location = (NSUInteger)loadingRequest.dataRequest.requestedOffset;
        length = NSUIntegerMax;
    }
    else {
        location = (NSUInteger)loadingRequest.dataRequest.requestedOffset;
        length = loadingRequest.dataRequest.requestedLength;
    }
    if(loadingRequest.dataRequest.currentOffset > 0){
        location = (NSUInteger)loadingRequest.dataRequest.currentOffset;
    }
    return NSMakeRange(location, length);
}

#pragma mark -

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    
    [self.pendingRequests addObject:loadingRequest];
//    [self downloadMediaFragmentWithRequest:loadingRequest];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self.pendingRequests removeObject:loadingRequest];
}

- (void)downloadMediaFragmentWithRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSURL *URL = loadingRequest.request.URL;
    NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:URL resolvingAgainstBaseURL:NO];
    actualURLComponents.scheme = @"http";

    NSRange reqRange = [self fetchRequestRangeWithRequest:loadingRequest];
    [self.download startWithURL:[actualURLComponents URL] reqeustRange:reqRange];
}

#pragma mark - BRPlayerViewDownload Delegate

- (void)download:(BRPlayerViewDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response contentLength:(int64_t)length contentType:(NSString *)type contentRange:(BRRange)range {
    
}

- (void)download:(BRPlayerViewDownload *)download didReceiveData:(NSData *)data {
    [self.pendingRequests.firstObject.dataRequest respondWithData:data];
}

- (void)download:(BRPlayerViewDownload *)download didCompleteWithError:(NSError *)error {
    if (error) {
        return;
    }
    
    [self.pendingRequests enumerateObjectsUsingBlock:^(AVAssetResourceLoadingRequest * _Nonnull req, NSUInteger idx, BOOL * _Nonnull stop) {
        [req finishLoading];
    }];
}

#pragma mark - getter

- (BRPlayerViewDownload *)download {
    if (!_download) {
        _download = BRPlayerViewDownload.new;
        _download.delegagte = self;
    }
    return _download;
}

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

typedef void (^ObserveBlock) (NSString *keyPath, id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context);

@interface BRPlayerView ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) NSDictionary<NSString *, ObserveBlock> *observeBlocks;
@property (nonatomic, assign) Float64 duration;

@property (nonatomic, strong) BRPlayerContentView *contentView;

@property (nonatomic, strong) BRPlayerViewCache *cache;

@end

@implementation BRPlayerView



- (void)dealloc
{
    [self remoeObserver];
}

- (instancetype)initWithURL:(NSURL *)URL
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        
        self.URL = URL;
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
    self.loopPlayCount = -1;
    self.autoPlayWhenReadyToPlay = NO;
    
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
    else {
        self.loopPlayCount = -1;
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

- (void)reset {
    
    if (self.playerItem) {
        [self remoeObserver];
    }
    
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
    
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

- (void)setOverlapView:(UIView *)view {
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.contentView addSubview:view];
}

#pragma mark - setter

- (void)setEnablePlayWhileDownload:(BOOL)enablePlayWhileDownload {
    _enablePlayWhileDownload = enablePlayWhileDownload;
    if (enablePlayWhileDownload) {
        
        [self reset];
        
        self.cache = BRPlayerViewCache.new;
        self.cache.delegate = self;
        
        NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:self.URL resolvingAgainstBaseURL:NO];
        actualURLComponents.scheme = @"streaming";
        
        AVURLAsset *urlAsset = [AVURLAsset assetWithURL:[actualURLComponents URL]];
        [urlAsset.resourceLoader setDelegate:self.cache queue:dispatch_get_main_queue()];
        self.playerItem = [AVPlayerItem playerItemWithAsset:urlAsset];
        
        [self commonInit];
    }
}

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
                [self.player play];
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
        
        [self.player play];
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
        
        NSLog(@"isPlaybackLikelyToKeepUp is: %ld", (long)self.playerItem.isPlaybackLikelyToKeepUp);
        
        [self.player play];
    };
}

#pragma mark - getter

- (BRPlayerContentView *)contentView {
    if (!_contentView) {
        _contentView = [[BRPlayerContentView alloc] initWithFrame:CGRectZero];
    }
    return _contentView;
}

- (BOOL)isPlaying {
    return self.player.rate == 0;
}

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


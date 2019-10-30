//
//  xlLCommand.m
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "xlLCommand.h"

@interface xlLCommand ()

@property (nonatomic, strong) id<XLLReceiverProtocol> receiver;
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) AVMutableComposition *mutableComposition;
@property (nonatomic, strong) id<XLLCommandProtocol> command;
@property (nonatomic, copy) ProcessComplete handler;

@end

@implementation xlLCommand

- (instancetype)initWithReceiver:(id<XLLReceiverProtocol>)receiver
{
    self = [super init];
    if (self) {
        _receiver = receiver;
    }
    return self;
}

- (instancetype)initWithVideoURL:(NSURL *)URL
{
    self = [super init];
    if (self) {
        self.asset = [AVAsset assetWithURL:URL];
        [self recompositionVideoWithAsset:self.asset];
    }
    return self;
}

- (instancetype)initWithCommand:(id<XLLCommandProtocol>)command {
    self = [super init];
    if (self) {
        self.command = command;
    }
    return self;
}

- (instancetype)initWithCommand:(id<XLLCommandProtocol>)command videoURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        self.command = command;
        
        self.asset = [AVAsset assetWithURL:URL];
        [self recompositionVideoWithAsset:self.asset];
    }
    return self;
}

- (void)processWithCompleteHandle:(ProcessComplete)handler {
    [self execute:self.mutableComposition];
    
    self.handler = handler;
}

- (void)execute:(AVMutableComposition *)asset {
    if (self.command) {
        [self.command execute:asset];
    }
}

- (void)recompositionVideoWithAsset:(AVAsset *)asset {
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    
    if ([asset tracksWithMediaType:AVMediaTypeVideo].count > 0) {
        assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        if (assetVideoTrack) {
            NSError *error = nil;
            AVMutableCompositionTrack *compositionVideoTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetVideoTrack atTime:kCMTimeZero error:&error];
            
            if (error) {
                NSLog(@"");
            }
        }
    }
    
    if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0) {
        assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        if (assetAudioTrack) {
            NSError *error = nil;
            AVMutableCompositionTrack *compositionAudioTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetAudioTrack atTime:kCMTimeZero error:&error];
            
            if (error) {
                NSLog(@"");
            }
        }
    }
}

#pragma mark - getter

- (AVMutableComposition *)mutableComposition {
    if (!_mutableComposition) {
        _mutableComposition = [AVMutableComposition composition];
    }
    return _mutableComposition;
}

@end

//
//  BRCommand.m
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "BRCommand.h"

@interface BRCommand ()

@property (nonatomic, strong) id<XLLReceiverProtocol> receiver;
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAsset *asset;

@property (nonatomic, strong) id<BRCommandProtocol> command;
@property (nonatomic, copy) ProcessComplete handler;

@property (nonatomic, strong) AVMutableComposition *mutableComposition;
@property (nonatomic, strong) AVMutableVideoComposition *videoComposition;
@property (nonatomic, strong) AVMutableAudioMix *audioMix;

@end

@implementation BRCommand

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

- (instancetype)initWithCommand:(id<BRCommandProtocol>)command {
    self = [super init];
    if (self) {
        self.command = command;
        self.mutableComposition = command.mutableComposition;
    }
    return self;
}

- (instancetype)initWithCommand:(id<BRCommandProtocol>)command videoURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        self.command = command;
        
        self.asset = [AVAsset assetWithURL:URL];
        [self recompositionVideoWithAsset:self.asset];
    }
    return self;
}

- (void)processWithCompleteHandle:(ProcessComplete)handler {
    self.handler = handler;
    
    [self execute:self.mutableComposition videoComposition:self.videoComposition audioMix:self.audioMix];
}

- (void)execute:(AVMutableComposition *)asset videoComposition:(AVMutableVideoComposition * _Nullable)videoComposition audioMix:(AVMutableAudioMix * _Nullable)audioMix {
    if (self.command) {
        [self.command execute:asset videoComposition:self.videoComposition audioMix:self.audioMix];
    }
    
//    if (self.handler) {
//        self.handler(self.mutableComposition);
//    }
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

- (void)exportMediaToURL:(NSURL *)URL completeHandle:(dispatch_block_t)complete {
    static NSDateFormatter *kDateFormatter;
    if (!kDateFormatter) {
        kDateFormatter = [[NSDateFormatter alloc] init];
        kDateFormatter.dateStyle = NSDateFormatterMediumStyle;
        kDateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:self.mutableComposition presetName:AVAssetExportPresetHighestQuality];
    // Set the desired output URL for the file created by the export process.
    exporter.outputURL = URL;
    // Set the output file type to be a QuickTime movie.
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = self.videoComposition;
    // Asynchronously export the composition to a video file and save this file to the camera roll once export completes.
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        
    }];
}

#pragma mark - getter

- (AVMutableComposition *)mutableComposition {
    if (!_mutableComposition) {
        _mutableComposition = [AVMutableComposition composition];
    }
    return _mutableComposition;
}

@end

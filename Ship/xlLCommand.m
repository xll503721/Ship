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
    }
    return self;
}

- (void)execute:(AVAsset *)asset {
    if (self.command) {
        [self.command execute:asset];
    }
}

- (AVMutableComposition *)recompositionVideoWithAsset:(AVAsset *)asset {
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    
    if ([asset tracksWithMediaType:AVMediaTypeVideo].count > 0) {
        assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        if (assetVideoTrack) {
            NSError *error = nil;
            AVMutableCompositionTrack *compositionVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
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
            AVMutableCompositionTrack *compositionAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetAudioTrack atTime:kCMTimeZero error:&error];
            
            if (error) {
                NSLog(@"");
            }
        }
    }
    
    return mutableComposition;
}

@end

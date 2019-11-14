//
//  xlLClipCommand.m
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "BRClipCommand.h"

@interface BRClipCommand ()

@property (nonatomic, assign) NSTimeInterval fromSecond;
@property (nonatomic, assign) NSTimeInterval toSecond;

@end

@implementation BRClipCommand

- (instancetype)initWithReceiver:(id<XLLReceiverProtocol>)receiver fromSecond:(NSTimeInterval)fromSecond toSecond:(NSTimeInterval)toSecond
{
    self = [super initWithReceiver:receiver];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithCommand:(id<BRCommandProtocol>)command fromSecond:(NSTimeInterval)fromSecond toSecond:(NSTimeInterval)toSecond {
    self = [super initWithCommand:command];
    if (self) {
        
    }
    return self;
}

- (void)execute:(AVMutableComposition *)asset videoComposition:(AVMutableVideoComposition * _Nullable)videoComposition audioMix:(AVMutableAudioMix * _Nullable)audioMix {
    [super execute:asset videoComposition:videoComposition audioMix:audioMix];
    
    if ([asset tracksWithMediaType:AVMediaTypeVideo].count > 0 && [asset tracksWithMediaType:AVMediaTypeAudio].count > 0) {
        AVAssetTrack *assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        AVAssetTrack *assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        
        AVMutableCompositionTrack *mutableVideoCompositionTrack = [asset mutableTrackCompatibleWithTrack:assetVideoTrack];
        [mutableVideoCompositionTrack removeTimeRange:CMTimeRangeMake(CMTimeMake(self.fromSecond, 1), CMTimeMake(self.toSecond, 1))];
        
        AVMutableCompositionTrack *mutableAudioCompositionTrack = [asset mutableTrackCompatibleWithTrack:assetAudioTrack];
        [mutableAudioCompositionTrack removeTimeRange:CMTimeRangeMake(CMTimeMake(self.fromSecond, 1), CMTimeMake(self.toSecond, 1))];
    }
}

@end

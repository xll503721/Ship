//
//  xlLTransitionCommand.m
//  Ship
//
//  Created by xlL on 2019/10/30.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "xlLTransitionCommand.h"

@interface xlLTransitionCommand ()

@end

@implementation xlLTransitionCommand

- (instancetype)initWithCommand:(id<XLLCommandProtocol>)command {
    self = [super initWithCommand:command];
    if (self) {
        
    }
    return self;
}

- (void)execute:(AVMutableComposition *)asset videoComposition:(AVMutableVideoComposition * _Nullable)videoComposition audioMix:(AVMutableAudioMix * _Nullable)audioMix {
    [super execute:asset videoComposition:videoComposition audioMix:audioMix];
    
    AVAssetTrack *videoAssetTrack = [asset tracksWithMediaType:AVMediaTypeVideo].lastObject;
    
    AVMutableVideoCompositionInstruction *videoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    videoCompositionInstruction.timeRange = CMTimeRangeMake(CMTimeMake(2, 1), CMTimeMake(3, 1));
    AVMutableVideoCompositionLayerInstruction *videoCompositionLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoAssetTrack];
    [videoCompositionLayerInstruction setOpacityRampFromStartOpacity:0 toEndOpacity:1.0 timeRange:CMTimeRangeMake(CMTimeMake(2, 1), CMTimeMake(3, 1))];
    
    videoCompositionInstruction.layerInstructions = @[videoCompositionLayerInstruction];
    videoComposition.instructions = @[videoCompositionInstruction];
}

@end

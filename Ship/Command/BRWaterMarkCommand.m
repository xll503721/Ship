//
//  xlLWaterMarkCommand.m
//  Ship
//
//  Created by xlL on 2019/10/30.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "BRWaterMarkCommand.h"

@interface BRWaterMarkCommand ()

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *string;
@property (nonatomic, strong) CALayer *layer;

@end

@implementation BRWaterMarkCommand

- (instancetype)initWithCommand:(id<BRCommandProtocol>)command image:(UIImage *)image {
    self = [super initWithCommand:command];
    if (self) {
        self.image = image;
    }
    return self;
}

- (instancetype)initWithCommand:(id<BRCommandProtocol>)command string:(NSString *)string {
    self = [super initWithCommand:command];
    if (self) {
        self.string = string;
    }
    return self;
}

- (instancetype)initWithCommand:(id<BRCommandProtocol>)command waterMarkLayer:(CALayer *)layer {
    self = [super initWithCommand:command];
    if (self) {
        self.layer = layer;
    }
    return self;
}

- (void)execute:(AVMutableComposition *)asset videoComposition:(AVMutableVideoComposition * _Nullable)videoComposition audioMix:(AVMutableAudioMix * _Nullable)audioMix {
    [super execute:asset videoComposition:videoComposition audioMix:audioMix];
 
    if (!self.layer) {
        self.layer = [self waterMarkLayer];
    }
    
    videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:self.layer inLayer:self.layer];
}

- (CALayer *)waterMarkLayer {
    CALayer *parentLayer = [CALayer layer];
    return parentLayer;
}

@end

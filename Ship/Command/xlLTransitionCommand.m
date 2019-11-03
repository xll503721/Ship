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

- (void)execute:(AVMutableComposition *)asset {
    [super execute:asset];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    
    AVMutableVideoCompositionInstruction *videoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    AVMutableVideoCompositionLayerInstruction *videoCompositionLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstruction];
    
    
    
}

@end

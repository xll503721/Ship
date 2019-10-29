//
//  xlLClipCommand.m
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "xlLClipCommand.h"

@interface xlLClipCommand ()

@end

@implementation xlLClipCommand

- (instancetype)initWithReceiver:(id<XLLReceiverProtocol>)receiver videoURL:(NSURL *)URL fromSecond:(NSTimeInterval)fromSecond toSecond:(NSTimeInterval)toSecond
{
    self = [super initWithReceiver:receiver];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithVideoURL:(NSURL *)URL fromSecond:(NSTimeInterval)fromSecond toSecond:(NSTimeInterval)toSecond {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)execute:(AVAsset *)asset {
    
}

@end
